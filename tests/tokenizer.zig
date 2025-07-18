const std = @import("std");
const testing = std.testing;
const urt = @import("urt");

const Token = urt.language.Token;
const Tokenizer = urt.language.Tokenizer;
const ParseResult = urt.results.ParseResult;
const ParseError = urt.results.ParseError;

fn expectEqualTokenValues(expected: Token.Value, actual: Token.Value) !void {
    try testing.expectEqual(@as(Token.Type, expected), @as(Token.Type, actual));
    switch (expected) {
        .string => |str| try testing.expectEqualStrings(str, actual.string),
        .literal => |lit| try testing.expectEqualStrings(lit, actual.literal),
        .number => |num| try testing.expectEqual(num, actual.number),
        else => {},
    }
}

fn expectEqualTokenizerValues(
    expected: []const Token.Value,
    tokenizer: *Tokenizer,
) !void {
    for (expected) |exp| {
        const result = tokenizer.token();
        switch (result) {
            .ok => |t| try expectEqualTokenValues(exp, (t orelse break).value),
            .err => |err| {
                std.debug.print("expected token type '{s}', found {}\n", .{ @tagName(exp), err });
                return error.TestExpectedEqual;
            },
        }
    }
}

test "expression" {
    var tokenizer = Tokenizer.init("a + 'number' * 1.2 - 1 / 0.5");
    try expectEqualTokenizerValues(&.{
        .{ .literal = "a" },
        .plus,
        .{ .string = "number" },
        .star,
        .{ .number = 1.2 },
        .minus,
        .{ .number = 1 },
        .slash,
        .{ .number = 0.5 },
    }, &tokenizer);
}

test "tight expression" {
    var tokenizer = Tokenizer.init("a+'number'*1.2-1/0.5");
    try expectEqualTokenizerValues(&.{
        .{ .literal = "a" },
        .plus,
        .{ .string = "number" },
        .star,
        .{ .number = 1.2 },
        .minus,
        .{ .number = 1 },
        .slash,
        .{ .number = 0.5 },
    }, &tokenizer);
}

test "string literals" {
    var tokenizer = Tokenizer.init("'hello world' \"hello world\"");

    try expectEqualTokenizerValues(&.{
        .{ .string = "hello world" },
        .{ .string = "hello world" },
    }, &tokenizer);
}

test "tight string literals" {
    var tokenizer = Tokenizer.init("'hello world'\"hello world\"");

    try expectEqualTokenizerValues(&.{
        .{ .string = "hello world" },
        .{ .string = "hello world" },
    }, &tokenizer);
}

test "show statement" {
    var tokenizer = Tokenizer.init("SHOW uses OF PlayerScript IN './Assets'");
    try expectEqualTokenizerValues(&.{
        .SHOW,
        .USES,
        .OF,
        .{ .literal = "PlayerScript" },
        .IN,
        .{ .string = "./Assets" },
    }, &tokenizer);
}

test "rename statement" {
    var tokenizer = Tokenizer.init("RENAME _spd FOR _speed OF PlayerScript IN './Assets'");
    try expectEqualTokenizerValues(&.{
        .RENAME,
        .{ .literal = "_spd" },
        .FOR,
        .{ .literal = "_speed" },
        .OF,
        .{ .literal = "PlayerScript" },
        .IN,
        .{ .string = "./Assets" },
    }, &tokenizer);
}

test "eval statement" {
    var tokenizer = Tokenizer.init("EVAL _stats._speed * 3.6 OF PlayerScript IN './Assets'");
    try expectEqualTokenizerValues(&.{
        .EVAL,
        .{ .literal = "_stats" },
        .dot,
        .{ .literal = "_speed" },
        .star,
        .{ .number = 3.6 },
        .OF,
        .{ .literal = "PlayerScript" },
        .IN,
        .{ .string = "./Assets" },
    }, &tokenizer);
}

test "never closed string" {
    const source = "EVAL _speed + 'asdsdasd OF PlayerScript";
    var tokenizer = Tokenizer.init(source);
    try expectEqualTokenizerValues(&.{
        .EVAL,
        .{ .literal = "_speed" },
        .plus,
    }, &tokenizer);

    const parse_result = tokenizer.token();
    try testing.expectEqual(ParseError{
        .never_closed_string = .{
            .location = .init(14, 1),
        },
    }, parse_result.isErr());
}

test "invalid character" {
    const source = "EVAL _speed * §test OF PlayerScript";
    var tokenizer = Tokenizer.init(source);
    try expectEqualTokenizerValues(&.{
        .EVAL,
        .{ .literal = "_speed" },
        .star,
    }, &tokenizer);

    const result = tokenizer.token();
    try testing.expectEqual(ParseError{
        .unexpected_character = .{
            .location = .init(14, 1),
        },
    }, result.isErr());
}

test "comment" {
    const source = "# this is a comment";
    var tokenizer = Tokenizer.init(source);
    try testing.expectEqual(ParseResult(?Token).OK(null), tokenizer.token());
}

test "comment trailing newline" {
    const source = "# this is a comment\n";
    var tokenizer = Tokenizer.init(source);
    try testing.expectEqual(ParseResult(?Token).OK(null), tokenizer.token());
}

test "comments" {
    const source = "# this is a comment\nSHOW uses OF Player # this is an inline comment\n# this is a comment\n";
    var tokenizer = Tokenizer.init(source);
    try expectEqualTokenizerValues(&.{
        .SHOW,
        .USES,
        .OF,
        .{ .literal = "Player" },
    }, &tokenizer);
}

test "comments with carriage return" {
    const source = "# this is a comment\r\nSHOW uses OF Player # this is an inline comment\r\n# this is a comment\r\n";
    var tokenizer = Tokenizer.init(source);
    try expectEqualTokenizerValues(&.{
        .SHOW,
        .USES,
        .OF,
        .{ .literal = "Player" },
    }, &tokenizer);
}

test "comments between statement" {
    const source = "SHOW uses # this is a comment\nOF Player # this is another comment\nIN Assets # this is yet another comment\n";
    var tokenizer = Tokenizer.init(source);
    try expectEqualTokenizerValues(&.{
        .SHOW,
        .USES,
        .OF,
        .{ .literal = "Player" },
        .IN,
        .{ .literal = "Assets" },
    }, &tokenizer);
}
