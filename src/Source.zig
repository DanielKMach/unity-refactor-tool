const std = @import("std");
const core = @import("core");

const Source = @This();

pub const SourceError = std.mem.Allocator.Error;
pub const FromFileError = SourceError || std.fs.File.ReadError || error{FileTooBig};
pub const FromPathError = FromFileError || std.fs.File.OpenError;

allocator: std.mem.Allocator,
source: []const u8,
name: ?[]const u8,

pub fn fromPath(dir: std.fs.Dir, path: []const u8, allocator: std.mem.Allocator) FromPathError!Source {
    const file_source = try dir.openFile(path, .{});
    defer file_source.close();

    return Source{
        .allocator = allocator,
        .name = try allocator.dupe(u8, std.fs.path.basename(path)),
        .source = try file_source.readToEndAlloc(allocator, std.math.maxInt(usize)),
    };
}

pub fn fromPathAbsolute(path: []const u8, allocator: std.mem.Allocator) FromPathError!Source {
    const file_source = try std.fs.openFileAbsolute(path, .{});
    defer file_source.close();

    return Source{
        .allocator = allocator,
        .name = try allocator.dupe(u8, std.fs.path.basename(path)),
        .source = try file_source.readToEndAlloc(allocator, std.math.maxInt(usize)),
    };
}

pub fn fromStdin(allocator: std.mem.Allocator) FromFileError!Source {
    return Source{
        .allocator = allocator,
        .name = try allocator.dupe(u8, "stdin"),
        .source = try std.io.getStdIn().readToEndAlloc(allocator, std.math.maxInt(usize)),
    };
}

pub fn anonymous(source: []const u8, allocator: std.mem.Allocator) SourceError!Source {
    return Source{
        .allocator = allocator,
        .name = null,
        .source = try allocator.dupe(u8, source),
    };
}

pub fn deinit(self: Source) void {
    self.allocator.free(self.source);
    if (self.name) |name| self.allocator.free(name);
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
