const builtin = @import("builtin");
const std = @import("std");
const usrl = @import("usrl");

const Source = @import("Source.zig");
const This = @This();

const log = std.log.scoped(.cli);

const e = "R";
const eh = "r";

pub const ExecutionMode = enum {
    args,
    file,
    stdin,
};

allocator: std.mem.Allocator,
cwd: std.fs.Dir,
in: *std.fs.File.Reader,
out: *std.fs.File.Writer,
err: *std.fs.File.Writer,

pub fn process(self: This, args: *std.process.ArgIterator) !bool {
    var check = false;
    var mode: ExecutionMode = .args;
    var output: ?std.fs.File = null;
    defer if (output) |o| o.close();

    const ansi = ANSI.init(self.out);

    var tocompile = std.ArrayList(Source).empty;
    defer tocompile.deinit(self.allocator);
    defer for (tocompile.items) |s| s.deinit(self.allocator);

    const proj = usrl.Project.fromRoot(self.cwd) catch |err| {
        switch (err) {
            error.AssetsNotFound => try ansi.print(eh, "\"Assets\" directory not found", .{}),
            error.PackagesNotFound => try ansi.print(eh, "\"Packages\" directory not found", .{}),
            else => |er| try ansi.print(eh, "Unable to scan working directory for Unity project: {t}", .{er}),
        }
        return false;
    };

    var i: usize = 0;
    while (args.next()) |arg| {
        defer i += 1;
        if (i == 0) {
            if (std.mem.eql(u8, arg, "interactive") or std.mem.eql(u8, arg, "i") or std.mem.eql(u8, arg, "it")) {
                return try self.startInteractiveMode(proj);
            } else if (std.mem.eql(u8, arg, "manual") or std.mem.eql(u8, arg, "m")) {
                try openManual();
                return true;
            } else if (std.mem.eql(u8, arg, "help") or std.mem.eql(u8, arg, "usage") or std.mem.eql(u8, arg, "h") or std.mem.eql(u8, arg, "?")) {
                try printHelp(&self.out.interface);
                return true;
            } else if (std.mem.eql(u8, arg, "version") or std.mem.eql(u8, arg, "v")) {
                try self.out.interface.print("{s}", .{usrl.version});
                return true;
            } else if (std.mem.eql(u8, arg, "--")) {
                mode = .stdin;
                var code: [1 << 16]u8 = undefined;
                const len = try self.in.interface.readSliceShort(&code);

                const source = try Source.dupe(self.allocator, code[0..len], "stdin");
                errdefer source.deinit(self.allocator);

                try tocompile.append(self.allocator, source);
                break;
            }
        }
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "--check") or std.mem.eql(u8, arg, "-c")) {
                check = true;
            } else if (std.mem.eql(u8, arg, "--file") or std.mem.eql(u8, arg, "-f")) {
                mode = .file;
            } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
                if (output != null) {
                    try ansi.print(e, "Output file already specified\r\n", .{});
                    try printHelp(&self.out.interface);
                    return false;
                }
                if (args.next()) |output_arg| {
                    if (std.fs.path.isAbsolute(output_arg)) {
                        output = try std.fs.createFileAbsolute(output_arg, .{});
                    } else {
                        output = try self.cwd.createFile(output_arg, .{});
                    }
                } else {
                    try ansi.print(e, "Missing output file argument\r\n", .{});
                    try printHelp(&self.out.interface);
                    return false;
                }
            } else {
                try ansi.print(e, "Unknown option: {s}\r\n", .{arg});
                try printHelp(&self.out.interface);
                return false;
            }
            continue;
        }
        switch (mode) {
            .args => {
                const source = try Source.dupe(self.allocator, arg, null);
                errdefer source.deinit(self.allocator);

                try tocompile.append(self.allocator, source);
            },
            .file => {
                var file: std.fs.File = if (std.fs.path.isAbsolute(arg))
                    try std.fs.openFileAbsolute(arg, .{})
                else
                    try self.cwd.openFile(arg, .{});

                var buf: [256]u8 = undefined;
                var reader = file.reader(&buf);

                var code: [1 << 16]u8 = undefined;
                const len = try reader.interface.readSliceShort(&code);

                const source = try Source.dupe(self.allocator, code[0..len], std.fs.path.basename(arg));
                errdefer source.deinit(self.allocator);

                try tocompile.append(self.allocator, source);
            },
            .stdin => {
                try ansi.print(e, "Positional arguments are not allowed with '--'", .{});
                return false;
            },
        }
    }

    var tokens = std.ArrayList([]const usrl.Token).empty;
    defer tokens.deinit(self.allocator);
    defer for (tokens.items) |t| usrl.Token.free(self.allocator, t);

    var torun = std.ArrayList(usrl.Script).empty;
    defer torun.deinit(self.allocator);
    defer for (torun.items) |s| s.deinit(self.allocator);

    if (tocompile.items.len == 0) return true;
    for (tocompile.items) |source| {
        const tkns = self.tokenize(source) orelse continue;
        const script = self.parse(tkns, source) orelse {
            usrl.Token.free(self.allocator, tkns);
            continue;
        };
        errdefer script.deinit(self.allocator);

        {
            errdefer usrl.Token.free(self.allocator, tkns);
            try tokens.append(self.allocator, tkns);
        }

        try torun.append(self.allocator, script);
    }

    if (check) return torun.items.len == tocompile.items.len;
    if (torun.items.len < tocompile.items.len) return false;

    const output_file = output orelse self.out.file;
    var wbuf: [4096]u8 = undefined;
    var fout = output_file.writer(&wbuf);

    for (torun.items, 0..) |script, j| {
        if (!self.run(script, proj, &fout.interface, tocompile.items[j])) return false;
    }

    if (i == 0) try printHelp(&self.out.interface);
    return true;
}

pub fn startInteractiveMode(self: This, proj: usrl.Project) !bool {
    const ansi = ANSI.init(self.out);
    const writer = &self.out.interface;
    const reader = &self.in.interface;

    it: while (true) {
        try ansi.print("D", ">> ", .{});
        try writer.flush();

        const line = reader.takeDelimiterInclusive('\n') catch |err| switch (err) {
            error.EndOfStream => break :it,
            else => return err,
        };

        const query = std.mem.trim(u8, line, " \n\t\r");
        if (query.len == 0) continue; // skip empty lines

        const source = Source{
            .name = null,
            .source = query,
        };

        const tkns = self.tokenize(source) orelse continue;
        defer usrl.Token.free(self.allocator, tkns);

        const script = self.parse(tkns, source) orelse continue;
        defer script.deinit(self.allocator);

        _ = self.run(script, proj, writer, source);
    }
    try writer.writeAll("\r\n");
    return true;
}

pub fn tokenize(self: This, source: Source) ?[]usrl.Token {
    var diag: usrl.TokenizeDiagnostics = .init(self.allocator);
    defer diag.deinit();

    return usrl.tokenize(source.source, self.allocator, &diag) catch |err| {
        switch (err) {
            error.USRLTokenizeError => while (diag.pop()) |prob| {
                printTokenizeProblem(prob, source, self.err) catch continue;
            },
            else => self.err.interface.print("ERROR: {t}", .{err}) catch {},
        }
        return null;
    };
}

pub fn parse(self: This, tokens: []usrl.Token, source: Source) ?usrl.Script {
    var diag: usrl.ParseDiagnostics = .init(self.allocator);
    defer diag.deinit();

    return usrl.parse(tokens, self.allocator, &diag) catch |err| {
        switch (err) {
            error.USRLParseError => while (diag.pop()) |prob| {
                printParseProblem(prob, source, self.err) catch continue;
            },
            else => self.err.interface.print("ERROR: {t}", .{err}) catch {},
        }
        return null;
    };
}

pub fn run(self: This, script: usrl.Script, proj: usrl.Project, out: *std.Io.Writer, source: Source) bool {
    var diag: usrl.RuntimeDiagnostics = .init(self.allocator);
    defer diag.deinit();

    usrl.run(script, self.allocator, &diag, proj, out) catch |err| {
        switch (err) {
            error.USRLRuntimeError => while (diag.pop()) |prob| {
                printRuntimeProblem(prob, source, self.err) catch continue;
            },
            else => self.err.interface.print("ERROR: {t}", .{err}) catch {},
        }
        return false;
    };
    return true;
}

pub fn printTokenizeProblem(tokenize_error: usrl.TokenizeProblem, source: Source, fw: *std.fs.File.Writer) std.Io.Writer.Error!void {
    var ansi = ANSI.init(fw);
    var out = &fw.interface;

    try ansi.print(eh, "SYNTAX ERROR: ", .{});

    switch (tokenize_error) {
        .never_closed_string => |err| {
            try ansi.print(e, "Never closed string at index {d}\r\n", .{err.location.index});
            try printLineHighlight(err.location, source, fw);
        },
        .unexpected_character => |err| {
            try ansi.print(e, "Unexpected character '{s}'\r\n", .{err.location.lexeme(source.source)});
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_number => |err| {
            try ansi.print(e, "Invalid number '{s}'\r\n", .{err.location.lexeme(source.source)});
            try printLineHighlight(err.location, source, fw);
        },
    }

    try out.flush();
}

pub fn printParseProblem(parse_error: usrl.ParseProblem, source: Source, fw: *std.fs.File.Writer) std.Io.Writer.Error!void {
    var ansi = ANSI.init(fw);
    var out = &fw.interface;

    try ansi.print(eh, "SYNTAX ERROR: ", .{});

    switch (parse_error) {
        .unexpected_token => |err| {
            {
                ansi.begin(e);
                defer ansi.end(e);
                try out.print("Unexpected {f}", .{err.found.value});
                if (err.expected.len > 0) try out.print(", expected ", .{});
                for (err.expected, 0..) |expected_type, i| {
                    if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                    if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                    try out.print("{f}", .{expected_type});
                }
                try out.print("\r\n", .{});
            }
            try printLineHighlight(err.found.loc, source, fw);
        },
        .invalid_csharp_identifier => |err| {
            try ansi.print(e, "Invalid C# identifier '{s}'\r\n", .{err.token.asSlice()});
            try printLineHighlight(err.token.loc, source, fw);
        },
        .invalid_guid => |err| {
            try ansi.print(e, "Invalid GUID '{s}'\r\n", .{err.token.asSlice()});
            try printLineHighlight(err.token.loc, source, fw);
        },
        .absolute_path => |err| {
            try ansi.print(e, "Path must be relative to project. Absolute path found: '{s}'\r\n", .{err.token.asSlice()});
            try printLineHighlight(err.token.loc, source, fw);
        },
        .duplicate_clause => |err| {
            try ansi.print(e, "Duplicate clause '{s}' appeared at:\r\n", .{err.clause});
            try printLineHighlight(err.first.loc, source, fw);
            try ansi.print(e, "But also at:\r\n", .{});
            try printLineHighlight(err.second.loc, source, fw);
        },
        .missing_clause => |err| {
            try ansi.print(e, "Missing clause '{s}'\r\n", .{err.clause});
            try printLineHighlight(err.placement.loc, source, fw);
        },
        .invalid_assignment_target => |err| {
            try ansi.print(e, "Invalid assignment target\r\n", .{});
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_mode_for_clause => |err| {
            try ansi.print(e, "Cannot use search mode '{t}' with clause '{s}'\r\n", .{ err.mode, err.clause });
            try printLineHighlight(err.location, source, fw);
        },
        .unexpected => |err| {
            try ansi.print(e, "Unexpected {t}\r\n", .{err});
        },
    }

    try out.flush();
}

pub fn printRuntimeProblem(runtime_error: usrl.RuntimeProblem, source: Source, fw: *std.fs.File.Writer) std.Io.Writer.Error!void {
    const ansi = ANSI.init(fw);
    const out = &fw.interface;

    try ansi.print(eh, "RUNTIME ERROR: ", .{});

    switch (runtime_error) {
        .invalid_asset => |err| {
            try ansi.print(e, "Invalid asset path\r\n", .{});
            try printLineHighlight(err.path, source, fw);
        },
        .invalid_path => |err| {
            try ansi.print(e, "Invalid path\r\n", .{});
            try printLineHighlight(err.path, source, fw);
        },
        .division_by_zero => |err| {
            try ansi.print(e, "Division by zero\r\n", .{});
            try printLineHighlight(err.location, source, fw);
        },
        .type_mismatch => |err| {
            try ansi.print(e, "Found {s} as lhs\r\n", .{@tagName(err.left)});
            try printLineHighlight(err.left_loc, source, fw);
            try ansi.print(e, "And {s} as rhs\r\n", .{@tagName(err.right)});
            try printLineHighlight(err.right_loc, source, fw);
        },
        .unexpected_type => |err| {
            {
                ansi.begin(e);
                defer ansi.end(e);
                try out.print("Unexpected type {s}", .{@tagName(err.found)});
                if (err.expected.len > 0) try out.print(", expected ", .{});
                for (err.expected, 0..) |expected_type, i| {
                    if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                    if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                    try out.print("{s}", .{@tagName(expected_type)});
                }
                try out.print("\r\n", .{});
            }
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_argument_count => |err| {
            const mode_str = switch (err.mode) {
                .exact => "exactly",
                .at_least => "at least",
                .at_most => "at most",
            };
            try ansi.print(e, "Invalid argument count: expected {s} {d}, found {d}\r\n", .{ mode_str, err.expected, err.found });
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_argument => |err| {
            try ansi.print(e, "Invalid argument: {s}\r\n", .{err.reason});
            try printLineHighlight(err.location, source, fw);
        },
        .undefined_variable => |err| {
            try ansi.print(e, "Undefined {f}. Use '{f} := (...)' to define it.\r\n", .{
                err.varr.value,
                std.fmt.alt(err.varr.value, .raw),
            });
            try printLineHighlight(err.location, source, fw);
        },
        .already_defined_variable => |err| {
            try ansi.print(e, "{f} is already defined. Use '{f} = (...)' to update it.\r\n", .{
                err.varr.value,
                std.fmt.alt(err.varr.value, .raw),
            });
            try printLineHighlight(err.location, source, fw);
        },
        .overriding_readonly => |err| {
            try ansi.print(e, "Cannot override read-only {f}\r\n", .{err.varr.value});
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_index => |err| {
            try ansi.print(e, "Invalid index {d}\r\n", .{err.index});
            try printLineHighlight(err.location, source, fw);
        },
        .out_of_bounds => |err| {
            try ansi.print(e, "Index {d} out of bounds (length: {d})\r\n", .{ err.index, err.len });
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_asset_reference => |err| {
            try ansi.print(e, "Invalid asset with GUID '{f}'. This could be because the asset could not be opened properly or it wasn't properly configured.\r\n", .{err.guid});
            try printLineHighlight(err.location, source, fw);
        },
        .asset_not_found => |err| {
            try ansi.print(e, "Asset with GUID '{f}' was not found.\r\n", .{err.guid});
            try printLineHighlight(err.location, source, fw);
        },
        .object_definition_not_found => |err| {
            try ansi.print(e, "Object definition with file ID {d} was not found in asset with GUID '{f}'.\r\n", .{ err.file_id, err.guid });
            try printLineHighlight(err.location, source, fw);
        },
        .null_object_definition_reference => |err| {
            try ansi.print(e, "Object definition is null\r\n", .{});
            try printLineHighlight(err.location, source, fw);
        },
        .unassignable_value => |err| {
            try ansi.print(e, "Value of type {t} cannot be assigned to {t}\r\n", .{ err.value_type, err.assigned_to });
            try printLineHighlight(err.location, source, fw);
        },
        .undefinable_target => |err| {
            try ansi.print(e, "Cannot define {t}. The ':=' operator can only be used with variables.\r\n", .{err.target});
            try printLineHighlight(err.location, source, fw);
        },
        .search_failed => |err| {
            try ansi.print(e, "Search for object with GUID '{f}' failed.\r\n", .{err.guid});
        },
        .update_during_readonly_eval => |err| {
            try ansi.print(e, "Cannot perform update during read-only evaluation.\r\n", .{});
            try printLineHighlight(err.location, source, fw);
        },
        .invalid_target_asset => |err| {
            const filter_str = switch (err.filter) {
                .any => "any asset",
                .prefabs_and_components => "prefab or component",
                .components_only => "component",
            };
            try ansi.print(e, "Invalid target asset. Expected {s} type.\r\n", .{filter_str});
            try printLineHighlight(err.location, source, fw);
        },
        .unexpected => |err| {
            try ansi.print(e, "Unexpected {t}\r\n", .{err});
        },
    }

    try out.flush();
}

pub fn printLineHighlight(loc: usrl.Token.Location, source: Source, out: *std.fs.File.Writer) std.Io.Writer.Error!void {
    std.debug.assert(loc.index <= source.source.len);
    const line_index = source.lineIndex(loc.index).?;
    const line = source.line(line_index).?;

    var ansi = ANSI.init(out);
    if (source.name) |name| {
        try ansi.print("*", "{s}:{d} \r\n", .{ name, line_index + 1 });
    }
    try out.interface.print("{s}\r\n", .{line});

    const index = loc.index - source.lineStart(line_index).?;
    const start = offset(index, line);
    const len = offset(@min(index + @max(loc.len, 1) - 1, line.len - 1), line) + 1 - start;

    ansi.begin("g");
    defer ansi.end("g");

    _ = try out.interface.splatByte(' ', start);
    try out.interface.writeByte('^');
    if (len > 1) _ = try out.interface.splatByte('~', len - 1);

    try out.interface.print("\r\n", .{});
}

/// Calculates the offset of the given index in the line, considering tabs.
pub fn offset(index: usize, line: []const u8) usize {
    var off: usize = 0;
    const tab_size = 8; // TODO: get tab size from os or something
    for (line[0..index]) |c| {
        if (c == '\t') {
            off += tab_size - (off % tab_size);
        } else {
            off += 1;
        }
    }
    return off;
}

/// Prints the standard help message to the given writer.
pub fn printHelp(out: *std.Io.Writer) std.Io.Writer.Error!void {
    try out.writeAll(@embedFile("help.txt"));
}

/// Opens the language manual
pub fn openManual() !void {
    const cwd = std.fs.cwd();
    const manual_file = try cwd.createFile("manual.html", .{});
    try manual_file.writeAll(@embedFile("manual.html"));

    var buf: [256]u8 = undefined;
    const path = try cwd.realpath("manual.html", &buf);
    buf[path.len] = 0;

    openURL(@ptrCast(path));
}

/// Opens the given URL.
pub fn openURL(url: [:0]const u8) void {
    switch (builtin.os.tag) {
        .windows => {
            const windows = @cImport(@cInclude("windows.h"));
            _ = windows.ShellExecuteA(null, "open", url, null, null, windows.SW_SHOWNORMAL);
        },
        else => {
            const stdlib = @cImport(@cInclude("stdlib.h"));
            var buf: [256]u8 = undefined;
            @memcpy(buf[0..5], "open ");
            @memcpy(buf[5 .. url.len + 5], url);
            buf[url.len + 5] = 0;
            _ = stdlib.system(&buf);
            return;
        },
    }
}

pub const SourcedScript = struct {
    source: Source,
    script: usrl.Script.Managed,
};

pub const ANSI = struct {
    enabled: bool = false,
    out: *std.Io.Writer,

    pub fn init(out: *std.fs.File.Writer) ANSI {
        const self = ANSI{
            .out = &out.interface,
            .enabled = out.file.getOrEnableAnsiEscapeSupport(),
        };
        return self;
    }

    pub fn begin(self: ANSI, tags: []const u8) void {
        if (!self.enabled) return;

        for (tags) |tag| {
            self.out.writeAll(switch (tag) {
                '*' => "\x1B[1m", // bold
                '.' => "\x1B[2m", // dim/faint
                '/' => "\x1B[3m", // italic
                '_' => "\x1B[4m", // underline
                '|' => "\x1B[5m", // blink
                '-' => "\x1B[9m", // strikethrough
                'd' => "\x1B[30m", // black (dark)
                'r' => "\x1B[31m", // red
                'g' => "\x1B[32m", // green
                'y' => "\x1B[33m", // yellow
                'b' => "\x1B[34m", // blue
                'm' => "\x1B[35m", // magenta
                'c' => "\x1B[36m", // cyan
                'w' => "\x1B[37m", // white
                'D' => "\x1B[90m", // bright black (dark gray)
                'R' => "\x1B[91m", // bright red
                'G' => "\x1B[92m", // bright green
                'Y' => "\x1B[93m", // bright yellow
                'B' => "\x1B[94m", // bright blue
                'M' => "\x1B[95m", // bright magenta
                'C' => "\x1B[96m", // bright cyan
                'W' => "\x1B[97m", // bright white
                else => continue,
            }) catch continue;
        }
    }

    pub fn end(self: ANSI, tags: []const u8) void {
        if (!self.enabled) return;

        for (tags) |tag| {
            self.out.writeAll(switch (tag) {
                '*', '.' => "\x1B[22m",
                '/' => "\x1B[23m",
                '_' => "\x1B[24m",
                '|' => "\x1B[25m",
                '-' => "\x1B[29m",
                'd', 'r', 'g', 'b', 'y', 'c', 'm', 'w' => "\x1B[39m",
                'D', 'R', 'G', 'B', 'Y', 'C', 'M', 'W' => "\x1B[39m",
                else => continue,
            }) catch continue;
        }
    }

    pub fn print(self: ANSI, tags: []const u8, comptime format: []const u8, args: anytype) std.Io.Writer.Error!void {
        if (!self.enabled) {
            try self.out.print(format, args);
            return;
        }

        self.begin(tags);
        defer self.end(tags);

        try self.out.print(format, args);
    }
};
