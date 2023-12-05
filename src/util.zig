const io = std.io;
const std = @import("std");
const clap = @import("zig-clap");

pub fn compare(s1: []u8, s2: []const u8) bool {
    if (s1.len != s2.len) {
        return false;
    }
    return std.mem.eql(u8, s1, s2);
}

pub fn compareConst(s1: []const u8, s2: []const u8) bool {
    if (s1.len != s2.len) {
        return false;
    }
    return std.mem.eql(u8, s1, s2);
}

pub fn isnum(c: u8) bool {
    return (c >= 48 and c < 58);
}

pub fn getnum(c: u8) u8 {
    return c - 48;
}