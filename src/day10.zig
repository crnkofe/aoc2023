const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

// returns tile at location or . if no tile at location
fn getTile(p: util.Point, map: std.ArrayList([]const u8)) u8 {
    if (p.y >= map.items.len) {
        return '.';
    }
    const line = map.items[p.y];
    if (p.x >= line.len) {
        return '.';
    }
    return line[p.x];
}

// | is a vertical pipe connecting north and south.
// - is a horizontal pipe connecting east and west.
// L is a 90-degree bend connecting north and east.
// J is a 90-degree bend connecting north and west.
// 7 is a 90-degree bend connecting south and west.
// F is a 90-degree bend connecting south and east.
// . is ground; there is no pipe in this tile.
// S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.
pub fn findNeighbours(p: util.Point, map: std.ArrayList([]const u8)) anyerror!std.ArrayList(util.Point) {
    var neighbours = std.ArrayList(util.Point).init(gpa.*);

    const t = getTile(p, map);
    // north
    if (p.y > 0 and t == 'S' or t == '|' or t == 'J' or t == 'L') {
        const tN = getTile(util.Point{ .x = p.x, .y = p.y - 1 }, map);
        if (tN == '7' or tN == '|' or tN == 'F') {
            try neighbours.append(util.Point{ .x = p.x, .y = p.y - 1 });
        }
    }

    // west
    if (p.x > 0 and t == 'S' or t == '-' or t == 'J' or t == '7') {
        const tW = getTile(util.Point{ .x = p.x - 1, .y = p.y }, map);
        if (tW == '-' or tW == 'L' or tW == 'F') {
            try neighbours.append(util.Point{ .x = p.x - 1, .y = p.y });
        }
    }

    // east
    if (t == 'S' or t == '-' or t == 'F' or t == 'L') {
        const tE = getTile(util.Point{ .x = p.x + 1, .y = p.y }, map);
        if (tE == '-' or tE == '7' or tE == 'J') {
            try neighbours.append(util.Point{ .x = p.x + 1, .y = p.y });
        }
    }
    // south
    if (t == 'S' or t == '|' or t == 'F' or t == '7') {
        const tS = getTile(util.Point{ .x = p.x, .y = p.y + 1 }, map);
        if (tS == '|' or tS == 'L' or tS == 'J') {
            try neighbours.append(util.Point{ .x = p.x, .y = p.y + 1 });
        }
    }

    return neighbours;
}

pub fn day10(filename: []const u8, _: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var s: util.Point = util.Point{ .x = 0, .y = 0 };
    var map = std.ArrayList([]const u8).init(gpa.*);

    var lineIndex: u8 = 0;
    var buffer: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var cIndex: u8 = 0;
        for (line) |c| {
            if (c == 'S') {
                s = util.Point{ .x = cIndex, .y = lineIndex };
            }
            cIndex += 1;
        }
        try map.append(try util.copys(line));
        lineIndex += 1;
    }

    var loop = std.AutoHashMap(util.Point, bool).init(gpa.*);

    var steps: u64 = 0;
    var lastNeigbours: std.ArrayList(util.Point) = std.ArrayList(util.Point).init(gpa.*);
    try lastNeigbours.append(s);
    try lastNeigbours.append(s);
    try loop.put(s, true);
    var neighbours: std.ArrayList(util.Point) = try findNeighbours(s, map);
    // What is the S-tile? This part is relevant for part 2.
    var sTile: u8 = 0;
    if (neighbours.items[0].x == neighbours.items[1].x) {
        sTile = '|';
    } else if (neighbours.items[0].y == neighbours.items[1].y) {
        sTile = '-';
    } else {
        const mxx = @max(neighbours.items[0].x, neighbours.items[1].x);
        const mnx = @min(neighbours.items[0].x, neighbours.items[1].x);
        const mxy = @max(neighbours.items[0].y, neighbours.items[1].y);
        const mny = @max(neighbours.items[0].y, neighbours.items[1].y);
        if ((mnx < s.x) and (mny < s.y)) {
            sTile = '7';
        } else if ((mnx < s.x) and (mxy > s.y)) {
            sTile = 'J';
        } else if ((mxx > s.x) and (mny > s.y)) {
            sTile = 'F';
        } else {
            sTile = 'L';
        }
    }

    while (!neighbours.items[0].eq(neighbours.items[1])) {
        try loop.put(neighbours.items[0], true);
        try loop.put(neighbours.items[1], true);
        var nextNeighbours: std.ArrayList(util.Point) = std.ArrayList(util.Point).init(gpa.*);
        for (neighbours.items) |n| {
            const nn: std.ArrayList(util.Point) = try findNeighbours(n, map);
            if ((!nn.items[0].eq(s)) and
                (!nn.items[0].eq(lastNeigbours.items[0])) and
                (!nn.items[0].eq(lastNeigbours.items[1])) and
                (!nn.items[0].eq(neighbours.items[0])) and
                (!nn.items[0].eq(neighbours.items[1])))
            {
                try nextNeighbours.append(nn.items[0]);
            } else {
                try nextNeighbours.append(nn.items[1]);
            }
        }
        lastNeigbours = neighbours;
        neighbours = nextNeighbours;
        steps += 1;
        if (steps > 100000) {
            return;
        }
    }
    try loop.put(neighbours.items[0], true);

    const mapLen = map.items[0].len;

    // simple Point-in-Polygon algorithm implementation
    var countInLoop: u64 = 0;
    var li: u8 = 0;
    while (li < map.items.len) {
        var countIntersections: u64 = 0;
        var ri: u8 = 0;
        var up: u8 = 0;
        var down: u8 = 0;
        while (ri < mapLen) {
            if (loop.contains(util.Point{ .x = ri, .y = li })) {
                var t: u8 = getTile(util.Point{ .x = ri, .y = li }, map);
                if (t == 'S') {
                    t = sTile;
                }

                // L is a 90-degree bend connecting north and east.
                // J is a 90-degree bend connecting north and west.
                // 7 is a 90-degree bend connecting south and west.
                // F is a 90-degree bend connecting south and east.
                if (t == '|') {
                    up += 1;
                    down += 1;
                } else if (t == 'L' or t == 'J') {
                    up += 1;
                } else if (t == '7' or t == 'F') {
                    down += 1;
                }
            } else {
                if ((up >= 1 and down >= 1)) {
                    countIntersections += @min(up, down);
                }
                up = 0;
                down = 0;
                if ((countIntersections % 2) == 1) {
                    countInLoop += 1;
                }
            }
            ri += 1;
        }
        li += 1;
    }

    std.debug.print("Day 10 Part 1: {d}\n", .{steps + 1});
    std.debug.print("Day 10 Part 2: {d}\n", .{countInLoop});
}
