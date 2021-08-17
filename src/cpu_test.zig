const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const mem = std.mem;

const c = @import("./cpu.zig");

const rom = @import("./bootrom.zig");

// assert that boot rom is loading as expected
test "boot rom" {
    var cpu = try c.CPU.init(std.heap.page_allocator);

    try cpu.memory.loadRom(rom.boot_rom[0..]);

    var expected = [3][]const u8{
        "LD SP,u16",
        "XOR A,A",
        "LD HL,u16"
    };

    // tick until pc is 0x100. bootrom is done then
    var i : usize = 0;
    while (cpu.pc < 0x100) : (i += 1) {
        var opcode = cpu.popPC();
        var op = cpu.operation(opcode);
        print("\n\nasserting {s}\n\n", .{expected[i]});

        assert(mem.eql(u8, expected[i], op.label));
    }

    // done
    cpu.deinit();
}

test "registers" {
    var r = c.register{.value = undefined};
    r.setHi(0x12);
    r.setLo(0x34);

    assert(0x12 == r.hi());
    assert(0x34 == r.lo());
    assert(0x1234 == r.hilo());
}
