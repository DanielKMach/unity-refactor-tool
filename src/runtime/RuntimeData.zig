const std = @import("std");

allocator: std.mem.Allocator,
out: std.io.AnyWriter,
cwd: std.fs.Dir,
query: [:0]const u8,
verbose: bool = false,
