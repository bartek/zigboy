const std = @import("std");
const print = std.debug.print;
const fs = std.fs;
const cwd = fs.cwd();
const warn = std.log.warn;

const stdin = std.io.getStdIn().reader();

const c = @import("./cpu.zig");

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var cpu = try c.CPU.init(allocator);

    // Load Tetris into memory
    const buffer = cwd.readFileAlloc(allocator, "./roms/tetris.gb", 32768) catch |err| {
        warn("unable to open file: {s}\n", .{@errorName(err)});
        return err;
    };

    try cpu.memory.loadRom(buffer);

    // Open the bootromlog for comparison
    var log = try cwd.openFile("bootromlog.txt", .{});
    defer log.close();

    const reader = log.reader();
    var line_buffer = try std.ArrayList(u8).initCapacity(allocator, 300);
    defer line_buffer.deinit();

    var i: usize = 0;
    while (true) : (i += 1) {
        print("{d} ", .{i});
        cpu.tick();

        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.maxInt(usize)) catch |err| switch (err) {
            error.EndOfStream => { break; },
            else => |e| return e,
        };

        var line = line_buffer.items;
        print("{d} {s}\n", .{i, line});

        // Pause on each line
        var buf: [10]u8 = undefined;

        if (i > 24588) {
            var userInput = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
        }
    }
}
