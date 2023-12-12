const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

fn printGalaxy(points: std.ArrayList(util.Point64), maxp: util.Point64) void {
    var x: u8 = 0;
    var y: u8 = 0;
    while (x <= maxp.x and y <= maxp.y) {
        var contains: bool = false;
        for (points.items) |p| {
            if (p.x == x and p.y == y) {
                contains = true;
            }
        }
        if (contains) {
            std.debug.print("#", .{});
        } else {
            std.debug.print(".", .{});
        }

        x += 1;
        if (x > maxp.x) {
            x = 0;
            y += 1;
            std.debug.print("\n", .{});
        }
    }
}

fn plotLineLow(x0: i128, y0: i128, x1: i128, y1: i128) u128 {
    const dx = x1 - x0;
    var dy = y1 - y0;
    var yi: i64 = 1;
    if (dy < 0) {
        yi = -1;
        dy = -dy;
    }
    var D = (2 * dy) - dx;
    var y = y0;

    var x = x0;
    var ct: u64 = 0;
    while (x < x1) {
        if (D > 0) {
            y = y + yi;
            ct += @abs(yi);
            D = D + (2 * (dy - dx));
        } else {
            D = D + 2 * dy;
        }
        x += 1;
        ct += 1;
    }
    return ct;
}

fn plotLineHigh(x0: i128, y0: i128, x1: i128, y1: i128) u128 {
    var dx = x1 - x0;
    const dy = y1 - y0;
    var xi: i128 = 1;
    if (dx < 0) {
        xi = -1;
        dx = -dx;
    }
    var D = (2 * dx) - dy;
    var x = x0;

    var y = y0;
    var ct: u128 = 0;
    while (y < y1) {
        if (D > 0) {
            x = x + xi;
            ct += @abs(xi);
            D = D + (2 * (dx - dy));
        } else {
            D = D + 2 * dx;
        }
        y += 1;
        ct += 1;
    }
    return ct;
}

fn plotLine(x0: i128, y0: i128, x1: i128, y1: i128) u128 {
    if (@abs(y1 - y0) < @abs(x1 - x0)) {
        if (x0 > x1) {
            return plotLineLow(x1, y1, x0, y0);
        } else { // draw line between each pair of galaxy and calculate sum of all distances
            return plotLineLow(x0, y0, x1, y1);
        }
    } else {
        if (y0 > y1) {
            return plotLineHigh(x1, y1, x0, y0);
        } else {
            return plotLineHigh(x0, y0, x1, y1);
        }
    }
}

pub fn day11(filename: []const u8, part2: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var points = std.ArrayList(util.Point64).init(gpa.*);

    var lineIndex: u8 = 0;
    var buffer: [1024]u8 = undefined;
    var lineLength: u8 = 0;
    var rowAdd: u64 = 0;
    var xPresent = std.AutoHashMap(u64, bool).init(gpa.*);

    var expansion: u64 = 1;
    if (part2) {
        expansion = 1000000 - 1;
    }

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var cIndex: u8 = 0;
        var expandRow: bool = true;
        for (line) |c| {
            if (lineIndex == 0) {
                lineLength += 1;
            }
            if (c == '#') {
                try points.append(util.Point64{ .x = cIndex, .y = lineIndex + rowAdd });
                expandRow = false;
                try xPresent.put(cIndex, true);
            }
            cIndex += 1;
        }
        if (expandRow) {
            rowAdd += expansion;
        }
        lineIndex += 1;
    }

    const olMax: util.Point64 = util.Point64{ .x = lineLength - 1, .y = lineIndex + rowAdd - 1 };

    var spreadPoints = std.ArrayList(util.Point64).init(gpa.*);
    var mx: u8 = 0;
    var xAdd: u64 = 0;
    while (mx <= olMax.x) {
        if (!xPresent.contains(mx)) {
            xAdd += expansion;
        } else {
            for (points.items) |p| {
                if (p.x == mx) {
                    try spreadPoints.append(util.Point64{ .x = p.x + xAdd, .y = p.y });
                }
            }
        }
        mx += 1;
    }
    const maxp = util.Point64{ .x = lineLength + xAdd - 1, .y = lineIndex + rowAdd - 1 };
    if (!part2) {
        printGalaxy(spreadPoints, maxp);
    }

    var totalDistances: u128 = 0;
    var gi: u64 = 0;
    while (gi < spreadPoints.items.len - 1) {
        const p1 = spreadPoints.items[gi];
        var gj: u64 = gi + 1;
        while (gj < spreadPoints.items.len) {
            const p2 = spreadPoints.items[gj];
            const dist = plotLine(p1.x, p1.y, p2.x, p2.y);
            totalDistances += dist;
            gj += 1;
        }
        gi += 1;
    }

    std.debug.print("Day 11 Part 1: {d}\n", .{totalDistances});
}
