const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_parser);

const Location = core.Token.Location;

pub const Expr = union(enum) {
    pub const eval = @import("expr/eval.zig");
    pub const ast = @import("expr/ast.zig");

    pub const VarMap = @import("expr/VarMap.zig");
    pub const Value = @import("expr/value.zig").Value;

    pub const EvalEnv = struct {
        allocator: std.mem.Allocator,
        diag: *core.RuntimeDiagnostics,
        context: Value.Object,
        vars: *VarMap,

        pub fn err(self: EvalEnv, p: core.RuntimeProblem) core.RuntimeDiagnostics.Error {
            return self.diag.push(p);
        }
    };

    pub const ParseEnv = struct {
        allocator: std.mem.Allocator,
        diag: *core.ParseDiagnostics,

        pub fn err(self: ParseEnv, p: core.ParseProblem) core.ParseDiagnostics.Error {
            return self.diag.push(p);
        }
    };

    pub const Type = @typeInfo(Expr).@"union".tag_type orelse unreachable;

    pub const Literal = struct {
        token: core.Token,
    };

    pub const Unary = struct {
        op: core.Token,
        operand: *core.Expr,
    };

    pub const Binary = struct {
        left: *core.Expr,
        op: core.Token,
        right: *core.Expr,
    };

    pub const Ternary = struct {
        left: *core.Expr,
        middle: *core.Expr,
        right: *core.Expr,
    };

    pub const Grouping = struct {
        loc: Location,
        expr: *core.Expr,
    };

    pub const Access = struct {
        base: *core.Expr,
        property: core.Token,
    };

    pub const Variable = struct {
        name: core.Token,
    };

    pub const Assignment = struct {
        target: *core.Expr,
        value: *core.Expr,
    };

    unary: Unary,
    literal: Literal,
    binary: Binary,
    ternary: Ternary,
    grouping: Grouping,
    access: Access,
    variable: Variable,
    assignment: Assignment,

    /// Parses an expression from the given token iterator.
    pub const parse = ast.parse;

    /// Evaluates the expression in the given environment.
    ///
    /// May leak memory if not used with an arena allocator.
    pub const evaluate = eval.evaluate;

    /// Evaluates the expression in a temporary environment, duplicating the result into the original environment's allocator.
    ///
    /// Frees any temporary allocations made during evaluation.
    pub fn evaluateAuto(self: *Expr, env: EvalEnv) anyerror!Value {
        var buf: [1024 * 1024]u8 = undefined; // 1 MiB
        var stack = std.heap.FixedBufferAllocator.init(&buf);

        const new_env = EvalEnv{
            .allocator = stack.allocator(),
            .diag = env.diag,
            .context = env.context,
            .vars = env.vars,
        };

        return try eval.evaluate(self, new_env);
    }

    pub fn loc(self: *Expr) Location {
        return switch (self.*) {
            .literal => |l| l.token.loc,
            .unary => |u| .merge(&.{ u.operand.loc(), u.op.loc }),
            .binary => |b| .merge(&.{ b.left.loc(), b.right.loc() }),
            .ternary => |t| .merge(&.{ t.left.loc(), t.right.loc() }),
            .grouping => |g| g.loc,
            .access => |a| .merge(&.{ a.base.loc(), a.property.loc }),
            .variable => |v| v.name.loc,
            .assignment => |as| .merge(&.{ as.target.loc(), as.value.loc() }),
        };
    }

    pub fn format(self: Expr, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .literal => |l| try writer.print("{f}", .{std.fmt.alt(l.token.value, .raw)}),
            .unary => |u| try writer.print("({f} {f})", .{ std.fmt.alt(u.op.value, .raw), u.operand }),
            .binary => |b| try writer.print("({f} {f} {f})", .{ std.fmt.alt(b.op.value, .raw), b.left, b.right }),
            .ternary => |t| try writer.print("(?: {f} {f} {f})", .{ t.left, t.middle, t.right }),
            .grouping => |g| try writer.print("(group {f})", .{g.expr}),
            .access => |a| try writer.print("(. {f} {f})", .{ a.base, std.fmt.alt(a.property.value, .raw) }),
            .variable => |v| try writer.print("{f}", .{std.fmt.alt(v.name.value, .raw)}),
            .assignment => |as| try writer.print("(= {f} {f})", .{ as.target, as.value }),
        }
    }

    /// Recursively frees any allocations made when parsing the expression.
    pub fn cleanup(self: *Expr, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .literal => |l| {
                l.token.cleanup(allocator);
            },
            .unary => |u| {
                u.operand.cleanup(allocator);
                u.op.cleanup(allocator);
            },
            .binary => |b| {
                b.left.cleanup(allocator);
                b.right.cleanup(allocator);
                b.op.cleanup(allocator);
            },
            .ternary => |t| {
                t.left.cleanup(allocator);
                t.middle.cleanup(allocator);
                t.right.cleanup(allocator);
            },
            .grouping => |g| g.expr.cleanup(allocator),
            .access => |a| {
                a.base.cleanup(allocator);
                a.property.cleanup(allocator);
            },
            .variable => |v| {
                v.name.cleanup(allocator);
            },
            .assignment => |as| {
                as.target.cleanup(allocator);
                as.value.cleanup(allocator);
            },
        }
        self.* = undefined;
        allocator.destroy(self);
    }
};
