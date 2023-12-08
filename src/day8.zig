const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

fn allEndZ(lst: std.ArrayList([]const u8)) bool {
    for (lst.items) |item| {
        if (item[2] != 'Z') {
            return false;
        }
    }
    return true;
}

pub fn gcd(a: anytype, b: anytype) @TypeOf(a, b) {
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .Int => |int| std.debug.assert(int.signedness == .unsigned),
        .ComptimeInt => {
            std.debug.assert(a >= 0);
            std.debug.assert(b >= 0);
        },
        else => unreachable,
    };
    std.debug.assert(a != 0 or b != 0);

    if (a == 0) return b;
    if (b == 0) return a;

    var x: @TypeOf(a, b) = a;
    var y: @TypeOf(a, b) = b;
    var m: @TypeOf(a, b) = a;

    while (y != 0) {
        m = x % y;
        x = y;
        y = m;
    }
    return x;
}

pub fn day8(filename: []const u8, part2: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    // indices will be sorted by rank desc (initially from 0..count file lines)
    var buffer: [1024]u8 = undefined;
    var lineno: u64 = 0;
    var instructions = std.ArrayList(u8).init(gpa.*);

    var first = std.ArrayList(u64).init(gpa.*);
    var second = std.ArrayList(u64).init(gpa.*);
    // var nodes = std.StringHashMap(u8).init(gpa.*);
    // defer map.deinit();
    var map = std.BufMap.init(gpa.*);
    // all elements starting with
    var part2Nodes = std.ArrayList([]const u8).init(gpa.*);
    var part2NodesOriginal = std.ArrayList([]const u8).init(gpa.*);
    //var part2Repeat = std.AutoHashMap(u64, u64).init(gpa.*);
    defer map.deinit();
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        // var mapping = std.mem.split(u8, line, " ");
        if (lineno == 0) {
            for (line) |c| {
                try instructions.append(c);
            }
        }
        if (lineno > 1) {
            // var node: std.ArrayList(u8).init(gpa.*);

            var toArr = std.ArrayList(u8).init(gpa.*);
            // split line of form AAA = (BBB, BBB)
            var lr = std.mem.split(u8, line, " = ");
            const from = lr.next() orelse "";
            if (from[2] == 'A') {
                var copyFrom = std.ArrayList(u8).init(gpa.*);
                var copyFrom1 = std.ArrayList(u8).init(gpa.*);
                for (from) |c| {
                    try copyFrom.append(c);
                    try copyFrom1.append(c);
                }
                try part2Nodes.append(copyFrom.items);
                try part2NodesOriginal.append(copyFrom1.items);
                try first.append(0);
                try second.append(0);
            }
            const to = lr.next() orelse "";
            for (to) |c| {
                try toArr.append(c);
            }
            try map.put(from, to);
        }
        lineno += 1;
    }

    var steps: u64 = 0;
    var node: []const u8 = "AAA";
    var ii: u64 = 0;
    if (!part2) {
        while (!util.compareConst(node, "ZZZ")) {
            var path: []const u8 = map.get(node) orelse "";
            const di = (ii % instructions.items.len);
            if (instructions.items[di] == 'L') {
                node = path[1..4];
            } else {
                node = path[6..9];
            }
            steps += 1;
            ii += 1;
        }
    }

    ii = 0;
    if (part2) {
        steps = 0;
        // while (!allEndZ(part2Nodes)) {
        //     const di = (ii % instructions.items.len);
        //     var zi: u8 = 0;
        //     while (zi < part2Nodes.items.len) {
        //         const currentNode = part2Nodes.items[zi];
        //         const path = map.get(currentNode) orelse "";
        //         if (instructions.items[di] == 'L') {
        //             part2Nodes.items[zi] = path[1..4];
        //         } else {
        //             part2Nodes.items[zi] = path[6..9];
        //         }
        //
        //         // if (util.compareConst(part2Nodes.items[zi], "QCZ")) {
        //         if (util.compareConst(part2Nodes.items[zi], "JJZ")) {
        //             if (first.items[zi] == 0) {
        //                 first.items[zi] = steps;
        //             } else if (second.items[zi] == 0) {
        //                 second.items[zi] = steps;
        //             }
        //         }
        //         zi += 1;
        //     }
        //     steps += 1;
        //     ii += 1;
        // }

        // the commented algorithm can be used as follows:
        // find all nodes that end with Z and run the algo so it finds how often that node repeats
        // apparently each node ending with Z repeats on only one and a different node ending with A
        // once all the numbers are known take them and compute least common multiple which is the solution
        const repeats: [6]u64 = .{18157, 14363, 16531, 12737, 19783, 19241};
        var x1: u64 = repeats[0];
        var i: u8 = 1;
        while (i < repeats.len) {
            x1 = (x1 * repeats[i]) / gcd(x1, repeats[i]);
            i += 1;
        }
        std.debug.print("Day 8 Part 2: {d}\n", .{x1});
    }


    std.debug.print("Day 8: {d}\n", .{steps});
}