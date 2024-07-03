pub const CPU = @import("testing_cpu.zig");

test {
    @import("std").testing.refAllDecls(@This());
}
