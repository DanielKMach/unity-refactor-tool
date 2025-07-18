const std = @import("std");
const core = @import("core");

const Source = @This();

allocator: std.mem.Allocator,
source: []const u8,
name: []const u8,

pub fn fromAbsPath(path: []const u8, allocator: std.mem.Allocator) !Source {
    const file_source = try std.fs.openFileAbsolute(path, .{});
    defer file_source.close();

    return Source{
        .allocator = allocator,
        .name = try allocator.dupe(u8, std.fs.path.basename(path)),
        .source = try file_source.readToEndAlloc(allocator, std.math.maxInt(usize)),
    };
}

pub fn fromStdin(allocator: std.mem.Allocator) !Source {
    return Source{
        .allocator = allocator,
        .name = try allocator.dupe(u8, "stdin"),
        .source = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize)),
    };
}

pub fn anonymous(source: []const u8, allocator: std.mem.Allocator) !Source {
    return Source{
        .allocator = allocator,
        .name = try allocator.dupe(u8, "anonymous"),
        .source = try allocator.dupe(u8, source),
    };
}

pub fn deinit(self: Source) void {
    self.allocator.free(self.source);
    self.allocator.free(self.name);
}

pub fn line(self: Source, line_index: usize) ?[]const u8 {
    var i: usize = 0;
    for (0..line_index) |_| {
        while (i < self.source.len) {
            if (self.source[i] == '\n') break;
            i += 1;
        } else {
            return null;
        }
    }
    var j = i + 1;
    while (j < self.source.len and self.source[j] != '\n') {
        j += 1;
    }
    return std.mem.trim(u8, self.source[i..j], "\r\n");
}

pub fn lineNumber(self: Source, index: usize) ?usize {
    if (index >= self.source.len) return null;
    const line_index = std.mem.count(u8, self.source[0..index], "\n");
    return line_index + 1;
}
