const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

pub fn day5(filename: []const u8, _: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buffer: [1024]u8 = undefined;
    var lineno: u8 = 0;
    var seeds = std.ArrayList(u128).init(gpa.*);
    var mappedSeeds = std.ArrayList(u128).init(gpa.*);

    // pairs and mappedPairs contain seed, seedCountInRange pairs in one list
    var pairs = std.ArrayList(u128).init(gpa.*);
    var mappedPairs = std.ArrayList(u128).init(gpa.*);

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (lineno == 0) {
            // pair index for part 2
            // if %2 == 0 then this is starting seed
            // else it is seed range count
            var cs: u128 = 0;
            for (line) |c| {
                if (util.isnum(c)) {
                    cs = cs * 10 + util.getnum(c);
                } else if (cs > 0) {
                    try seeds.append(cs);
                    try pairs.append(cs);
                    cs = 0;
                }
            }
            if (cs > 0) {
                try seeds.append(cs);
                try pairs.append(cs);
            }
        }

        if (lineno > 1) {
            if (line.len <= 1) {
                for (seeds.items) |seed| {
                    try mappedSeeds.append(seed);
                }
                try seeds.insertSlice(0, mappedSeeds.items);
                mappedSeeds.deinit();
                mappedSeeds = std.ArrayList(u128).init(gpa.*);

                while (pairs.items.len > 0) {
                    const item = pairs.orderedRemove(0);
                    try mappedPairs.append(item);
                }
                try pairs.insertSlice(0, mappedPairs.items);
                mappedPairs.deinit();
                mappedPairs = std.ArrayList(u128).init(gpa.*);
            } else if(line[line.len-1] == ':') {
                // std.debug.print("name: {s}\n", .{line});
            } else {
                var mapping = std.mem.split(u8, line, " ");
                const dest = try std.fmt.parseInt(u128, mapping.next() orelse "0", 10);
                const source = try std.fmt.parseInt(u128, mapping.next() orelse "0", 10);
                const count = try std.fmt.parseInt(u128, mapping.next() orelse "0", 10);
                // std.debug.print("source -> dest : ct: {d} {d} {d}\n", .{source, dest, count});
                var si: u8 = 0;
                while (si < seeds.items.len) {
                    const seed = seeds.items[si];
                    if ((seed >= source) and ((seed - source) < count)) {
                        try mappedSeeds.append(dest + (seed - source));
                        // remove seed from seeds
                        _ = seeds.swapRemove(si);
                    } else {
                        si += 1;
                    }
                }
                // pair index
                var guard: u8 = 0;
                var pi: u8 = 0;
                while (pi < pairs.items.len) {
                    const st = pairs.items[pi];
                    const sc = pairs.items[pi+1];
                    const se = st + sc;
                    // options:
                    // out of mapping range (nothing happens)
                    if ((se <= source) or (st > (source + count))) {
                        // std.debug.print("range out of mapping: {d}..{d} <> {d} {d}", st, se, source, source + count);
                        pi += 2;
                    } else if ((st >= source) and ((st + sc) < (source + count))) {
                        // remove range from pairs
                        _ = pairs.swapRemove(pi+1);
                        _ = pairs.swapRemove(pi);

                        // entirely mapped (entire range is replaced)
                        try mappedPairs.append(dest + (st - source));
                        // range stays the same
                        try mappedPairs.append(sc);

                    } else if (st < source) {
                        // remove range from pairs
                        _ = pairs.swapRemove(pi+1);
                        _ = pairs.swapRemove(pi);

                        // we get two ranges - one before source that becomes unmapped
                        try pairs.append(st);
                        // range goes upto start
                        try pairs.append(source - st);
                        pi += 2;

                        const containedSize = @min(count, sc - (source - st));
                        // and one that is entirely contained (mapped)
                        try mappedPairs.append(dest);
                        // range stays the same
                        try mappedPairs.append(containedSize);

                        // if seed range encompasses entire rule
                        // then get another unmapped range
                        if (se > (source + count)) {
                            try pairs.append(source + count);
                            try pairs.append(se - (source + count));
                            pi += 2;
                        }
                    } else {
                        // remove range from pairs
                        _ = pairs.swapRemove(pi+1);
                        _ = pairs.swapRemove(pi);

                        // we get two ranges - one that is entirely contained (mapped)
                        try mappedPairs.append(dest + (st - source));
                        // range goes upto end
                        try mappedPairs.append(count - (st - source));

                        const partSize: u128 = sc - (source + count - st);
                        if (partSize > 0) {
                            // and one that exists after source+count
                            try pairs.append(source + count);
                            // range goes upto start
                            try pairs.append(partSize);
                        }
                        pi += 2;
                    }
                    guard += 1;
                    if (guard > 1000) {
                        return;
                    }
                }
            }
        }

        lineno += 1;
    }
    var minLocation = seeds.items[0];
    for (seeds.items) |seed| {
        minLocation = @min(minLocation, seed);
    }

    var minPart2Location: u128 = pairs.items[0];
    var pi: u8 = 0;
    while (pi < pairs.items.len) {
        minPart2Location = @min(minPart2Location, pairs.items[pi]);
        pi += 2;
    }
    std.debug.print("Day 5 Part 1: {d}\n", .{minLocation});
    std.debug.print("Day 5 Part 2: {d}\n", .{minPart2Location});
}
