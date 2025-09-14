const std = @import("std");
const core = @import("core");

pub const Of = @import("clse/Of.zig");
pub const In = @import("clse/In.zig");

fn ParseFn(comptime T: type) type {
    return fn (*core.Token.Iterator, core.Stmt.ParseEnv) core.Stmt.ParseError!T;
}

pub fn parse(comptime T: type, tokens: *core.Token.Iterator, env: core.Stmt.ParseEnv) core.ParseAllocError!T {
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

            if (!core.util.hasFn(Clause, "parse", ParseFn(Clause))) {
                @compileError("Invalid parse function for clause " ++ @typeName(Clause));
            }

            const next_token = tokens.peek(1);
            if (Clause.parse(tokens, env)) |value| {
                comptime std.debug.assert(@TypeOf(value) == Clause);
                if (clause_tokens[i] == null) {
                    @field(holder, field.name) = value;
                    clause_tokens[i] = next_token;
                    break;
                }
                return env.err(.{ .duplicate_clause = .{
                    .clause = field.name,
                    .first = clause_tokens[i] orelse unreachable,
                    .second = next_token,
                } });
            } else |err| switch (err) {
                error.TokenMismatch => {},
                else => |e| return e,
            }
        } else {
            break;
        }
    }

    inline for (fields, 0..) |field, i| {
        if (clause_tokens[i] == null and field.default_value_ptr == null) {
            return env.err(.{ .missing_clause = .{
                .clause = field.name,
                .placement = tokens.next(),
            } });
        }
    }

    return holder;
}
