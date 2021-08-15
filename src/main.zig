const std = @import("std");
const fs = std.fs;
const cwd = fs.cwd();
const warn = std.log.warn;

const c = @import("./cpu.zig");

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    var cpu = try c.CPU.init(allocator);
     
    // Read the boot ROM into memory
    const buffer = cwd.readFileAlloc(allocator, "./roms/DMG_ROM.bin", 256) catch |err| {
        warn("unable to open file: {s}\n", .{@errorName(err)});
        return err;
    };

    try cpu.memory.loadRom(buffer);

    cpu.tick();
}
