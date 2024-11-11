const std = @import("std");
const testing = std.testing;

// test if a bit is set
pub fn is_set(value: u8, bit: u3) bool {
    return (value >> bit) & 1 == 1;
}

// set a bit and return the new value
pub fn set(value: u8, bit: u3) u8 {
    return value | (@as(u8, 1) << bit);
}

// clears a bit and returns the value
pub fn clear(value: u8, bit: u3) u8 {
    return value & ~(@as(u8, 1) << bit);
}

// return the value of a bit
pub fn val(value: u8, bit: u3) u8 {
    return (value >> bit) & 1;
}

test "bits" {
    // 10111111 -> 11111111 (set bit 6)
    try testing.expectEqual(false, is_set(0xbf, 6));
    const b = set(0xbf, 6);
    try testing.expectEqual(true, is_set(b, 6));

    // 11111111 -> 11111111 (clear bit 6)
    const c = clear(0xff, 6);
    try testing.expectEqual(c, 191);

    // 1000111 (0x47)
    try testing.expectEqual(val(0x47, 3), 0);
    try testing.expectEqual(val(0x47, 6), 1);
}
