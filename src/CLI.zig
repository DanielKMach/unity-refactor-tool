const builtin = @import("builtin");
const std = @import("std");
const urt = @import("urt");

const This = @This();
const log = std.log.scoped(.cli);

pub const ExecutionMode = enum {
    args,
    file,
    stdin,
    interactive,
};

allocator: std.mem.Allocator,
out: std.fs.File.Writer,
cwd: std.fs.Dir,

pub fn process(self: This, args: *std.process.ArgIterator) !bool {
    var mode: ExecutionMode = .args;

    if (args.next()) |arg| {
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "--file") or std.mem.eql(u8, arg, "-f")) {
                mode = .file;
            } else if (std.mem.eql(u8, arg, "--")) {
                mode = .stdin;
            } else if (std.mem.eql(u8, arg, "--interactive") or std.mem.eql(u8, arg, "-i")) {
                mode = .interactive;
            } else if (std.mem.eql(u8, arg, "--manual") or std.mem.eql(u8, arg, "-m")) {
                try openManual();
                return true;
            } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
                try printHelp(self.out);
                return true;
            } else {
                try self.out.print("\x1b[31mUnknown option: {s}\x1b[0m\r\n", .{arg});
                try printHelp(self.out);
                return false;
            }
        } else {
            const source = try urt.Source.anonymous(arg, self.allocator);
            defer source.deinit();
            if (!try self.run(source)) return false;
        }
    } else {
        try printHelp(self.out);
        return true;
    }

    switch (mode) {
        .file => {
            while (args.next()) |p| {
                var allocated = false;
                var path: []const u8 = undefined;
                defer if (allocated) self.allocator.free(path);

                if (std.fs.path.isAbsolute(p)) {
                    path = p;
                } else {
                    path = try self.cwd.realpathAlloc(self.allocator, p);
                    allocated = true;
                }

                const source = try urt.Source.fromAbsPath(path, self.allocator);
                defer source.deinit();

                if (!try self.run(source)) return false;
            }
        },
        .stdin => {
            const source = try urt.Source.fromStdin(self.allocator);
            defer source.deinit();

            if (!try self.run(source)) return false;
        },
        .args => {
            while (args.next()) |query| {
                const source = try urt.Source.anonymous(query, self.allocator);
                defer source.deinit();
                if (!try self.run(source)) return false;
            }
        },
        .interactive => {
            const in = std.io.getStdIn().reader();

            while (true) {
                try self.out.writeAll(">> ");
                const line = try in.readUntilDelimiterOrEofAlloc(self.allocator, '\n', std.math.maxInt(u16)) orelse break;
                defer self.allocator.free(line);

                const query = std.mem.trim(u8, line, " \n\t\r");

                if (query.len == 0) {
                    continue; // skip empty lines
                }
                const source = try urt.Source.anonymous(query, self.allocator);
                defer source.deinit();

                if (!try self.run(source)) return false;
            }
            try self.out.writeAll("\r\n");
        },
    }
    return true;
}

pub fn run(self: This, source: urt.Source) !bool {
    const result = try urt.eval(source, self.allocator, self.cwd, self.out.any());
    switch (result) {
        .ok => return true,
        .err => |err| {
            switch (err) {
                .parsing => |parse_err| try printParseError(parse_err, source, self.out),
                .runtime => |runtime_err| try printRuntimeError(runtime_err, self.out),
            }
            return false;
        },
    }
}

pub fn printParseError(parse_error: urt.results.ParseError, source: urt.Source, out: std.fs.File.Writer) !void {
    const ansi = ANSI.init(out);
    try ansi.print("*r", "PARSING ERROR: ", .{});

    switch (parse_error) {
        .unknown => {
            try ansi.print("r", "Unknown statement\r\n", .{});
        },
        .never_closed_string => |err| {
            try ansi.print("r", "Never closed string at index {d}\r\n", .{err.location.index});
            try printLineHighlight(err.location, source, out);
        },
        .unexpected_token => |err| {
            {
                ansi.begin("r");
                defer ansi.end("r");
                try out.print("Unexpected token '{s}'", .{@tagName(err.found.value)});
                if (err.expected.len > 0) try out.print(", expected ", .{});
                for (err.expected, 0..) |expected_type, i| {
                    if (i > 0 and i != err.expected.len - 1) try out.print(", ", .{});
                    if (i != 0 and i == err.expected.len - 1) try out.print(" or ", .{});
                    try out.print("{s}", .{@tagName(expected_type)});
                }
                try out.print("\r\n", .{});
            }
            try printLineHighlight(err.found.loc, source, out);
        },
        .unexpected_character => |err| {
            try ansi.print("r", "Unexpected character '{s}'\r\n", .{err.location.lexeme(source.source)});
            try printLineHighlight(err.location, source, out);
        },
        .invalid_csharp_identifier => |err| {
            try ansi.print("r", "Invalid C# identifier '{s}'\r\n", .{err.token.loc.lexeme(source.source)});
            try printLineHighlight(err.token.loc, source, out);
        },
        .invalid_guid => |err| {
            try ansi.print("r", "Invalid GUID '{s}'\r\n", .{err.token.loc.lexeme(source.source)});
            try printLineHighlight(err.token.loc, source, out);
        },
        .invalid_number => |err| {
            try ansi.print("r", "Invalid number '{s}'\r\n", .{err.location.lexeme(source.source)});
            try printLineHighlight(err.location, source, out);
        },
        .duplicate_clause => |err| {
            try ansi.print("r", "Duplicate clause '{s}' appeared at:\r\n", .{err.clause});
            try printLineHighlight(err.first.loc, source, out);
            try ansi.print("r", "But also at:\r\n", .{});
            try printLineHighlight(err.second.loc, source, out);
        },
        .missing_clause => |err| {
            try ansi.print("r", "Missing clause '{s}'\r\n", .{err.clause});
            try printLineHighlight(err.placement.loc, source, out);
        },
        .multiple => |errs| {
            for (errs) |err| {
                try printParseError(err, source, out);
            }
        },
    }
}

pub fn printRuntimeError(runtime_error: urt.results.RuntimeError, out: std.fs.File.Writer) !void {
    const ansi = ANSI.init(out);
    try ansi.print("*r", "RUNTIME ERROR: ", .{});

    switch (runtime_error) {
        .invalid_asset => |_| {
            try ansi.print("r", "Invalid asset path\r\n", .{});
        },
        .invalid_path => |_| {
            try ansi.print("r", "Invalid path\r\n", .{});
        },
    }
}

pub fn printLineHighlight(loc: urt.Token.Location, source: urt.Source, out: std.fs.File.Writer) !void {
    const line_number = source.lineNumber(loc.index) orelse return error.InvalidLocation;
    if (line_number != source.lineNumber(loc.index + @max(loc.len, 1) - 1)) return error.InvalidLocation;
    const line = source.line(line_number - 1) orelse return error.InvalidLocation;

    const ansi = ANSI.init(out);
    try ansi.print("*", "{s}:{d}: \r\n", .{ source.name, line_number });
    try out.print("{s}\r\n", .{line});

    ansi.begin("g");
    defer ansi.end("g");

    try out.writeByteNTimes(' ', loc.index);
    try out.writeByte('^');
    if (loc.len > 1) try out.writeByteNTimes('~', loc.len - 1);

    try out.print("\r\n", .{});
}

/// Prints the standard help message to the given writer.
pub fn printHelp(out: std.fs.File.Writer) anyerror!void {
    try out.writeAll(@embedFile("help.txt"));
}

/// Opens the language manual
pub fn openManual() anyerror!void {
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

pub const ANSI = struct {
    enabled: bool = false,
    out: std.fs.File.Writer,

    pub fn init(out: std.fs.File.Writer) ANSI {
        var self = ANSI{ .out = out };
        _ = self.enable();
        return self;
    }

    pub fn begin(self: ANSI, tags: []const u8) void {
        if (!self.enabled) return;

        for (tags) |tag| {
            self.out.writeAll(switch (tag) {
                '*' => "\x1B[1m",
                '_' => "\x1B[4m",
                'r' => "\x1B[31m",
                'g' => "\x1B[32m",
                'b' => "\x1B[34m",
                'y' => "\x1B[33m",
                'c' => "\x1B[36m",
                'm' => "\x1B[35m",
                else => continue,
            }) catch continue;
        }
    }

    pub fn end(self: ANSI, tags: []const u8) void {
        if (!self.enabled) return;

        for (tags) |tag| {
            self.out.writeAll(switch (tag) {
                '*' => "\x1B[22m",
                '_' => "\x1B[24m",
                'r', 'g', 'b', 'y', 'c', 'm' => "\x1B[39m",
                else => continue,
            }) catch continue;
        }
    }

    pub fn print(self: ANSI, tags: []const u8, comptime format: []const u8, args: anytype) !void {
        if (!self.enabled) {
            try self.out.print(format, args);
            return;
        }

        self.begin(tags);
        defer self.end(tags);

        try self.out.print(format, args);
    }

    /// Enables ANSI escape codes for the needed platforms (windows).
    pub fn enable(self: *ANSI) bool {
        self.enabled = self.out.context.getOrEnableAnsiEscapeSupport();
        return self.enabled;
    }
};
