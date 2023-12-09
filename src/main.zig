const io = std.io;
const std = @import("std");
const clap = @import("zig-clap");
const day1 = @import("day1.zig");
const day2 = @import("day2.zig");
const day3 = @import("day3.zig");
const day4 = @import("day4.zig");
const day5 = @import("day5.zig");
const day6 = @import("day6.zig");
const day7 = @import("day7.zig");
const day8 = @import("day8.zig");
const day9 = @import("day9.zig");

pub fn main() anyerror!void {
    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-h, --help         Display this help and exit.
        \\-d, --day <u8>     Run nth day algorithm (Day 1 by default).
        \\-2, --v2           Run v2 version for day.
        \\-i, --input <str>  Filename with input.
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        // Report useful error and exit
        diag.report(io.getStdErr().writer(), err) catch {};
        return;
    };
    defer res.deinit();

    if (res.args.day == 1) {
        return day1.day1(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 2) { 
        return day2.day2(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 3) { 
        return day3.day3(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 4) { 
        return day4.day4(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 5) {
        return day5.day5(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 6) {
        return day6.day6(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 7) {
        return day7.day7(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 8) {
        return day8.day8(res.args.input orelse "", res.args.v2 > 0);
    } else if (res.args.day == 9) {
            return day9.day9(res.args.input orelse "", res.args.v2 > 0);
    } else {
        std.debug.print("Unknown day {d}\n", .{res.args.day orelse 0});
    }
}
