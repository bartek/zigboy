const std = @import("std");
const clap = @import("clap");

const cwd = fs.cwd();
const eql = std.mem.eql;
const fs = std.fs;
const print = std.debug.print;
const warn = std.log.warn;

const stdin = std.io.getStdIn().reader();

const c = @import("./cpu.zig");
const State = @import("./state.zig").State;

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var debug: bool = false;

    // Identify args
    var args = std.process.args();
    while (args.next(allocator)) |error_or_arg| {
        const arg = error_or_arg catch |err| {
            warn("Error parsing arguments: {s}", .{err});
            return err;
        };
        if (eql(u8, arg, "-d")) {
            debug = true;
        }
    }

    var cpu = try c.CPU.init(allocator);

    // Load Tetris into memory
    const buffer = cwd.readFileAlloc(allocator, "./roms/tetris.gb", 32768) catch |err| {
        warn("unable to open file: {s}\n", .{@errorName(err)});
        return err;
    };

    try cpu.memory.loadRom(buffer);

    // State is a connection between modules for debugging, useful things
    var state = try State.init(allocator, &cpu);

    // Open the bootromlog for comparison
    var log = try cwd.openFile("./debug/bootromlog.txt", .{});
    defer log.close();

    const reader = log.reader();
    var line_buffer = try std.ArrayList(u8).initCapacity(allocator, 300);
    defer line_buffer.deinit();

    var i: usize = 0;
    while (true) : (i += 1) {
        // Update state before each CPU tick
        try state.append();

        var instruction = cpu.tick();

        try state.append_instruction(instruction.label);

        reader.readUntilDelimiterArrayList(&line_buffer, '\n', std.math.maxInt(usize)) catch |err| switch (err) {
            error.EndOfStream => {
                // Do nothing, boot rom log is done.
            },
            else => |e| {
                return e;
            },
        };

        var line = line_buffer.items;

        // Pause when state differs from bootromlog
        if (debug) {
            if (!eql(u8, state.top(), line_buffer.items)) {
                quickSleep();
                print("\n\n", .{});
                for (state.current()) |l, index| {
                    print("{d}\t{s}\t{s}\n", .{ i, l, state.instructions.items[index] });
                }

                print("+\t{s}\n", .{line});
                print("\n\n", .{});
            }
        }
    }
}

fn quickSleep() void {
    std.time.sleep(500 * std.time.ns_per_ms);
}
