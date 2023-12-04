
const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

pub fn day4(filename: []const u8, _: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var totalElfScore: u64 = 0;

    var buffer: [1024]u8 = undefined;

    var cardIndex: u8 = 1;
    var scratchCards = std.AutoHashMap(u64, u64).init(gpa.*);

    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {        
        try scratchCards.put(cardIndex, 1 + (scratchCards.get(cardIndex) orelse 0));
        var splits = std.mem.split(u8, line, ": ");
        // skip card index
        _ = splits.next();
        const hand = splits.next() orelse "";

        var winsMap = std.AutoHashMap(u64, bool).init(gpa.*);
        var winsDraws = std.mem.split(u8, hand, " | ");
        const wins = winsDraws.next() orelse "";
        const draws = winsDraws.next() orelse "";
        var currentWin: u64 = 0;
        for (wins) |w| {
            if (util.isnum(w)) {
                currentWin = currentWin * 10 + util.getnum(w);
            } else {
                try winsMap.put(currentWin, true);
                currentWin = 0;
            }
        }
        try winsMap.put(currentWin, true);

        var handScore: u64 = 0;
        var currentDraw: u64 = 0;
        var di: u64 = 1;
        for (draws) |d| {
            if (util.isnum(d)) {
                currentDraw = currentDraw * 10 + util.getnum(d);
            } else if (currentDraw > 0) {
                const nextScratchCard: u64 = di + cardIndex;
                if (winsMap.contains(currentDraw)) {                    
                    try scratchCards.put(nextScratchCard, (scratchCards.get(nextScratchCard) orelse 0) + (scratchCards.get(cardIndex) orelse 1));
                    di += 1;
                    if (handScore == 0) {
                        handScore = 1;
                    } else {
                        handScore *= 2;
                    }
                }
                currentDraw = 0;
            }
        }
        if ((currentDraw > 0) and (winsMap.contains(currentDraw))) {
                const nextScratchCard: u64 = di + cardIndex;
                try scratchCards.put(nextScratchCard, (scratchCards.get(nextScratchCard) orelse 0) + (scratchCards.get(cardIndex) orelse 1));
            if (handScore == 0) {
                handScore = 1;
            } else {
                handScore *= 2;
            }
        }
        totalElfScore += handScore;
        cardIndex += 1;
    }

    var totalCardCount: u64 = 0;
    var it = scratchCards.iterator();
    while (it.next()) |kv| {
        totalCardCount += kv.value_ptr.*;
    }

    std.debug.print("Day 4 Part 1: {d}\n", .{totalElfScore});
    std.debug.print("Day 4 Part 2: {d}\n", .{totalCardCount});
}
