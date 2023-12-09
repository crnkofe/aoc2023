const io = std.io;
const mem = std.mem;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_instance.allocator();

pub fn day9(filename: []const u8, part2: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var sumPredictions: i64 = 0;
    // indices will be sorted by rank desc (initially from 0..count file lines)
    var buffer: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var nums = std.ArrayList(i64).init(gpa.*);
        var rawNums = std.mem.split(u8, line, " ");
        while (rawNums.next()) |rawNum| {
            const num = try std.fmt.parseInt(i64, rawNum, 10);
            try nums.append(num);
        }

        var numSteps = std.ArrayList(std.ArrayList(i64)).init(gpa.*);
        try numSteps.append(nums);
        var lastDiff:i64 = 0;
        var anyDiff: bool = true;
        if (!part2) {
            lastDiff = nums.items[nums.items.len-1] - nums.items[nums.items.len-2];
        } else {
            lastDiff = nums.items[1] - nums.items[0];
        }
        var step: u8 = 1;
        while ((!part2 and (lastDiff != 0)) or (part2 and anyDiff)) {
            anyDiff = false;
            var newNums = std.ArrayList(i64).init(gpa.*);
            var ni: u8 = 1;
            var n: i64 = nums.items[0];
            while (ni < nums.items.len) {
                lastDiff = nums.items[ni] - n;
                if (lastDiff != 0) {
                    anyDiff = true;
                }
                try newNums.append(nums.items[ni] - n);
                n = nums.items[ni];
                ni += 1;
            }
            try numSteps.append(newNums);
            nums = newNums;
            step += 1;
        }

        var predictedValue: i64 = 0;
        while (step > 0) {
            const stepNumsM1 = numSteps.items[step-1];
            if (!part2) {
                predictedValue += stepNumsM1.items[stepNumsM1.items.len-1];
            } else {
                predictedValue = stepNumsM1.items[0] - predictedValue;
            }

            step -= 1;
        }
        sumPredictions += predictedValue;
    }

    std.debug.print("Day 9: {d}\n", .{sumPredictions});
}