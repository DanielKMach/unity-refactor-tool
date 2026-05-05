const builtin = @import("builtin");
const std = @import("std");
const usrl = @import("usrl");

const Source = @import("Source.zig");
const Glep = @import("Glep.zig");
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

pub fn process(self: This, _: *std.process.ArgIterator) !bool {
    const ansi = ANSI.init(self.out);

    var tocompile = std.ArrayList(Source).empty;
    defer tocompile.deinit(self.allocator);
    defer for (tocompile.items) |s| s.deinit(self.allocator);

    var glep = try Glep.init(self.allocator);
    defer glep.deinit(self.allocator);

    _ = glep.next(); // executable name

    const sub = glep.peek() orelse {
        try printHelp(&self.out.interface);
        return true;
    };

    if (std.mem.eql(u8, sub, "manual") or std.mem.eql(u8, sub, "m")) {
        try openManual();
        return true;
    } else if (std.mem.eql(u8, sub, "help") or std.mem.eql(u8, sub, "usage") or std.mem.eql(u8, sub, "h") or std.mem.eql(u8, sub, "?")) {
        try printHelp(&self.out.interface);
        return true;
    } else if (std.mem.eql(u8, sub, "version") or std.mem.eql(u8, sub, "v")) {
        try self.out.interface.print("{s}\r\n", .{usrl.version});
        return true;
    }

    const proj = usrl.Project.fromRoot(self.cwd) catch |err| {
        switch (err) {
            error.AssetsNotFound => try ansi.print(e, "\"Assets\" directory not found. This tool must be executed from the root directory of a Unity project.\r\n", .{}),
            error.PackagesNotFound => try ansi.print(e, "\"Packages\" directory not found. This tool must be executed from the root directory of a Unity project.\r\n", .{}),
            else => |er| try ansi.print(e, "Unable to scan working directory for Unity project: {t}\r\n", .{er}),
        }
        return false;
    };

    if (std.mem.eql(u8, sub, "interactive") or std.mem.eql(u8, sub, "i") or std.mem.eql(u8, sub, "it")) {
        return try self.startInteractiveMode(proj);
    }

    const check = glep.has("--check/-c");
    const output = if (glep.has("--out/-o")) blk: {
        if (check) {
            try ansi.print(e, "'--check' and '--out' cannot be used together.\r\n", .{});
            return false;
        }
        break :blk glep.get("--out/-o") orelse {
            try ansi.print(e, "Unspecified output file after '--out'.\r\n", .{});
            return false;
        };
    } else null;

    const mode: ExecutionMode = blk: {
        const stdin = glep.has("--");
        const file = glep.has("--file/-f");
        if (stdin and file) {
            try ansi.print(e, "'--file' and '--' cannot be used together.\r\n", .{});
            return false;
        }
        if (stdin) break :blk .stdin;
        if (file) break :blk .file;
        break :blk .args;
    };

    switch (mode) {
        .stdin => {
            if (glep.next()) |arg| {
                try ansi.print(e, "Unnecessary argument '{s}' found.\r\n", .{arg});
                return false;
            }

            var query: [1 << 16]u8 = undefined;
            const len = try self.in.interface.readSliceShort(&query);

            try tocompile.append(self.allocator, try .dupe(self.allocator, query[0..len], "stdin"));
        },
        .file => {
            while (glep.get("--file/-f")) |path| {
                var file: std.fs.File = blk: {
                    if (std.fs.path.isAbsolute(path)) {
                        break :blk std.fs.openFileAbsolute(path, .{});
                    } else {
                        break :blk self.cwd.openFile(path, .{});
                    }
                } catch |err| {
                    const name = std.fs.path.basename(path);
                    try ansi.print(e, "Failed to open script file '{s}': {t}\r\n", .{ name, err });
                    return false;
                };
                defer file.close();

                var buf: [256]u8 = undefined;
                var reader = file.reader(&buf);

                var query: [1 << 16]u8 = undefined;
                const len = try reader.interface.readSliceShort(&query);

                try tocompile.append(self.allocator, try .dupe(
                    self.allocator,
                    query[0..len],
                    std.fs.path.basename(path),
                ));
            }

            if (glep.next()) |arg| {
                try ansi.print(e, "Unnecessary argument '{s}' found.\r\n", .{arg});
                return false;
            }
        },
        .args => {
            while (glep.next()) |stmt| {
                try tocompile.append(self.allocator, try .dupe(self.allocator, stmt, null));
            }
        },
    }
    std.debug.assert(glep.remaining() == 0);

    var torun = std.ArrayList(usrl.Script.Managed).empty;
    defer torun.deinit(self.allocator);
    defer for (torun.items) |s| s.deinit();

    if (tocompile.items.len == 0) return true;
    for (tocompile.items) |source| {
        const tkns = self.tokenize(source) orelse continue;
        defer usrl.Token.free(self.allocator, tkns);

        const script = self.parse(tkns, source) orelse continue;
        errdefer script.deinit();

        try torun.append(self.allocator, script);
    }

    if (check) return torun.items.len == tocompile.items.len;
    if (torun.items.len < tocompile.items.len) return false;

    const outfile = if (output) |outpath| blk: {
        if (std.fs.path.isAbsolute(outpath)) {
            break :blk std.fs.createFileAbsolute(outpath, .{});
        } else {
            break :blk self.cwd.createFile(outpath, .{});
        }
    } catch |err| {
        const name = std.fs.path.basename(outpath);
        try ansi.print(e, "Failed to open output file '{s}': {t}\r\n", .{ name, err });
        return false;
    } else self.out.file;
    defer outfile.close();

    var wbuf: [4096]u8 = undefined;
    var out = outfile.writer(&wbuf);

    for (torun.items, 0..) |s, j| {
        if (!self.run(s.script, proj, &out.interface, tocompile.items[j])) return false;
    }
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
        defer script.deinit();

        _ = self.run(script.script, proj, writer, source);
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
            else => {
                const ansi = ANSI.init(self.err);
                ansi.print(eh, "SYNTAX ERROR: ", .{}) catch {};
                ansi.print(e, "Unexpected {t}\r\n", .{err}) catch {};
            },
        }
        return null;
    };
}

pub fn parse(self: This, tokens: []usrl.Token, source: Source) ?usrl.Script.Managed {
    var diag: usrl.ParseDiagnostics = .init(self.allocator);
    defer diag.deinit();

    return usrl.parseManaged(tokens, self.allocator, &diag) catch |err| {
        switch (err) {
            error.USRLParseError => while (diag.pop()) |prob| {
                printParseProblem(prob, source, self.err) catch continue;
            },
            else => {
                const ansi = ANSI.init(self.err);
                ansi.print(eh, "SYNTAX ERROR: ", .{}) catch {};
                ansi.print(e, "Unexpected {t}\r\n", .{err}) catch {};
            },
        }
        return null;
    };
}

pub fn run(self: This, script: usrl.Script, proj: usrl.Project, out: *std.Io.Writer, source: Source) bool {
    var diag: usrl.RuntimeDiagnostics = .init(self.allocator);
    defer diag.deinit();

    usrl.run(script, self.allocator, &diag, .{
        .proj = proj,
        .out = out,
    }) catch |err| {
        switch (err) {
            error.USRLRuntimeError => while (diag.pop()) |prob| {
                printRuntimeProblem(prob, source, self.err) catch continue;
            },
            else => {
                const ansi = ANSI.init(self.err);
                ansi.print(eh, "RUNTIME ERROR: ", .{}) catch {};
                ansi.print(e, "Unexpected {t}\r\n", .{err}) catch {};
            },
        }
        return false;
    };
    return true;
}

pub fn printTokenizeProblem(prob: usrl.TokenizeProblem, source: Source, fw: *std.fs.File.Writer) std.Io.Writer.Error!void {
    var ansi = ANSI.init(fw);

    try ansi.print(eh, "SYNTAX ERROR: ", .{});
    try ansi.print(e, "{f}.\r\n", .{prob});
    try printLineHighlight(prob.loc(), source, fw);
    try fw.interface.flush();
}

pub fn printParseProblem(prob: usrl.ParseProblem, source: Source, fw: *std.fs.File.Writer) std.Io.Writer.Error!void {
    var ansi = ANSI.init(fw);

    try ansi.print(eh, "SYNTAX ERROR: ", .{});
    try ansi.print(e, "{f}.\r\n", .{prob});
    try printLineHighlight(prob.loc(), source, fw);
    try fw.interface.flush();
}

pub fn printRuntimeProblem(prob: usrl.RuntimeProblem, source: Source, fw: *std.fs.File.Writer) std.Io.Writer.Error!void {
    const ansi = ANSI.init(fw);

    try ansi.print(eh, "RUNTIME ERROR: ", .{});
    try ansi.print(e, "{f}.\r\n", .{prob});
    if (prob.loc()) |loc| try printLineHighlight(loc, source, fw);
    try fw.interface.flush();
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
    openURL("https://danielkmach.github.io/USRL");
}

/// Opens the given URL.
pub fn openURL(comptime url: []const u8) void {
    switch (builtin.os.tag) {
        .windows => {
            const windows = @cImport(@cInclude("windows.h"));
            _ = windows.ShellExecuteA(null, "open", url, null, null, windows.SW_SHOWNORMAL);
        },
        else => {
            const stdlib = @cImport(@cInclude("stdlib.h"));
            _ = stdlib.system("open " ++ url);
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
