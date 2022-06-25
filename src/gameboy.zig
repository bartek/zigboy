const std = @import("std");

const Atomic = std.atomic.Atomic;
const CPU = @import("./cpu.zig").CPU;
const PPU = @import("./ppu.zig").PPU;
const State = @import("./state.zig").State;
const print = std.debug.print;

const FRAME_RATE: i32 = 60;

// The Game Boy is driven by a clock that generates a signal alternating between
// 0 and 1. These are conventionally called ticks. The Game Boy's clock does
// this 4,193,304 times per second.
const clock_speed: i32 = 4194304;

const cycles_per_frame = clock_speed / FRAME_RATE;

fn run(cpu: *CPU, ppu: *PPU, state: *State) void {
    var cycles: i32 = 0;
    while (cycles < cycles_per_frame) : (cycles += 1) {
        // Update state before each CPU tick
        state.append() catch unreachable;

        var instruction = cpu.tick();

        //print("Instruction: {s}\n", .{instruction.label});
        //std.time.sleep(500 * std.time.ns_per_ms);

        ppu.tick();

        state.append_instruction(instruction.label);
    }
}

pub fn run_thread(done: *Atomic(bool), cpu: *CPU, ppu: *PPU, state: *State) void {
    while (!done.load(.Unordered)) {
        run(cpu, ppu, state);
    }
}
