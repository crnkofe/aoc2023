const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

const OffsetIdx = struct {
    offset: u64,
    numIdx: u8,
};

const CogProblem = struct {
    sentence: []u8,
    nums: std.ArrayList(u64),
    dpCache: std.AutoHashMap(OffsetIdx, u64),

    pub fn solve(self: *CogProblem, stStart: u64, ni: u8) anyerror!u64 {
        const cacheIdx = OffsetIdx{ .offset = stStart, .numIdx = ni };
        if (self.dpCache.contains(cacheIdx)) {
            return self.dpCache.get(cacheIdx) orelse 0;
        }
        if (stStart >= self.sentence.len) {
            if (ni >= self.nums.items.len) {
                return 1;
            }
            return 0;
        }
        if (ni >= self.nums.items.len) {
            // verify that this is a solution
            for (self.sentence[stStart..self.sentence.len]) |c| {
                if (c == '#') {
                    return 0;
                }
            }
            return 1;
        }
        const cogs = self.nums.items[ni];
        if (self.sentence.len < cogs) {
            return 0;
        }
        const sLen: u64 = @as(u64, self.sentence.len);
        // find all valid placements
        var combos: u64 = 0;
        var si: u64 = stStart;

        var firstHash: u64 = sLen + 1;
        while (si <= sLen - cogs) {
            // we must cover all #
            if (si > firstHash) {
                break;
            }
            if ((self.sentence[si] == '#') and (firstHash == (sLen + 1))) {
                firstHash = si;
            }
            var cc: u8 = 0;

            if ((si < (sLen - cogs)) and (self.sentence[si + cogs] == '#')) {
                si += 1;
                continue;
            }
            while (cc < cogs) {
                if (self.sentence[si + cc] != '#' and self.sentence[si + cc] != '?') {
                    break;
                }
                cc += 1;
            }
            // valid placement
            if (cc == cogs) {
                const solutions = try self.solve(si + cogs + 1, ni + 1);
                combos += solutions;
            } else {}
            si += 1;
        }
        try self.dpCache.put(cacheIdx, combos);
        return combos;
    }
};

pub fn day12(filename: []const u8, part2: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buffer: [1024]u8 = undefined;

    var initRepeat: u8 = 1;
    if (part2) {
        initRepeat = 5;
    }

    var total: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var simplerSentence = std.ArrayList(u8).init(gpa.*);
        var cogNums: std.ArrayList(u8) = std.ArrayList(u8).init(gpa.*);
        const lineCpy = try util.copys(line);
        var repeat = initRepeat;
        while (repeat > 0) {
            var word: std.ArrayList(u8) = std.ArrayList(u8).init(gpa.*);
            var readInput: bool = false;
            if (word.items.len == 0 and lineCpy[0] == '.') {
                try simplerSentence.append('.');
            }
            for (lineCpy) |c| {
                if (!readInput) {
                    if (c == '.') {
                        if (word.items.len > 0) {
                            word = std.ArrayList(u8).init(gpa.*);
                            try simplerSentence.append(c);
                        }
                    } else if (c == ' ') {
                        readInput = true;
                        if (word.items.len > 0) {
                            word = std.ArrayList(u8).init(gpa.*);
                        }
                    } else {
                        try word.append(c);
                        try simplerSentence.append(c);
                    }
                } else {
                    try cogNums.append(c);
                }
            }
            repeat -= 1;
            if (repeat > 0) {
                try simplerSentence.append('?');
                try word.append('?');
                try cogNums.append(',');
            }
        }
        var nums = std.ArrayList(u64).init(gpa.*);
        var rawNums = std.mem.split(u8, cogNums.items, ",");
        while (rawNums.next()) |rawNum| {
            if (rawNum.len == 0) {
                continue;
            }
            const num = try std.fmt.parseInt(u64, rawNum, 10);
            try nums.append(num);
        }

        var problem = CogProblem{ .sentence = simplerSentence.items, .nums = nums, .dpCache = std.AutoHashMap(OffsetIdx, u64).init(gpa.*) };
        const combos = try problem.solve(0, 0);
        total += combos;
        // std.debug.print("--- Solution \n", .{});
        // std.debug.print("{s} ", .{simplerSentence.items});
        // for (nums.items) |num| {
        //     std.debug.print("{d},", .{num});
        // }
        // std.debug.print(" - {d} \n", .{combos});
    }

    std.debug.print("Day 12: {d}\n", .{total});
}
