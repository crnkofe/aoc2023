const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

fn isnum(c: u8) bool {
    return (c >= 48 and c < 58);
}

fn getnum(c: u8) u8 {
    return c - 48;
}

// only relevant for day3 where everything except . and numbers is a symbol
fn issymbol(c: u8) bool {
    if (c == '.') {
        return false;
    }

    return (((c >= 33) and (c <= 47))
        or ((c >= 58) and (c <= 64))
        or ((c >= 91) and (c <= 96))
        or ((c >= 123) and (c <= 126)));
}

fn nthordot(n: u8, s: []u8) u8 {
    if (n >= s.len) {
        return '.';
    }
    return s[n];
}

// Parse engine parts from s2
// engine part is a number where adjacent squares in 8 directions contain
// a symbol (not '.' which is just empty space)
pub fn parseEngineParts(s2row: u8, s1: []u8, s2: []u8, s3: []u8, cogCount: *std.AutoHashMap(u64, usize), cogMult: *std.AutoHashMap(u64, usize)) anyerror!u32 {
    var partSum: u32 = 0;
    var idx: u8 = 0;
    var currentNum: u32 = 0;
    var isEnginePart: bool = false;
    const r1: u64 = s2.len * (s2row-1);
    const r2: u64 = s2.len * s2row;
    const r3: u64 = s2.len * (s2row+1);
    var addedCogs = std.ArrayList(u64).init(gpa.*);
    for (s2) |c2| {
        if (isnum(c2)) {
            // check for engine part number before number start
            if ((currentNum == 0) and (idx > 0)) {
                if (issymbol(nthordot(idx-1, s1)) 
                    or issymbol(nthordot(idx-1, s2))
                    or issymbol(nthordot(idx-1, s3))) {
                    isEnginePart = true;
                }
                if (nthordot(idx-1, s1) == '*') {
                    try cogCount.put(r1+idx-1, (cogCount.get(r1+idx-1) orelse 0) + 1);
                    try addedCogs.append(r1+idx-1);
                }
                if (nthordot(idx-1, s2) == '*') {
                    try cogCount.put(r2+idx-1, (cogCount.get(r2+idx-1) orelse 0) + 1);
                    try addedCogs.append(r2+idx-1);
                }
                if (nthordot(idx-1, s3) == '*') {
                    try cogCount.put(r3+idx-1, (cogCount.get(r3+idx-1) orelse 0) + 1);
                    try addedCogs.append(r3+idx-1);
                }
            }

            if (issymbol(nthordot(idx, s1)) or issymbol(nthordot(idx, s3))) {
                if (nthordot(idx, s1) == '*') {
                    try cogCount.put(r1+idx, (cogCount.get(r1+idx) orelse 0) + 1);
                    try addedCogs.append(r1+idx);
                }
                if (nthordot(idx, s3) == '*') {
                    try cogCount.put(r3+idx, (cogCount.get(r3+idx) orelse 0) + 1);
                    try addedCogs.append(r3+idx);
                }
                isEnginePart = true;
            }
            currentNum = @as(u32, currentNum) * 10 + @as(u32, getnum(c2));
        } else {
            if (currentNum > 0) {
                if (issymbol(nthordot(idx, s1))
                    or issymbol(nthordot(idx, s2))
                    or issymbol(nthordot(idx, s3))) {
                    isEnginePart = true;

                    if (nthordot(idx, s1) == '*') {
                        try cogCount.put(r1+idx, (cogCount.get(r1+idx) orelse 0) + 1);
                        try addedCogs.append(r1+idx);
                    }
                    if (nthordot(idx, s2) == '*') {
                        try cogCount.put(r2+idx, (cogCount.get(r2+idx) orelse 0) + 1);
                        try addedCogs.append(r2+idx);
                    }
                    if (nthordot(idx, s3) == '*') {
                        try cogCount.put(r3+idx, (cogCount.get(r3+idx) orelse 0) + 1);
                        try addedCogs.append(r3+idx);
                    }
                }
                
            }
            if (isEnginePart) {
                partSum += currentNum;
                for (addedCogs.items) |cog| {            
                    try cogMult.put(cog, (cogMult.get(cog) orelse 1) * currentNum);
                }
                addedCogs.clearRetainingCapacity();
            }

            currentNum = 0;
            isEnginePart = false;
        }
        idx += 1;
    }
    if (isEnginePart) {
        partSum += currentNum;
        for (addedCogs.items) |cog| {            
            try cogMult.put(cog, (cogMult.get(cog) orelse 1) * currentNum);
        }
    }
    return partSum;
}

pub fn day3(filename: []const u8, _: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buffer: [1024]u8 = undefined;
    var lineno: u8 = 0;

    var line1: []u8 = &[_]u8{};
    var line2: []u8 = &[_]u8{};
    var line3: []u8 = &[_]u8{};

    var ln:usize = 0;
    var totalPartSum:u32 = 0;

    var cogCount = std.AutoHashMap(u64, usize).init(gpa.*);
    var cogMult = std.AutoHashMap(u64, usize).init(gpa.*);
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (lineno == 0) {
            line1 = try gpa.alloc(u8, line.len);
            line2 = try gpa.alloc(u8, line.len);
            line3 = try gpa.alloc(u8, line.len);
            ln = line.len;
        }
        std.mem.copyForwards(u8, line1, line2);
        std.mem.copyForwards(u8, line2, line3);
        std.mem.copyForwards(u8, line3, line);

        if (lineno > 0) {
            totalPartSum += try parseEngineParts(lineno, line1, line2, line3, &cogCount, &cogMult);
        }
        lineno += 1;
    }
    totalPartSum += try parseEngineParts(lineno, line2, line3, &[_]u8{}, &cogCount, &cogMult);
    std.debug.print("Day 3 Part 1: {d}\n", .{totalPartSum});

    var sumPairs: u64 = 0;
    var it = cogCount.iterator();
    while (it.next()) |kv| {
        if (kv.value_ptr.* == 2) {
            sumPairs += cogMult.get(kv.key_ptr.*) orelse 0;
        }
    }
    std.debug.print("Day 3 Part 2: {d}\n", .{sumPairs});
}
