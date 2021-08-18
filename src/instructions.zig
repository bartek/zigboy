const std = @import("std");
const print = std.debug.print;

const c = @import("./cpu.zig");

// Step is single step within an Opcode
pub const Step = fn(cpu: *c.CPU) void;

// Opcode is an instruction for the CPU
pub const Opcode = struct {
    label: [] const u8, // e.g. "XOR A,A"
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

    switch(opcode) {
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
        0x21 => {
            op =  .{
                .label = "LD HL,u16",
                .value = opcode,
                .length = 3,
                .cycles = 12,
                .steps = &[_]Step{
                    ldHlu16,
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
        else => {
            print("not implemented", .{});
        }
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

