const std = @import("std");
const eql = std.mem.eql;
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
        cpu.tick();

        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.maxInt(usize)) catch |err| switch (err) {
            error.EndOfStream => {
                // Do nothing, boot rom log is done.
            },
            else => |e| { return e; },
        };

        var line = line_buffer.items;

        // Pause when state differs from bootromlog
        if (!eql(u8, cpu.state().items, line_buffer.items)) {
            print("{d} {s}\n", .{i, cpu.state().items});

            // Display current CPU state
            print("{d} {s}\n", .{i, line});
            var buf: [10]u8 = undefined;
            var userInput = try stdin.readUntilDelimiterOrEof(buf[0..], '\n');
        }
    }
}
