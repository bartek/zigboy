const std = @import("std");

const c = @import("./cpu.zig");

const rom = @import("./bootrom.zig");

// assert that boot rom is loading as expected
test "boot rom" {
    var cpu = try c.CPU.init(std.heap.page_allocator);

    try cpu.memory.loadRom(rom.boot_rom[0..]);

    // expectations:
    var expected = [_]u8{
        0x31,
    };

    // tick until pc is 0x100. bootrom is done then
    while (cpu.pc < 0x100) {
        cpu.tick();
    }

    // done
    cpu.deinit();
}
