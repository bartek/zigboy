const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;

const Memory = @import("./memory.zig").Memory;
const SM83 = @import("cpu.zig").SM83;

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

const Test = struct {
    name: []u8,
    initial: Settings,
    final: Settings,
    // TODO: Add cycles field
};

fn readFile(allocator: Allocator, path: []const u8) !std.json.Parsed([]Test) {
    const data = try std.fs.cwd().readFileAlloc(allocator, path, 89000);
    defer allocator.free(data);
    return std.json.parseFromSlice([]Test, allocator, data, .{ .allocate = .alloc_always, .ignore_unknown_fields = true });
}

// load test .json;
// for test in test.json:
//     set initial processor state from test;
//     set initial RAM state from test;
//
//     for cycle in test:
//         cycle processor
//         if we are checking cycle-by-cycle:
//             compare our R/W/MRQ/Address/Data pins against the current cycle;
//
//     compare final RAM state to test and report any errors;
//    compare final processor state to test and report any errors;
test "00" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const t = try readFile(allocator, "src/testdata/00.json");
    defer t.deinit();

    for (t.value) |tt| {
        _ = tt;
        //var memory = try Memory.init(allocator);
        //var cpu = SM83.init(&memory);
        //cpu.af.setHi(tt.initial.a);
        //cpu.af.setLo(tt.initial.f);

        //cpu.bc.setHi(tt.initial.b);
        //cpu.bc.setLo(tt.initial.c);

        //cpu.de.setHi(tt.initial.d);
        //cpu.de.setLo(tt.initial.e);

        //cpu.hl.setHi(tt.initial.h);
        //cpu.hl.setLo(tt.initial.l);

        //cpu.pc = tt.initial.pc;
    }
    try testing.expectEqual(1, 0);
}
