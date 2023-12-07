const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

var cards = std.AutoHashMap(u8, u8).init(gpa.*);
var hands = std.AutoHashMap(u64, []const u8).init(gpa.*);
var originalHands = std.AutoHashMap(u64, []u8).init(gpa.*);
var part2: bool = false;

fn score(hand: []const u8) anyerror!std.AutoHashMap(u8, u8) {
    var fa = std.AutoHashMap(u8, u8).init(gpa.*);
    var currentF: u8 = 0;
    var ch: u8 = 0;
    var countJ: u8 = 0;
    for (hand) |c| {
        if (ch == 0) {
            ch = c;
            currentF = 1;
        } else if (ch == c) {
            currentF += 1;
        } else {
            if (part2 and (ch == 'J')) {
                countJ += currentF;
            } else {
                try fa.put(currentF, (fa.get(currentF) orelse 0) + 1);
            }
            currentF = 1;
            ch = c;
        }
    }
    if (part2 and (ch == 'J')) {
        countJ += currentF;
    } else {
        try fa.put(currentF, (fa.get(currentF) orelse 0) + 1);
    }

    var i: u8 = 5;
    if (part2) {
        while (i >= 1) {
            if (countJ == 0) break;
            if ((fa.get(i) orelse 0) > 0) {
                try fa.put(i+countJ, (fa.get(i+countJ) orelse 0) + 1);
                try fa.put(i, (fa.get(i) orelse 1) - 1);
                break;
            }
            i -= 1;
        }
        if (countJ == 5) {
            try fa.put(countJ, 1);
        }
    }
    i = 5;
    return fa;
}

fn compare2nd(l: []const u8, r: []const u8) bool {
    var i: u8 = 0;
    while (i < l.len) {
        const cl = cards.get(l[i]) orelse 0;
        const cr = cards.get(r[i]) orelse 0;
        if (cl != cr) {
            return cl < cr;
        }
        i += 1;
    }
    return true;
}

fn compareHandByIndex(context: void, a: u64, b: u64) bool {
    _ = context;

    const leftScore = score(hands.get(a) orelse "") catch unreachable;
    const rightScore = score(hands.get(b) orelse "") catch unreachable;
    // 5 is max frequency
    var i: u8 = 5;
    while (i >= 1) {
        const scoreLI = (leftScore.get(i) orelse 0);
        const scoreRI = (rightScore.get(i) orelse 0);
        if ((scoreLI != 0) and (scoreRI != 0)) {
            if (i == 3 and
                (((leftScore.get(2) orelse 0) != 0) or
                 ((rightScore.get(2) orelse 0) != 0))) {
                // if full house just skip 3 comparison and compare 2s instead
                i -= 1;
                continue;
            }
            if (scoreLI != scoreRI) {
                return scoreLI < scoreRI;
            } else {
                const ret = compare2nd(originalHands.get(a) orelse "", originalHands.get(b) orelse "");
                return ret;
            }
        } else if (scoreLI != 0) {
            return false;
        } else if (scoreRI != 0) { // ri > li
            return true;
        }
        i -= 1;
    }
    return a < b;
}

fn lt(context: void, a: u8, b: u8) bool {
    _ = context;
    return a < b;
}

pub fn day7(filename: []const u8, p2: bool) anyerror!void {
    part2 = p2;
    const allCardsP1: []const u8 = "AKQJT98765432";
    const allCardsP2: []const u8 = "AKQT98765432J";
    var cardIndex: u8 = 0;
    if (!p2) {
        // std.debug.print("Part 1 {s}\n", .{allCardsP1});
        for (allCardsP1) |c| {
            try cards.put(c, 13 - cardIndex);
            cardIndex += 1;
        }
    } else {
        // std.debug.print("Part 2 {s}\n", .{allCardsP2});
        for (allCardsP2) |c| {
            try cards.put(c, 13 - cardIndex);
            cardIndex += 1;
        }
    }

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var totalScore: u128 = 0;
    var bets = std.AutoHashMap(u64, u128).init(gpa.*);
    // indices will be sorted by rank desc (initially from 0..count file lines)
    var indices = std.ArrayList(u64).init(gpa.*);
    var buffer: [1024]u8 = undefined;
    var lineno: u64 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var handArr = std.ArrayList(u8).init(gpa.*);
        var originalArr = std.ArrayList(u8).init(gpa.*);
        var mapping = std.mem.split(u8, line, " ");

        const rawHand = mapping.next() orelse "";
        for (rawHand) |c| {
            try handArr.append(c);
            try originalArr.append(c);
        }
        const bet = try std.fmt.parseInt(u128, mapping.next() orelse "0", 10);

        std.sort.insertion(u8, handArr.items, {}, lt);

        try hands.put(lineno, handArr.items);
        try bets.put(lineno, bet);
        try indices.append(lineno);
        try originalHands.put(lineno, originalArr.items);
        lineno += 1;
    }

    std.sort.insertion(u64, indices.items, {}, compareHandByIndex);

    var ci: u64 = 1;
    for (indices.items) |idx| {
        totalScore += ci * (bets.get(idx) orelse 0);
        ci += 1;
    }
    std.debug.print("Day 7: {d}\n", .{totalScore});
}