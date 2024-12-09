const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const Memory = @import("./memory.zig").Memory;
const SM83 = @import("cpu.zig").SM83;
const Registers = @import("cpu.zig").Registers;
const RamEntry = @import("cpu.zig").RamEntry;
const register = @import("cpu.zig").register;

const Settings = struct {
    a: u8,
    b: u8,
    c: u8,
    d: u8,
    e: u8,
    f: u8,
    h: u8,
    l: u8,
    pc: u16,
    sp: u16,
    ram: [][]u16,
};

// Test is a test case, as per testdata
const Test = struct {
    name: []u8,
    initial: Settings,
    final: Settings,
    // TODO: Add cycles field
};

fn readFile(allocator: Allocator, path: []const u8) !std.json.Parsed([]Test) {
    const data = try std.fs.cwd().readFileAlloc(allocator, path, 890000);
    defer allocator.free(data);
    return std.json.parseFromSlice([]Test, allocator, data, .{ .allocate = .alloc_always, .ignore_unknown_fields = true });
}

// Each element in the array is a test case, where we instantiate our CPU
// based on the initial state form the test case. Then, fetch and execute
// single instruction.
//
// Once done, compare expected state ("final") with actual CPU state.
//
// Reset for each test case.
//
// TODO: For Cycle accuracy, can use expected cycles value from test case.
test "SM83 00" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const t = try readFile(allocator, "testdata/01.json");
    defer t.deinit();

    for (t.value) |tt| {
        std.debug.print("name: {s}\n", .{tt.name});

        var af = register.init(0x00);
        af.setHi(tt.initial.a);
        af.setLo(tt.initial.f);

        var bc = register.init(0x00);
        bc.setHi(tt.initial.b);
        bc.setLo(tt.initial.c);

        var de = register.init(0x00);
        de.setHi(tt.initial.d);
        de.setLo(tt.initial.e);

        var hl = register.init(0x00);
        hl.setHi(tt.initial.h);
        hl.setLo(tt.initial.l);

        var cpu = try SM83.init(allocator, .{
            .registers = Registers.init(.{
                .af = af,
                .bc = bc,
                .de = de,
                .hl = hl,
            }),
            // adtennant tests have a design decision were initial and final PC
            // is off by 1 (compard to the implementation)
            //
            // Via https://github.com/adtennant/GameboyCPUTests
            // The tests assume a decode-execute-prefetch loop and so start at
            // PC+1, with the final cycle being the prefetch of the next
            // instruction. See Gameboy CPU Internals for more info.
            .pc = tt.initial.pc - 1,
            .sp = tt.initial.sp,
            .ram = tt.initial.ram,
        });

        _ = cpu.tick();

        try testing.expectEqual(tt.final.pc - 1, cpu.pc);
        try testing.expectEqual(tt.final.sp, cpu.sp);
        try testing.expectEqual(tt.final.a, cpu.registers.af.hi());
        try testing.expectEqual(tt.final.f, cpu.registers.af.lo());
        try testing.expectEqual(tt.final.b, cpu.registers.bc.hi());
        try testing.expectEqual(tt.final.c, cpu.registers.bc.lo());
        try testing.expectEqual(tt.final.d, cpu.registers.de.hi());
        try testing.expectEqual(tt.final.e, cpu.registers.de.lo());
        try testing.expectEqual(tt.final.l, cpu.registers.hl.lo());
        try testing.expectEqual(tt.final.h, cpu.registers.hl.hi());
    }
}
