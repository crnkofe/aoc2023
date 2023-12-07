const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

pub fn day6(_: []const u8, _: bool) anyerror!void {
    // TODO: make it read io
    // var file = try std.fs.cwd().openFile(filename, .{});
    // defer file.close();

    var times = std.ArrayList(u128).init(gpa.*);
    var distances = std.ArrayList(u128).init(gpa.*);
    // hardcoded test
    // try times.append(7);
    // try times.append(15);
    // try times.append(30);

    // try distances.append(9);
    // try distances.append(40);
    // try distances.append(200);

    // hardcoded problem
    // try times.append(46);
    // try times.append(82);
    // try times.append(84);
    // try times.append(79);
    //
    // try distances.append(347);
    // try distances.append(1522);
    // try distances.append(1406);
    // try distances.append(1471);

    // hardcoded part2 problem
    try times.append(46828479);
    // try times.append(82);
    // try times.append(84);
    // try times.append(79);
    //
    try distances.append(347152214061471);
    // try distances.append(1522);
    // try distances.append(1406);
    // try distances.append(1471);

    var beatTheRecord: u128 = 1;
    var i: u64 = 0;
    while (i < times.items.len) {
        const ts = times.items[i];
        const distToBeat = distances.items[i];

        // find min time to beat the record
        var waysToBeat: u64 = 0;
        var tc: u64 = 1;
        while (tc < ts) {
            if ((tc * (ts - tc)) > distToBeat) {

                waysToBeat += 1;
            }
            tc += 1;
        }

        beatTheRecord *= waysToBeat;
        i += 1;
    }

    std.debug.print("Day 6 Part 1/2: {d}\n", .{beatTheRecord});
}
