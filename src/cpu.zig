const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

// Set a bit and return the new value
fn set(value: u8, bit: u8) u8 {
    return value | (1 << bit);
}

// TODO
fn reset(value: u8, bit: u8) u8 {
    //return value & ^(1 << bit);
}


const register = struct {
    value: u16,

    pub fn setLo(self: *register, value: u8) void {
        self.value = @intCast(u16, value) | @intCast(u16, self.value)&0xFF00;
    }

    pub fn setHi(self: *register, value: u8) void {
        self.value = @intCast(u16, value)<<8 | (@intCast(u16, self.value) & 0xFF);
    }

    pub fn hilo(self: *register) u16 {
        return self.value;
    }

    pub fn lo(self: *register) u8 {
        return self.value & 0xFF;
    }

    pub fn hi(self: *register) u8 {
        return @intCast(u8, self.value >> 8);
    }
};


pub const Memory = struct {
    // GameBoy contains an 8-bit processor, meaning it can access 8-bits of data
    // at one time. To access this data, it has a 16-bit address bus, which can
    // address 65,536 positions of memory.
    const memory_size = 65536;

    allocator: *Allocator,
    memory: []u8,

    pub fn init(allocator: *Allocator) !Memory {
        return Memory{
            .allocator = allocator,
            .memory = try allocator.alloc(u8, memory_size),
        };
    }

    pub fn deinit(self: *Memory) void {
        self.allocator.free(self.memory);
    }

    pub fn read(self: *Memory, address: u16) u8 {
        return self.memory[address];
    }

    pub fn write(self: *Memory, address: u16, value: u8) void {
        self.memory[address] = value;
    }

    pub fn loadRom(self: *Memory, buffer: []u8) !void {
        for (buffer) |b, index| {
            self.write(@intCast(u16, index), b);
        }
    }
};

// The GameBoy CPU is composed of 8 different registers which are responsible
// for holding onto little pieces of data that the CPU can manipulate when it
// executes various instructions. These registers are named A, B, C, D, E, F, H,
// and L. Since they are 8-bit registers, they can hold only 8-bit values.
// However, the GameBoy can combine two registers in order to read and write
// 16-bit values. The valid combinations then are AF, BC, DE, and HL.
pub const CPU = struct {
    af: register,
    bc: register,
    de: register,
    hl: register,

    // Program Counter
    pc: u16,

    // Stack Pointer
    sp: u16,

    memory: Memory,

    pub fn init(allocator: *Allocator) !CPU {
        return CPU{
            .memory = try Memory.init(allocator),
            .af = undefined,
            .bc = undefined,
            .de = undefined,
            .hl = undefined,
            .pc = 0x00,
            .sp = undefined,
        };
    }

    pub fn deinit(self: *CPU) void {
        self.memory.deinit();
    }

    // tick ticks the CPU
    pub fn tick(self: *CPU) void{ 
        var opcode = self.popPC();
        self.execute(opcode);
    }

    // popPC reads a single byte from memory and increments PC
    fn popPC(self: *CPU) u16 {
        var opcode: u16 = self.memory.read(self.pc);
        self.pc += 1;
        return opcode;
    }

    fn popPC16(self: *CPU) u16 {
        var b1: u16 =  self.popPC();
        var b2: u16 = self.popPC();
        return b2 << 8 | b1;
    }


    // The F register is a special register because it contains the values of 4
    // flags which allow the CPU to track particular states:
    //
    pub fn setFlag(self: *CPU, index: u8, on: bool) void {
        if (on) {
            self.af.setLo(set(self.af.lo(), index));
        } else {
            self.af.setLo(reset(self.af.lo(), index));
        }
    }

    // Zero Flag. Set when the result of a mathemetical instruction is zero
    pub fn Z(self: *CPU) bool {
        return self.af.hilo()>>7&1 == 1;
    }

    // setZ sets the zero flag
    pub fn setZ(self: *CPU, on: bool) void {
        self.setFlag(7, on);
    }

    // setN sets the negative flag
    pub fn setN(self: *CPU, on:bool) void {
        self.setFlag(6, on);
    }

    // setH sets the half carry flag
    pub fn setH(self: *CPU, on: bool) void {
        self.setFlag(5, on);
    }


    // setC sets the carry flag
    pub fn setC(self: *CPU, on:bool) void {
        self.setFlag(4, on);
    }

    // execute acepts an opcode and executes the relevant instruction
    // https://izik1.github.io/gbops/index.html
    // TODO: Better understand length and clock cycles
    pub fn execute(self: *CPU, opcode: u16) void {
        print("0x{x}\n", .{opcode});

        var cycles: u8 = undefined;
        var length: u8 = undefined;

        switch(opcode) {
            // LD SP,u16
            0x31 => {
                self.sp = self.popPC16();
            },
            // XOR A,A
            // Bitwise XOR between the value in register A
            0xaf => {
                var a1: u8 = self.af.hi();
                var a2: u8 = self.af.hi();

                var v: u8 = a1 ^ a2;
                self.af.setHi(v);

                // Set flags
                self.setZ(v == 0);
                self.setN(false);
                self.setH(false);
                self.setC(false);
            },
            else => {
                print("not implemented", .{});
            }
        }
    }
};

