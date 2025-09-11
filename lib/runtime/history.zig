const std = @import("std");

pub fn History(T: type, size: usize) type {
    if (size == 0) {
        @compileError("History size must be greater than 0");
    }

    return struct {
        const This = @This();

        data: [size]T,
        index: usize,
        len: usize,

        pub const empty = This{
            .data = undefined,
            .index = 0,
            .len = 0,
        };

        pub fn push(self: *This, value: T) void {
            self.data[self.index] = value;
            self.index = (self.index + 1) % size;
            if (self.len < size) {
                self.len += 1;
            }
        }

        pub fn last(self: This, offset: usize) ?T {
            if (offset + 1 > self.len) {
                return null;
            }
            const i = round(@as(isize, @intCast(self.index)) - @as(isize, @intCast(offset)) - 1);
            return self.data[i];
        }

        fn round(index: isize) usize {
            return @intCast(std.math.mod(isize, index, @intCast(size)) catch unreachable);
        }
    };
}

test "null check" {
    const testing = std.testing;

    var hist = History(u8, 5).empty;
    hist.push('a');
    hist.push('b');

    try testing.expectEqual('b', hist.last(0));
    try testing.expectEqual('a', hist.last(1));
    try testing.expectEqual(null, hist.last(2));
    try testing.expectEqual(null, hist.last(3));
    try testing.expectEqual(null, hist.last(4));
    try testing.expectEqual(null, hist.last(5));
    try testing.expectEqual(null, hist.last(6));

    hist.push('c');
    hist.push('d');
    hist.push('e');

    try testing.expectEqual('e', hist.last(0));
    try testing.expectEqual('d', hist.last(1));
    try testing.expectEqual('c', hist.last(2));
    try testing.expectEqual('b', hist.last(3));
    try testing.expectEqual('a', hist.last(4));
    try testing.expectEqual(null, hist.last(5));
    try testing.expectEqual(null, hist.last(6));
}

test "null check 2" {
    const testing = std.testing;

    var hist = History(u8, 3).empty;
    hist.push('a');
    hist.push('b');
    hist.push('c');
    hist.push('d');
    hist.push('e');

    try testing.expectEqual('e', hist.last(0));
    try testing.expectEqual('d', hist.last(1));
    try testing.expectEqual('c', hist.last(2));
    try testing.expectEqual(null, hist.last(3));
    try testing.expectEqual(null, hist.last(4));
    try testing.expectEqual(null, hist.last(5));
}

test "null check 3" {
    const testing = std.testing;

    var hist = History(u8, 3).empty;

    try testing.expectEqual(null, hist.last(0));
    try testing.expectEqual(null, hist.last(1));
    try testing.expectEqual(null, hist.last(2));
    try testing.expectEqual(null, hist.last(3));
}
