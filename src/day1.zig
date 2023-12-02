const io = std.io;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

pub fn day1(filename: []const u8, v2: bool) anyerror!void {
    // create our general purpose allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // get an std.mem.Allocator from it
    const allocator = gpa.allocator();

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var sum_numbers: u128 = 0;
    var buffer: [1024]u8 = undefined;
    const numbers = "one two three four five six seven eight nine";
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var list = std.ArrayList(u8).init(allocator);
        var sz: u8 = 0;
        var alpha_list = std.ArrayList(u8).init(allocator);
        for (line) |c| {
            if (c >= 48 and c < 58) {
                try list.append(c-48);
                sz = sz + 1;
                alpha_list.deinit();
                alpha_list = std.ArrayList(u8).init(allocator);
            } else {
                try alpha_list.append(c);
            }

            if (v2) {
                var splits = std.mem.split(u8, numbers, " ");
                var tmpn: u8 = 1;
                while (splits.next()) |chunk| {
                    if (alpha_list.items.len >= chunk.len) {
                        const st = alpha_list.items.len - chunk.len;
                        const end = st + chunk.len;
                        if (util.compare(alpha_list.items[st..end], chunk)) {
                            try list.append(tmpn);
                            sz = sz + 1;
                        }
                    }
                    tmpn += 1;
                }
            }

        }
        if (sz == 0) {
            continue;
        }
        const current_number = @as(u128, list.items[0]) * 10 + @as(u128, list.items[sz-1]);
        sum_numbers += current_number;
        list.deinit();
    }
    std.debug.print("Day 1 Part 1: {d}\n", .{sum_numbers});
}
