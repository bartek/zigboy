const std = @import("std");
const print = std.debug.print;

const c = @import("./cpu.zig");

// Step is single step within an Opcode
pub const Step = fn (cpu: *c.CPU) void;

// Opcode is an instruction for the CPU
pub const Opcode = struct {
    label: []const u8, // e.g. "XOR A,A"
    value: u16, // e.g. 0x31
    length: u8,
    cycles: u8, // clock cycles

    // Zig note: The usage of .steps in initializing the Opcode looks like so:
    // .steps = &[_]Step{
    //     ldSpu16,
    // }
    // This is implicitly a constant, and thus, we have to give the compiler a
    // hint that this is expected, hence the `const` in this definition.
    // Alternatively, the steps could be explicitly defined as a non-constant
    // (var steps = [_]Step{...}, but it feels syntactically more enjoyable to
    // do it this way.
    steps: []const Step,
};

pub fn operation(cpu: *c.CPU, opcode: u16) Opcode {
    print("0x{x}\n", .{opcode});

    var op: Opcode = .{
        .label = undefined,
        .value = opcode, // This is repeated. Not sure why Zig doesn't allow it to be omitted in the subsequent usage.
        .length = undefined,
        .cycles = undefined,
        .steps = undefined,
    };

    switch (opcode) {
        0x0 => {
            op = .{
                .label = "NOP",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{},
            };
        },
        0x31 => {
            op = .{
                .label = "LD SP,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .steps = &[_]Step{
                    ldSpu16,
                },
            };
        },
        0x20 => {
            op = .{
                .label = "JR NZ,u8",
                .value = opcode,
                .length = 2,
                .cycles = 12, // FIXME: with/without branch timing to review
                .steps = &[_]Step{
                    jrNz8,
                },
            };
        },
        0x21 => {
            op = .{
                .label = "LD HL,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .steps = &[_]Step{
                    ldHlu16,
                },
            };
        },
        0x32 => {
            op = .{
                .label = "LD (HL-),A",
                .value = opcode,
                .length = 1,
                .cycles = 8,
                .steps = &[_]Step{
                    ldHlA,
                },
            };
        },
        // XOR A,A
        // Bitwise XOR between the value in register A
        0xaf => {
            op = .{
                .label = "XOR A,A",
                .value = opcode,
                .length = 1,
                .cycles = 4,
                .steps = &[_]Step{
                    xorAA,
                },
            };
        },

        // -- Extended Callbacks
        // called via the opcode 0xcb which is an extended opcode meaning
        // the next immediate byte has to be decoded and treated as the opcode
        0xcb => {
            var next: u16 = cpu.popPC();
            op = extendedOperation(cpu, next);
        },
        else => {
            print("not implemented\n", .{});
        },
    }

    return op;
}

fn extendedOperation(cpu: *c.CPU, opcode: u16) Opcode {
    print("[extended]: 0x{x}\n", .{opcode});

    var op: Opcode = .{
        .label = undefined,
        .value = opcode, // This is repeated. Not sure why Zig doesn't allow it to be omitted in the subsequent usage.
        .length = undefined,
        .cycles = undefined,
        .steps = undefined,
    };

    switch (opcode) {
        0x7c => {
            op = .{
                .label = "BIT 7,H",
                .value = opcode,
                .length = 2,
                .cycles = 8,
                .steps = &[_]Step{
                    bit7h,
                },
            };
        },
        else => {
            print("[extended] not implemented\n", .{});
        },
    }

    return op;
}

// LD SP,16
fn ldSpu16(cpu: *c.CPU) void {
    cpu.sp = cpu.popPC16();
}

// LD HL,u16
fn ldHlu16(cpu: *c.CPU) void {
    cpu.hl.set(cpu.popPC16());
}

// LD (HL-),A
// Load to the address specified by the 16-bit register HL, data from A
// The value of HL is decremented after memory write
fn ldHlA(cpu: *c.CPU) void {
    var address: u16 = cpu.hl.hilo();
    cpu.memory.write(address, cpu.af.hi());
    cpu.hl.set(cpu.hl.hilo() - 1);
}

// XOR A,A
fn xorAA(cpu: *c.CPU) void {
    var a1: u8 = cpu.af.hi();
    var a2: u8 = cpu.af.hi();

    var v: u8 = a1 ^ a2;
    cpu.af.setHi(v);

    // Set flags
    cpu.setZ(v == 0);
    cpu.setN(false);
    cpu.setH(false);
    cpu.setC(false);
}

// Jumps

// JR NZ,u8
// Unconditional jump to the relative address specified by popping PC, only
// occurring if Z is false
fn jrNz8(cpu: *c.CPU) void {
    var address: u16 = cpu.popPC();
    if (!cpu.Z()) {
        var next: u16 = cpu.pc + address;
        print("Jumping to {x}\n", .{next});
        cpu.pc = next;
    }
}

// Extended Operations

// BIT 7,H
// Test bit at index 7 using value H
fn bit7h(cpu: *c.CPU) void {
    var v: u8 = cpu.hl.hi();
    var index: u3 = 7;

    cpu.setZ((v >> index) & 1 == 0);
    cpu.setN(false);
    cpu.setH(true);
}
