const io = std.io;
const std = @import("std");
const clap = @import("zig-clap");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

pub const Point = struct {
    x: u8,
    y: u8,

    pub fn eq(self: Point, p2: Point) bool {
        return self.x == p2.x and self.y == p2.y;
    }
};

pub const Point64 = struct {
    x: u64,
    y: u64,

    pub fn eq(self: Point, p2: Point) bool {
        return self.x == p2.x and self.y == p2.y;
    }
};

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

pub fn copys(s: []const u8) anyerror![]const u8 {
    const cp: []u8 = try gpa.alloc(u8, s.len);
    std.mem.copyForwards(u8, cp, s);
    return cp;
}
