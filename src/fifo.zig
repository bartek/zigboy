const std = @import("std");
const testing = std.testing;

// A simple first-in, first-out queue.
pub fn Fifo(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();

        items: [capacity]T = undefined,

        // out is the current index of the tail (output) of the FIFO
        out: usize,

        // in is the current index of the head (input) of the FIFO
        in: usize,

        // len is the number of items in the FIFO
        len: usize,

        pub fn init(len: usize) error{Overflow}!Self {
            if (len > capacity) return error.Overflow;
            return Self{ .len = len, .out = 0, .in = 0 };
        }

        // Push an item onto the FIFO.
        pub fn push(self: *Self, item: T) error{Overflow}!void {
            if (self.len == self.items.len) {
                return error.Overflow;
            }
            self.items[self.in] = item;
            self.in = (self.in + 1) % capacity;
            self.len += 1;
        }

        // Returns the number of items currently in the FIFO
        pub fn length(self: Self) usize {
            return self.len;
        }

        // Remove and return the first element from the FIFO
        pub fn pop(self: *Self) error{Underflow}!T {
            if (self.len == 0) {
                return error.Underflow;
            }
            const item = self.items[self.out];
            self.out = (self.out + 1) % capacity;
            self.len -= 1;
            return item;
        }

        // Remove all entries from the FIFO
        pub fn clear(self: *Self) void {
            self.in = 0;
            self.out = 0;
            self.len = 0;
        }
    };
}

test "Fifo" {
    var f = try Fifo(u8, 12).init(6);

    try testing.expectEqual(f.len, 6);
    try testing.expectEqual(f.out, 0);
    try testing.expectEqual(f.in, 0);

    try f.push(1);
    try f.push(2);
    try f.push(3);

    try testing.expectEqual(f.pop(), 1);
    try testing.expectEqual(f.pop(), 2);

    var fs = try Fifo(*const [5:0]u8, 12).init(6);

    try fs.push("hello");
    try fs.push("world");

    try testing.expectEqual(fs.pop(), "hello");
}

test "FIFO Capacity" {
    var f = try Fifo(u8, 2).init(1);
    try f.push(1);
    try testing.expectError(error.Overflow, f.push(2));
}

test "FIFO length" {
    var f = try Fifo(u8, 6).init(0);
    try testing.expectEqual(f.len, 0);
    try f.push(1);
    try testing.expectEqual(f.len, 1);
    try testing.expectEqual(f.pop(), 1);
    try testing.expectEqual(f.len, 0);
}

test "FIFO Underflow" {
    var f = try Fifo(u8, 6).init(0);
    try testing.expectError(error.Underflow, f.pop());
}
