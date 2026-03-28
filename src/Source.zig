const std = @import("std");
const core = @import("core");

const Source = @This();

source: []const u8,
name: ?[]const u8,

pub fn dupe(allocator: std.mem.Allocator, source: []const u8, name: ?[]const u8) std.mem.Allocator.Error!Source {
    return .{
        .source = try allocator.dupe(u8, source),
        .name = if (name) |nm| try allocator.dupe(u8, nm) else null,
    };
}

pub fn line(self: Source, line_index: usize) ?[]const u8 {
    const start: usize = self.lineStart(line_index) orelse return null;
    const end = std.mem.indexOfScalarPos(u8, self.source, start, '\n') orelse self.source.len;
    return std.mem.trim(u8, self.source[start..end], "\r\n");
}

pub fn lineIndex(self: Source, index: usize) ?usize {
    if (index > self.source.len) return null;
    const line_index = std.mem.count(u8, self.source[0..@min(index, self.source.len)], "\n");
    return line_index;
}

pub fn lineStart(self: Source, line_index: usize) ?usize {
    var start: usize = 0;
    for (0..line_index) |_| {
        start = std.mem.indexOfScalarPos(u8, self.source, start, '\n') orelse {
            if (start == self.source.len) return null;
            start = self.source.len;
            continue;
        };
        start += 1; // move past the newline character
    }
    return start;
}

pub fn deinit(self: Source, allocator: std.mem.Allocator) void {
    if (self.name) |nm| allocator.free(nm);
    allocator.free(self.source);
}
