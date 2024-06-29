const std = @import("std");
const AtomicOrder = std.builtin.AtomicOrder;
const Atomic = std.atomic;
const CPU = @import("./cpu.zig").SM83;
const print = std.debug.print;

const FRAME_RATE: i32 = 60;

// The Game Boy is driven by a clock that generates a signal alternating between
// 0 and 1. These are conventionally called ticks. The Game Boy's clock does
// this 4,193,304 times per second.
const clock_speed: i32 = 4194304;

const cycles_per_frame = clock_speed / FRAME_RATE;

fn run(cpu: *CPU) void {
    var cycles: i32 = 0;
    while (cycles < cycles_per_frame) : (cycles += 1) {
        _ = cpu.tick();
    }
}

pub fn run_thread(done: *Atomic.Value(bool), cpu: *CPU) void {
    while (!done.load(AtomicOrder.unordered)) {
        run(cpu);
    }
}
