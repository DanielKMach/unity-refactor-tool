const std = @import("std");
const tracy = @import("tracy");
pub const config = @import("config");

pub const Stmt = @import("stmt.zig").Stmt;
pub const Expr = @import("expr.zig").Expr;
pub const runtime = @import("runtime.zig");
pub const util = @import("util.zig");
pub const yaml = @import("yaml.zig");

pub const Project = @import("Project.zig");
pub const Token = @import("Token.zig");
pub const Tokenizer = @import("Tokenizer.zig");
pub const Diagnostics = @import("diag.zig").Diagnostics;
pub const Script = @import("Script.zig");
pub const Transaction = @import("Transaction.zig");

pub const version = config.version;

pub const TokenizeError = error{USRLTokenizeError};
pub const TokenizeAllocError = TokenizeError || std.mem.Allocator.Error;
pub const TokenizeDiagnostics = Diagnostics(TokenizeProblem, error.USRLTokenizeError);

pub const TokenizeProblem = union(enum) {
    const Type = @typeInfo(@This()).@"union".tag_type orelse unreachable;

    never_closed_string: struct {
        location: Token.Location,
    },
    unexpected_character: struct {
        location: Token.Location,
    },
    invalid_number: struct {
        location: Token.Location,
    },

    pub fn loc(prob: TokenizeProblem) Token.Location {
        return switch (prob) {
            .never_closed_string => |p| p.location,
            .unexpected_character => |p| p.location,
            .invalid_number => |p| p.location,
        };
    }

    pub fn format(prob: TokenizeProblem, w: *std.Io.Writer) std.Io.Writer.Error!void {
        return switch (prob) {
            .never_closed_string => w.writeAll("Never closed string"),
            .unexpected_character => w.writeAll("Unexpected character"),
            .invalid_number => w.writeAll("Invalid number"),
        };
    }
};

pub const ParseError = error{USRLParseError};
pub const ParseAllocError = ParseError || std.mem.Allocator.Error;
pub const ParseDiagnostics = Diagnostics(ParseProblem, error.USRLParseError);

pub const ParseProblem = union(enum) {
    const Type = @typeInfo(@This()).@"union".tag_type orelse unreachable;

    unexpected_token: struct {
        expected: []const Token.Type,
        found: Token,
    },
    invalid_guid: struct {
        token: Token,
    },
    invalid_csharp_identifier: struct {
        token: Token,
    },
    absolute_path: struct {
        token: Token,
    },

    // Clause related errors
    duplicate_clause: struct {
        clause: []const u8,
        first: Token,
        second: Token,
    },
    missing_clause: struct {
        clause: []const u8,
        placement: Token,
    },
    invalid_mode_for_clause: struct {
        clause: []const u8,
        mode: Stmt.Show.SearchMode,
        location: Token.Location,
    },

    // Expression related errors
    invalid_assignment_target: struct {
        location: Token.Location,
    },

    pub fn loc(prob: ParseProblem) Token.Location {
        return switch (prob) {
            .unexpected_token => |p| p.found.loc,
            .invalid_csharp_identifier => |p| p.token.loc,
            .invalid_guid => |p| p.token.loc,
            .absolute_path => |p| p.token.loc,
            .duplicate_clause => |p| p.second.loc,
            .missing_clause => |p| p.placement.loc,
            .invalid_assignment_target => |p| p.location,
            .invalid_mode_for_clause => |p| p.location,
        };
    }

    pub fn format(prob: ParseProblem, w: *std.Io.Writer) std.Io.Writer.Error!void {
        return switch (prob) {
            .unexpected_token => |p| {
                try w.print("Unexpected {f}", .{p.found.value});
                if (p.expected.len > 0) try w.writeAll(", expected ");
                for (p.expected, 0..) |e, i| {
                    try w.print("{f}", .{e});
                    if (i < p.expected.len - 2) try w.writeAll(", ");
                    if (i == p.expected.len - 2) try w.writeAll(" or ");
                }
            },
            .invalid_csharp_identifier => |p| w.print("Invalid C# identifier '{s}'", .{p.token.asSlice()}),
            .invalid_guid => |p| w.print("Invalid GUID '{s}'", .{p.token.asSlice()}),
            .absolute_path => w.writeAll("Path must be relative to project"),
            .duplicate_clause => |p| w.print("Duplicate clause '{s}'", .{p.clause}),
            .missing_clause => |p| w.print("Missing clause '{s}'", .{p.clause}),
            .invalid_assignment_target => w.writeAll("Invalid assignment target"),
            .invalid_mode_for_clause => |p| w.print("Cannot use search mode '{t}' with clause '{s}'", .{ p.mode, p.clause }),
        };
    }
};

pub const RuntimeError = error{USRLRuntimeError};
pub const RuntimeDiagnostics = Diagnostics(RuntimeProblem, error.USRLRuntimeError);

pub const RuntimeProblem = union(enum) {
    const Type = @typeInfo(RuntimeProblem).@"union".tag_type orelse unreachable;

    invalid_asset: struct {
        path: Token.Location,
    },
    invalid_path: struct {
        path: Token.Location,
    },
    unexpected_type: struct {
        found: Expr.Value.Type,
        expected: []const Expr.Value.Type,
        location: Token.Location,
    },
    type_mismatch: struct {
        left: Expr.Value.Type,
        left_loc: Token.Location,
        right: Expr.Value.Type,
        right_loc: Token.Location,
    },
    division_by_zero: struct {
        location: Token.Location,
    },
    invalid_argument_count: struct {
        mode: enum { exact, at_least, at_most },
        expected: usize,
        found: usize,
        location: Token.Location,
    },
    invalid_argument: struct {
        reason: []const u8,
        location: Token.Location,
    },
    undefined_variable: struct {
        varr: Token,
        location: Token.Location,
    },
    already_defined_variable: struct {
        varr: Token,
        location: Token.Location,
    },
    overriding_readonly: struct {
        varr: Token,
        location: Token.Location,
    },
    out_of_bounds: struct {
        index: isize,
        len: usize,
        location: Token.Location,
    },
    invalid_index: struct {
        index: f32,
        location: Token.Location,
    },
    invalid_asset_reference: struct {
        guid: runtime.GUID,
        location: Token.Location,
    },
    asset_not_found: struct {
        guid: runtime.GUID,
        location: Token.Location,
    },
    object_definition_not_found: struct {
        guid: runtime.GUID,
        file_id: u64,
        location: Token.Location,
    },
    null_object_definition_reference: struct {
        location: Token.Location,
    },
    search_failed: struct {
        guid: runtime.GUID,
    },
    unassignable_value: struct {
        value_type: Expr.Value.Type,
        assigned_to: enum { variable, property, array },
        location: Token.Location,
    },
    undefinable_target: struct {
        target: enum { property, entry },
        location: Token.Location,
    },
    update_during_readonly_eval: struct {
        location: Token.Location,
    },
    invalid_target_asset: struct {
        filter: Stmt.clse.Of.Filter,
        location: Token.Location,
    },

    pub fn loc(prob: RuntimeProblem) ?Token.Location {
        return switch (prob) {
            .invalid_asset => |p| p.path,
            .invalid_path => |p| p.path,
            .division_by_zero => |p| p.location,
            .type_mismatch => |p| Token.Location.merge(&.{ p.left_loc, p.right_loc }),
            .unexpected_type => |p| p.location,
            .invalid_argument_count => |p| p.location,
            .invalid_argument => |p| p.location,
            .undefined_variable => |p| p.location,
            .already_defined_variable => |p| p.location,
            .overriding_readonly => |p| p.location,
            .invalid_index => |p| p.location,
            .out_of_bounds => |p| p.location,
            .invalid_asset_reference => |p| p.location,
            .asset_not_found => |p| p.location,
            .object_definition_not_found => |p| p.location,
            .null_object_definition_reference => |p| p.location,
            .unassignable_value => |p| p.location,
            .undefinable_target => |p| p.location,
            .update_during_readonly_eval => |p| p.location,
            .invalid_target_asset => |p| p.location,
            .search_failed => null,
        };
    }

    pub fn format(prob: RuntimeProblem, w: *std.Io.Writer) std.Io.Writer.Error!void {
        return switch (prob) {
            .invalid_asset => w.writeAll("Invalid asset path"),
            .invalid_path => w.writeAll("Invalid path"),
            .division_by_zero => w.writeAll("Division by zero"),
            .type_mismatch => |p| w.print("Found {t} as lhs and {t} as rhs", .{ p.left, p.right }),
            .unexpected_type => |p| {
                try w.print("Unexpected type {t}", .{p.found});
                if (p.expected.len > 0) try w.writeAll(", expected ");
                for (p.expected, 0..) |e, i| {
                    try w.print("{t}", .{e});
                    if (i < p.expected.len - 2) try w.writeAll(", ");
                    if (i == p.expected.len - 2) try w.writeAll(" or ");
                }
            },
            .invalid_argument_count => |p| {
                const mode = switch (p.mode) {
                    .exact => "exactly",
                    .at_least => "at least",
                    .at_most => "at most",
                };
                try w.print("Invalid argument count: expected {s} {d}, found {d}", .{ mode, p.expected, p.found });
            },
            .invalid_argument => |p| w.print("Invalid argument: {s}", .{p.reason}),
            .undefined_variable => |p| w.print("Undefined {f}. Use '{f} := (...)' to define it", .{
                p.varr.value,
                std.fmt.alt(p.varr.value, .raw),
            }),
            .already_defined_variable => |p| w.print("{f} is already defined. Use '{f} = (...)' to update its value", .{
                p.varr.value,
                std.fmt.alt(p.varr.value, .raw),
            }),
            .overriding_readonly => |p| w.print("Cannot override read-only {f}", .{p.varr.value}),
            .invalid_index => |p| w.print("Invalid index {d}", .{p.index}),
            .out_of_bounds => |p| w.print("Index {d} is out of bounds (length: {d})", .{ p.index, p.len }),
            .invalid_asset_reference => |p| w.print("Invalid asset with GUID '{f}'. This could be because the asset could not be opened properly or it wasn't properly configured", .{p.guid}),
            .asset_not_found => |p| w.print("Asset with GUID '{f}' was not found", .{p.guid}),
            .object_definition_not_found => |p| w.print("Object definition with file ID {d} was not found in asset with GUID '{f}'", .{ p.file_id, p.guid }),
            .null_object_definition_reference => w.writeAll("Object definition is null"),
            .unassignable_value => |p| w.print("Value of type {t} cannot be assigned to {t}", .{ p.value_type, p.assigned_to }),
            .undefinable_target => |p| w.print("Cannot define {t}. The ':=' operator can only be used with variables", .{p.target}),
            .search_failed => |p| w.print("Search for object with GUID '{f}' failed", .{p.guid}),
            .update_during_readonly_eval => w.writeAll("Cannot perform update during read-only evaluation"),
            .invalid_target_asset => |err| {
                const filter = switch (err.filter) {
                    .any => "any asset",
                    .prefabs_and_components => "prefab or component",
                    .components_only => "component",
                };
                try w.print("Invalid target asset. Expected {s} type", .{filter});
            },
        };
    }
};

/// Tokenizes the given expression into a slice of tokens.
///
/// The slice is owned by the caller.
pub fn tokenize(
    expression: []const u8,
    allocator: std.mem.Allocator,
    diag: *TokenizeDiagnostics,
) TokenizeAllocError![]Token {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var list = try std.ArrayList(Token).initCapacity(allocator, 16);
    defer list.deinit(allocator);
    errdefer Token.cleanup(allocator, list.items);

    var tokenizer = Tokenizer.init(expression);
    while (try tokenizer.token(allocator, diag)) |tkn| {
        errdefer Token.cleanup(allocator, &.{tkn});

        try list.append(allocator, tkn);
    }

    return try list.toOwnedSlice(allocator);
}

pub fn parse(
    tokens: []const Token,
    allocator: std.mem.Allocator,
    diag: *ParseDiagnostics,
) ParseAllocError!Script {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var iterator = Token.Iterator.init(tokens);

    var statements = std.ArrayList(Stmt).empty;
    defer statements.deinit(allocator);
    errdefer for (statements.items) |stmt| stmt.deinit(allocator);

    const env: Stmt.ParseEnv = .{
        .diag = diag,
        .allocator = allocator,
    };

    while (!iterator.match(.eof) and iterator.remaining() > 0) {
        const stmt = try Stmt.parse(&iterator, env);
        try statements.append(env.allocator, stmt);
        const end = try iterator.grabAny(&.{ .semicolon, .eof }, env.diag);
        if (end.is(.eof)) break;
    }

    return .{ .statements = try statements.toOwnedSlice(allocator) };
}

pub fn check(
    tokens: []const Token,
    allocator: std.mem.Allocator,
    diag: *ParseDiagnostics,
) ParseAllocError!void {
    const script = try parse(tokens, allocator, diag);
    script.deinit(allocator);
}

pub fn parseManaged(
    tokens: []const Token,
    allocator: std.mem.Allocator,
    diag: *ParseDiagnostics,
) ParseAllocError!Script.Managed {
    try check(tokens, allocator, diag);

    const tkns = try allocator.alloc(Token, tokens.len);
    errdefer allocator.free(tkns);
    try Token.dupe(allocator, tkns, tokens);
    errdefer Token.cleanup(allocator, tkns);

    const script = parse(tkns, allocator, diag) catch |err| switch (err) {
        error.USRLParseError => unreachable,
        error.OutOfMemory => |e| return e,
    };
    errdefer script.deinit(allocator);

    return .{
        .allocator = allocator,
        .script = script,
        .tokens = tkns,
    };
}

pub fn run(
    script: Script,
    allocator: std.mem.Allocator,
    diag: *RuntimeDiagnostics,
    proj: Project,
    out: *std.Io.Writer,
) anyerror!void {
    const zone = tracy.Zone(@src());
    defer zone.End();

    var transaction = Transaction.init(allocator);
    defer transaction.deinit();

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{ .allocator = allocator, .n_jobs = config.scan_thread_count });
    defer pool.deinit();

    const env = Stmt.RunEnv{
        .transaction = &transaction,
        .allocator = allocator,
        .pool = &pool,
        .diag = diag,
        .proj = proj,
        .out = out,
    };

    script.run(env) catch |err| {
        transaction.rollback();
        return err;
    };

    transaction.commit();
}

test tokenize {
    const query = "SHOW uses OF Test";

    const tkns = try tokenize(query, std.testing.allocator, .none);
    defer Token.free(std.testing.allocator, tkns);

    try std.testing.expectEqual(5, tkns.len);
    try std.testing.expectEqual(Token.new(.SHOW, .init(0, 4)), tkns[0]);
    try std.testing.expectEqual(Token.new(.USES, .init(5, 4)), tkns[1]);
    try std.testing.expectEqual(Token.new(.OF, .init(10, 2)), tkns[2]);
    try std.testing.expectEqual(.literal, @as(Token.Type, tkns[3].value));
    try std.testing.expectEqualStrings("Test", tkns[3].value.literal);
    try std.testing.expectEqual(Token.Location.init(13, 4), tkns[3].loc);
    try std.testing.expectEqual(Token.new(.eof, .init(17, 0)), tkns[4]);

    try std.testing.expectError(error.OutOfMemory, tokenize(query, std.testing.failing_allocator, .none));
}

test parse {
    const tkns: []const Token = &.{
        .new(.SHOW, .init(0, 4)),
        .new(.USES, .init(5, 4)),
        .new(.OF, .init(10, 2)),
        .new(.{ .literal = "Test" }, .init(13, 4)),
        .new(.eof, .init(17, 0)),
    };

    const s0 = try parse(tkns, std.testing.allocator, .none);
    s0.deinit(std.testing.allocator);

    const s1 = try parse(Token.empty, std.testing.allocator, .none);
    s1.deinit(std.testing.allocator);

    try std.testing.expectError(error.OutOfMemory, parse(tkns, std.testing.failing_allocator, .none));
}

test check {
    const tkns: []const Token = &.{
        .new(.SHOW, .init(0, 4)),
        .new(.USES, .init(5, 4)),
        .new(.OF, .init(10, 2)),
        .new(.{ .literal = "Test" }, .init(13, 4)),
        .new(.eof, .init(17, 0)),
    };

    try check(tkns, std.testing.allocator, .none);
    try check(Token.empty, std.testing.allocator, .none);

    try std.testing.expectError(error.OutOfMemory, check(tkns, std.testing.failing_allocator, .none));
}
