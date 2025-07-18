const std = @import("std");
const core = @import("core");

pub const AssetTarget = @import("clse/AssetTarget.zig");
pub const InTarget = @import("clse/InTarget.zig");

pub fn parse(comptime T: type, tokens: *core.parsing.Tokenizer.TokenIterator, env: core.parsing.ParsetimeEnv) !core.results.ParseResult(T) {
    const info = @typeInfo(T);
    if (info != .@"struct") @compileError("expected a struct type, got " ++ @tagName(info));

    const fields = info.@"struct".fields;
    var clause_tokens: [fields.len]?core.Token = @splat(null);
    var holder: T = std.mem.zeroInit(T, .{});

    while (true) {
        inline for (fields, 0..) |field, i| {
            const finfo = @typeInfo(field.type);
            const Clause = switch (finfo) {
                .optional => |opt| cse: {
                    if (@typeInfo(opt.child) != .@"struct") {
                        @compileError("expected field '" ++ field.name ++ "' to be of type optional struct, got optional " ++ @tagName(@typeInfo(opt.child)));
                    }
                    break :cse opt.child;
                },
                .@"struct" => field.type,
                else => @compileError("expected field '" ++ field.name ++ "' to be of type struct or optional struct, got " ++ @tagName(finfo)),
            };

            if (@TypeOf(Clause.parse) != fn (*core.parsing.Tokenizer.TokenIterator, core.parsing.ParsetimeEnv) anyerror!core.results.ParseResult(Clause)) {
                @compileError("Invalid parse function for clause " ++ @typeName(Clause));
            }

            const next_token = tokens.peek(1);
            switch (try Clause.parse(tokens, env)) {
                .ok => |value| {
                    if (@TypeOf(value) != Clause) @compileError("parse function returns " ++ @typeName(@TypeOf(value)) ++ ", expected " ++ @typeName(Clause));
                    if (clause_tokens[i] == null) {
                        @field(holder, field.name) = value;
                        clause_tokens[i] = next_token;
                        break;
                    }
                    return .ERR(.{
                        .duplicate_clause = .{
                            .clause = field.name,
                            .first = clause_tokens[i] orelse unreachable,
                            .second = next_token,
                        },
                    });
                },
                .err => |err| switch (err) {
                    .unknown => {},
                    else => return .ERR(err),
                },
            }
        } else {
            break;
        }
    }

    inline for (fields, 0..) |field, i| {
        if (clause_tokens[i] == null and field.default_value_ptr == null) {
            return .ERR(.{
                .missing_clause = .{
                    .clause = field.name,
                    .placement = tokens.next(),
                },
            });
        }
    }

    return .OK(holder);
}
