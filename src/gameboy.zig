const std = @import("std");

const Atomic = std.atomic.Atomic;
const CPU = @import("./cpu.zig").CPU;
const State = @import("./state.zig").State;
const print = std.debug.print;

const FRAME_RATE: i32 = 60;
const clock_speed: i32 = 4194304;

const cycles_per_frame = clock_speed / FRAME_RATE;

fn run(cpu: *CPU, state: *State) void {
    var cycles: i32 = 0;
    while (cycles < cycles_per_frame) : (cycles += 1) {
        // Update state before each CPU tick
        state.append() catch unreachable;

        var instruction = cpu.tick();

        state.append_instruction(instruction.label);
    }
}

pub fn runThread(done: *Atomic(bool), cpu: *CPU, state: *State) void {
    while (!done.load(.Unordered)) {
        run(cpu, state);
    }
}
