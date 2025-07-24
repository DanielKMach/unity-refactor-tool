const builtin = @import("builtin");
const std = @import("std");
const urt = @import("urt");

const This = @This();
const log = std.log.scoped(.cli);

const e = "R";
const eh = "r";

pub const ExecutionMode = enum {
    args,
    file,
};

allocator: std.mem.Allocator,
out: std.fs.File.Writer,
cwd: std.fs.Dir,

pub fn process(self: This, args: *std.process.ArgIterator) !bool {
    var mode: ExecutionMode = .args;
    var output: ?std.fs.File = null;
    defer if (output) |o| o.close();
    const ansi = ANSI.init(self.out);

    var parser = urt.parsing.Parser{
        .allocator = self.allocator,
    };
    var scripts = std.ArrayList(LocalizedScript).init(self.allocator);
    defer scripts.deinit();
    defer for (scripts.items) |*s| s.cleanup();

    var i: usize = 0;
    while (args.next()) |arg| {
        defer i += 1;
        if (i == 0) {
            if (std.mem.eql(u8, arg, "i") or std.mem.eql(u8, arg, "it") or std.mem.eql(u8, arg, "interactive")) {
                return try self.startInteractiveMode(std.io.getStdIn().reader());
            } else if (std.mem.eql(u8, arg, "m") or std.mem.eql(u8, arg, "manual")) {
                try openManual();
                return true;
            } else if (std.mem.eql(u8, arg, "h") or std.mem.eql(u8, arg, "help") or std.mem.eql(u8, arg, "usage") or std.mem.eql(u8, arg, "?")) {
                try printHelp(self.out);
                return true;
            } else if (std.mem.eql(u8, arg, "--")) {
                const source = try urt.Source.fromStdin(self.allocator);
                defer source.deinit();
                if (try self.parse(source, &parser)) |script| {
                    return try self.run(script, .{
                        .cwd = self.cwd,
                        .out = self.out.any(),
                        .allocator = self.allocator,
                    });
                }
                return false;
            }
        }
        if (std.mem.startsWith(u8, arg, "-")) {
            if (std.mem.eql(u8, arg, "--file") or std.mem.eql(u8, arg, "-f")) {
                mode = .file;
            } else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
                if (output != null) {
                    try ansi.print(e, "Output file already specified\r\n", .{});
                    try printHelp(self.out);
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
                    try printHelp(self.out);
                    return false;
                }
            } else {
                try ansi.print(e, "Unknown option: {s}\r\n", .{arg});
                try printHelp(self.out);
                return false;
            }
            continue;
        }
        switch (mode) {
            .args => {
                const source = try urt.Source.anonymous(arg, self.allocator);
                defer source.deinit();
                if (try self.parse(source, &parser)) |script| {
                    try scripts.append(.{
                        .script = script,
                    });
                    continue;
                }
                return false;
            },
            .file => {
                var dir: std.fs.Dir = undefined;
                var source: urt.Source = undefined;

                if (std.fs.path.isAbsolute(arg)) {
                    source = try urt.Source.fromPathAbsolute(arg, self.allocator);
                    dir = try std.fs.openDirAbsolute(std.fs.path.dirname(arg).?, .{ .iterate = true });
                } else {
                    source = try urt.Source.fromPath(self.cwd, arg, self.allocator);
                    const abs_path = try self.cwd.realpathAlloc(self.allocator, arg);
                    defer self.allocator.free(abs_path);
                    dir = try std.fs.openDirAbsolute(std.fs.path.dirname(abs_path).?, .{ .iterate = true });
                }

                if (try self.parse(source, &parser)) |script| {
                    try scripts.append(.{
                        .script = script,
                        .dir = dir,
                    });
                    continue;
                }
                return false;
            },
        }
    }
    for (scripts.items) |script| {
        const output_file = output orelse self.out.context;
        const writer = output_file.writer();
        if (!try self.run(script.script, .{
            .cwd = script.dir orelse self.cwd,
            .out = writer.any(),
            .allocator = self.allocator,
        })) {
            return false;
        }
    }
    return true;
}

pub fn startInteractiveMode(self: This, in: std.fs.File.Reader) !bool {
    const ansi = ANSI.init(self.out);
    var parser = urt.parsing.Parser{
        .allocator = self.allocator,
    };

    it: while (true) {
        try ansi.print("D", ">> ", .{});
        const line = blk: {
            const l = try in.readUntilDelimiterOrEofAlloc(self.allocator, '\n', std.math.maxInt(u16));
            break :blk l orelse break :it;
        };
        defer self.allocator.free(line);

        const query = std.mem.trim(u8, line, " \n\t\r");
        if (query.len == 0) {
            continue; // skip empty lines
        }

        const source = try urt.Source.anonymous(query, self.allocator);
        defer source.deinit();

        _ = try self.parseAndRun(source, &parser, .{
            .allocator = self.allocator,
            .cwd = self.cwd,
            .out = self.out.any(),
        });
    }
    try self.out.writeAll("\r\n");
    return true;
}

pub fn parse(self: This, source: urt.Source, parser: *urt.parsing.Parser) !?urt.runtime.Script {
    const result = try parser.parse(source);
    if (result.isErr()) |err| {
        try printParseError(err, source, self.out);
        return null;
    }
    return result.ok;
}

pub fn run(self: This, script: urt.runtime.Script, config: urt.runtime.Script.RunConfig) !bool {
    const result = try script.run(config);
    if (result.isErr()) |err| {
        try printRuntimeError(err, self.out);
        return false;
    }
    return true;
}

pub fn parseAndRun(self: This, source: urt.Source, parser: *urt.parsing.Parser, config: urt.runtime.Script.RunConfig) !bool {
    const script = try self.parse(source, parser);
    if (script) |s| {
        defer s.deinit();
        return try self.run(s, config);
    }
    return false;
}

pub fn printParseError(parse_error: urt.results.ParseError, source: urt.Source, out: std.fs.File.Writer) !void {
    const ansi = ANSI.init(out);
    try ansi.print(eh, "PARSING ERROR: ", .{});

    switch (parse_error) {
        .unknown => {
            try ansi.print(e, "Unknown statement\r\n", .{});
        },
        .never_closed_string => |err| {
            try ansi.print(e, "Never closed string at index {d}\r\n", .{err.location.index});
            try printLineHighlight(err.location, source, out);
        },
        .unexpected_token => |err| {
            {
                ansi.begin(e);
                defer ansi.end(e);
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
            try ansi.print(e, "Unexpected character '{s}'\r\n", .{err.location.lexeme(source.source)});
            try printLineHighlight(err.location, source, out);
        },
        .invalid_csharp_identifier => |err| {
            try ansi.print(e, "Invalid C# identifier '{s}'\r\n", .{err.token.loc.lexeme(source.source)});
            try printLineHighlight(err.token.loc, source, out);
        },
        .invalid_guid => |err| {
            try ansi.print(e, "Invalid GUID '{s}'\r\n", .{err.token.loc.lexeme(source.source)});
            try printLineHighlight(err.token.loc, source, out);
        },
        .invalid_number => |err| {
            try ansi.print(e, "Invalid number '{s}'\r\n", .{err.location.lexeme(source.source)});
            try printLineHighlight(err.location, source, out);
        },
        .duplicate_clause => |err| {
            try ansi.print(e, "Duplicate clause '{s}' appeared at:\r\n", .{err.clause});
            try printLineHighlight(err.first.loc, source, out);
            try ansi.print(e, "But also at:\r\n", .{});
            try printLineHighlight(err.second.loc, source, out);
        },
        .missing_clause => |err| {
            try ansi.print(e, "Missing clause '{s}'\r\n", .{err.clause});
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
    try ansi.print(eh, "RUNTIME ERROR: ", .{});

    switch (runtime_error) {
        .invalid_asset => |_| {
            try ansi.print(e, "Invalid asset path\r\n", .{});
        },
        .invalid_path => |_| {
            try ansi.print(e, "Invalid path\r\n", .{});
        },
    }
}

pub fn printLineHighlight(loc: urt.Token.Location, source: urt.Source, out: std.fs.File.Writer) !void {
    const line_index = source.lineIndex(loc.index) orelse return error.InvalidLocation;
    if (line_index != source.lineIndex(loc.index + @max(loc.len, 1) - 1)) return error.InvalidLocation;
    const line = source.line(line_index) orelse return error.InvalidLocation;

    const ansi = ANSI.init(out);
    if (source.name) |name| {
        try ansi.print("*", "{s}:{d} \r\n", .{ name, line_index + 1 });
    }
    try out.print("{s}\r\n", .{line});

    const index = loc.index - (source.lineStart(line_index) orelse unreachable);
    const start = offset(index, line);
    const len = offset(index + @max(loc.len, 1) - 1, line) + 1 - start;

    ansi.begin("g");
    defer ansi.end("g");

    try out.writeByteNTimes(' ', start);
    try out.writeByte('^');
    if (len > 1) try out.writeByteNTimes('~', len - 1);

    try out.print("\r\n", .{});
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

pub const LocalizedScript = struct {
    script: urt.runtime.Script,
    dir: ?std.fs.Dir = null,

    pub fn cleanup(self: *LocalizedScript) void {
        self.script.deinit();
        if (self.dir) |*d| d.close();
    }
};

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
