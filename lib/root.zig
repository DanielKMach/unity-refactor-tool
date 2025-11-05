const std = @import("std");

pub const Stmt = @import("stmt.zig").Stmt;
pub const Expr = @import("expr.zig").Expr;
pub const runtime = @import("runtime.zig");
pub const profiling = @import("profiling.zig");
pub const util = @import("util.zig");
pub const yaml = @import("yaml.zig");

pub const Source = @import("Source.zig");
pub const Token = @import("Token.zig");
pub const Tokenizer = @import("Tokenizer.zig");
pub const Diagnostics = @import("diag.zig").Diagnostics;
pub const Script = @import("Script.zig");
pub const Transaction = @import("Transaction.zig");
pub const Parser = @import("Parser.zig");
pub const Result = @import("results.zig").Result;

pub const ParseProblem = union(enum) {
    const Type = @typeInfo(@This()).@"union".tag_type orelse unreachable;

    // Syntax related errors
    never_closed_string: struct {
        location: Token.Location,
    },
    unexpected_character: struct {
        location: Token.Location,
    },
    invalid_number: struct {
        location: Token.Location,
    },

    // Token related errors
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

    // Expression related errors
    invalid_assignment_target: struct {
        location: Token.Location,
    },

    // Generic errors
    unexpected: anyerror,
};

pub const ParseError = error{USRLParseError};
pub const ParseAllocError = ParseError || std.mem.Allocator.Error;
pub const ParseDiagnostics = Diagnostics(ParseProblem, error.USRLParseError);

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

    unexpected: anyerror,
};

pub const RuntimeError = error{USRLRuntimeError};
pub const RuntimeDiagnostics = Diagnostics(RuntimeProblem, error.USRLRuntimeError);
