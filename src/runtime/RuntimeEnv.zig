const std = @import("std");

allocator: std.mem.Allocator,
transaction: *@import("Transaction.zig"),
out: std.io.AnyWriter,
cwd: std.fs.Dir,
