const std = @import("std");
const urt = @import("urt");

test "source from file" {
    const source = try urt.Source.fromPath(std.fs.cwd(), "data3/query.usrl", std.testing.allocator);
    defer source.deinit();

    try std.testing.expectEqualStrings("query.usrl", source.name.?);
    try std.testing.expectEqualStrings("SHOW uses OF Player", source.source);
}

test "anonymous source" {
    const source = try urt.Source.anonymous("SHOW uses OF Player", std.testing.allocator);
    defer source.deinit();

    try std.testing.expectEqual(null, source.name);
    try std.testing.expectEqualStrings("SHOW uses OF Player", source.source);
}

test "line retrieval" {
    const source = try urt.Source.fromPath(std.fs.cwd(), "data3/script.usrl", std.testing.allocator);
    defer source.deinit();

    const line = source.line(0); // SHOW stmt
    const line2 = source.line(1); // RENAME stmt
    const line3 = source.line(2); // EVAL stmt
    const line4 = source.line(3); // trailing newline
    const line5 = source.line(4); // should be null

    try std.testing.expect(line != null);
    try std.testing.expect(line2 != null);
    try std.testing.expect(line3 != null);
    try std.testing.expect(line4 != null);
    try std.testing.expectEqual(null, line5);
    try std.testing.expectEqualStrings("SHOW uses OF Player;", line.?);
    try std.testing.expectEqualStrings("RENAME _spd FOR _speed OF Player;", line2.?);
    try std.testing.expectEqualStrings("EVAL _speed OF Player", line3.?);
    try std.testing.expectEqualStrings("", line4.?); // trailing newline should be empty string
}

test "line number" {
    const source = try urt.Source.fromPath(std.fs.cwd(), "data3/script.usrl", std.testing.allocator);
    defer source.deinit();

    const line_number_start = source.lineIndex(0); // first index
    const line_number_end = source.lineIndex(21); // new line char
    const line2_number_start = source.lineIndex(22); // first index
    const line2_number_end = source.lineIndex(56); // new line char
    const line3_number_start = source.lineIndex(57); // first index
    const line3_number_end = source.lineIndex(79); // new line char
    const line4_number = source.lineIndex(80); // theoretical sentinel
    try std.testing.expectEqual(0, line_number_start);
    try std.testing.expectEqual(1, line2_number_start);
    try std.testing.expectEqual(2, line3_number_start);
    try std.testing.expectEqual(3, line4_number);
    try std.testing.expectEqual(line_number_start, line_number_end);
    try std.testing.expectEqual(line2_number_start, line2_number_end);
    try std.testing.expectEqual(line3_number_start, line3_number_end);
}
