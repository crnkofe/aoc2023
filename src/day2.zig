const io = std.io;
const std = @import("std");
const clap = @import("zig-clap");
const util = @import("util.zig");

pub fn day2(filename: []const u8, _: bool) anyerror!void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var possibleGames: i32 = 0;
    var buffer: [1024]u8 = undefined;
    var funnySum: i32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var gameData = std.mem.split(u8, line, ": ");
        var gameDataN: u8 = 0;
        var gamePossible: bool = true;
        var gameIndex: i32 = 0;
        var minRed: i32 = 0;
        var minBlue: i32 = 0;
        var minGreen: i32 = 0;        
        while (gameData.next()) |gameDataChunk| {
            if (gameDataN > 0) {
                var moveCounts = std.mem.split(u8, gameDataChunk, "; ");
                while (moveCounts.next()) |moveCountChunk| {
                    var countColors = std.mem.split(u8, moveCountChunk, ", ");
                    while (countColors.next()) |countColorChunk| {
                        var countColor = std.mem.split(u8, countColorChunk, " ");
                        var count: i32 = 0;
                        var ccci: u8 = 0;
                        while (countColor.next()) |countOrColorChunk| {
                            if (ccci == 0) {
                                count = try std.fmt.parseInt(i32, countOrColorChunk, 10);
                            } else {
                                if (util.compareConst(countOrColorChunk, "red")) {
                                    if (count > 12) {
                                        gamePossible = false;
                                    }
                                    minRed = @max(count, minRed);
                                } else if (util.compareConst(countOrColorChunk, "green")) {
                                    if (count > 13) {
                                        gamePossible = false;
                                    }
                                    minGreen = @max(count, minGreen);
                                } else if (util.compareConst(countOrColorChunk, "blue")) {
                                    if (count > 14) {
                                        gamePossible = false;
                                    }
                                    minBlue = @max(count, minBlue);
                                }
                            }
                            ccci += 1;
                        }
                    }
                }
            } else {
                var gameIndexes = std.mem.split(u8, gameDataChunk, " ");
                var gameChunkIndex: u8 = 0;
                while (gameIndexes.next()) |gameIndexChunk| {
                    if (gameChunkIndex == 1) {
                        gameIndex = try std.fmt.parseInt(i32, gameIndexChunk, 10);
                    }
                    gameChunkIndex += 1;
                }
            }
            gameDataN += 1;
        }
        if (gamePossible) {
            possibleGames += gameIndex;
        }
        funnySum += minBlue * minRed * minGreen;
    }
    std.debug.print("Day 2: {d}\n", .{possibleGames});
    std.debug.print("Day 2 part 2: {d}\n", .{funnySum});
}
