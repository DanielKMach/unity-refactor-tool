const std = @import("std");
const core = @import("core");

const log = std.log.scoped(.expr_parser);

const Location = core.Token.Location;

pub const Expr = union(enum) {
    pub const eval = @import("expr/eval.zig");
    pub const ast = @import("expr/ast.zig");

    pub const VarMap = @import("expr/VarMap.zig");
    pub const Value = @import("expr/value.zig").Value;

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

    pub const Indexing = struct {
        base: *core.Expr,
        index: *core.Expr,
        bracket: core.Token,
    };

    pub const Property = struct {
        name: core.Token,
    };

    pub const Variable = struct {
        name: core.Token,
    };

    pub const Assignment = struct {
        target: *core.Expr,
        op: core.Token,
        value: *core.Expr,
    };

    pub const Call = struct {
        callee: *core.Expr,
        args: []const *core.Expr,
        paren: core.Token,
    };

    unary: Unary,
    literal: Literal,
    binary: Binary,
    ternary: Ternary,
    grouping: Grouping,
    access: Access,
    indexing: Indexing,
    property: Property,
    variable: Variable,
    assignment: Assignment,
    call: Call,

    /// Parses an expression from the given token iterator.
    pub const parse = ast.parse;

    /// Evaluates the expression in the given environment.
    ///
    /// May leak memory if not used with an arena allocator.
    pub const evaluate = eval.evaluate;

    /// Evaluates the expression in a temporary environment, duplicating the result into the original environment's allocator.
    ///
    /// Frees any temporary allocations made during evaluation.
    pub fn evaluateAuto(self: *Expr, env: eval.Env) eval.Error!Value {
        var buf: [1024 * 1024]u8 = undefined; // 1 MiB
        var stack = std.heap.FixedBufferAllocator.init(&buf);

        const new_env = eval.Env{
            .allocator = stack.allocator(),
            .root = self,
            .diag = env.diag,
            .context = env.context,
            .assets = env.assets,
            .objs = env.objs,
            .vars = env.vars,
            .readonly = env.readonly,
        };

        const result = try eval.evaluate(self, new_env);
        return try result.val.dupe(env.allocator);
    }

    /// Creates a derived value from this expression and the given value.
    pub fn derived(self: *Expr, value: Value) Value.Derived {
        return .{
            .src = self,
            .val = value,
        };
    }

    pub fn loc(self: *Expr) Location {
        return switch (self.*) {
            .literal => |l| l.token.loc,
            .unary => |u| .merge(&.{ u.operand.loc(), u.op.loc }),
            .binary => |b| .merge(&.{ b.left.loc(), b.right.loc() }),
            .ternary => |t| .merge(&.{ t.left.loc(), t.right.loc() }),
            .grouping => |g| g.loc,
            .access => |a| .merge(&.{ a.base.loc(), a.property.loc }),
            .indexing => |i| .merge(&.{ i.base.loc(), i.index.loc(), i.bracket.loc }),
            .property => |p| p.name.loc,
            .variable => |v| v.name.loc,
            .assignment => |as| .merge(&.{ as.target.loc(), as.value.loc() }),
            .call => |c| .merge(&.{ c.callee.loc(), c.paren.loc }),
        };
    }

    pub fn dupe(self: Expr, allocator: std.mem.Allocator) std.mem.Allocator.Error!*Expr {
        switch (self) {
            .literal => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.literal.token = try duped.literal.token.dupe(allocator);
                return duped;
            },
            .unary => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.unary.op = try duped.unary.op.dupe(allocator);
                duped.unary.operand = try duped.unary.operand.dupe(allocator);
                return duped;
            },
            .binary => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.binary.op = try duped.binary.op.dupe(allocator);
                duped.binary.left = try duped.binary.left.dupe(allocator);
                duped.binary.right = try duped.binary.right.dupe(allocator);
                return duped;
            },
            .ternary => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.ternary.left = try duped.ternary.left.dupe(allocator);
                duped.ternary.middle = try duped.ternary.middle.dupe(allocator);
                duped.ternary.right = try duped.ternary.right.dupe(allocator);
                return duped;
            },
            .grouping => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.grouping.expr = try duped.grouping.expr.dupe(allocator);
                return duped;
            },
            .access => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.access.property = try duped.access.property.dupe(allocator);
                duped.access.base = try duped.access.base.dupe(allocator);
                return duped;
            },
            .indexing => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.indexing.bracket = try duped.indexing.bracket.dupe(allocator);
                duped.indexing.base = try duped.indexing.base.dupe(allocator);
                duped.indexing.index = try duped.indexing.index.dupe(allocator);
                return duped;
            },
            .property => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.property.name = try duped.property.name.dupe(allocator);
                return duped;
            },
            .variable => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.variable.name = try duped.variable.name.dupe(allocator);
                return duped;
            },
            .assignment => {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.assignment.op = try duped.assignment.op.dupe(allocator);
                duped.assignment.target = try duped.assignment.target.dupe(allocator);
                duped.assignment.value = try duped.assignment.value.dupe(allocator);
                return duped;
            },
            .call => |c| {
                const duped = try allocator.create(Expr);
                duped.* = self;
                duped.call.paren = try duped.call.paren.dupe(allocator);
                duped.call.callee = try duped.call.callee.dupe(allocator);
                const duped_args = try allocator.alloc(*Expr, c.args.len);
                for (c.args, 0..) |arg, i| {
                    duped_args[i] = try arg.dupe(allocator);
                }
                duped.call.args = duped_args;
                return duped;
            },
        }
    }

    pub fn format(self: Expr, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .literal => |l| try writer.print("{f}", .{std.fmt.alt(l.token.value, .raw)}),
            .unary => |u| try writer.print("{f}({f})", .{ std.fmt.alt(u.op.value, .raw), u.operand }),
            .binary => |b| try writer.print("{f}({f} {f})", .{ std.fmt.alt(b.op.value, .raw), b.left, b.right }),
            .ternary => |t| try writer.print("?:({f} {f} {f})", .{ t.left, t.middle, t.right }),
            .grouping => |g| try writer.print("g({f})", .{g.expr}),
            .access => |a| try writer.print("a({f} {f})", .{ a.base, std.fmt.alt(a.property.value, .raw) }),
            .indexing => |i| try writer.print("i({f} {f})", .{ i.base, i.index }),
            .property => |p| try writer.print("{f}", .{std.fmt.alt(p.name.value, .raw)}),
            .variable => |v| try writer.print("{f}", .{std.fmt.alt(v.name.value, .raw)}),
            .assignment => |as| try writer.print("{f}({f} {f})", .{ std.fmt.alt(as.op.value, .raw), as.target, as.value }),
            .call => |c| {
                try writer.print("call({f}", .{c.callee});
                for (c.args) |arg| {
                    try writer.print(" {f}", .{arg});
                }
                try writer.writeByte(',');
            },
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
            .indexing => |i| {
                i.base.cleanup(allocator);
                i.index.cleanup(allocator);
                i.bracket.cleanup(allocator);
            },
            .property => |p| p.name.cleanup(allocator),
            .variable => |v| v.name.cleanup(allocator),
            .assignment => |as| {
                as.target.cleanup(allocator);
                as.op.cleanup(allocator);
                as.value.cleanup(allocator);
            },
            .call => |c| {
                c.callee.cleanup(allocator);
                for (c.args) |arg| {
                    arg.cleanup(allocator);
                }
                allocator.free(c.args);
                c.paren.cleanup(allocator);
            },
        }
        self.* = undefined;
        allocator.destroy(self);
    }
};
