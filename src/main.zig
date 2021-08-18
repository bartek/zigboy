const std = @import("std");
const fs = std.fs;
const cwd = fs.cwd();
const warn = std.log.warn;

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

    // read first 100 instructions
    var i: usize = 0;
    while (i < 100) : (i += 1) {
        cpu.tick();
    }
}
