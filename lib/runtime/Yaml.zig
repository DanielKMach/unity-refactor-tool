const std = @import("std");
const ly = @import("libyaml");
const log = std.log.scoped(.yaml);

const This = @This();

pub const Parser = ly.yaml_parser_t;
pub const Emitter = ly.yaml_emitter_t;
pub const Event = ly.yaml_event_t;
pub const Document = ly.yaml_document_t;

const c_alloc = std.heap.raw_c_allocator;

pub const LibyamlError = error{LibyamlError};
pub const OutputError = error{NoOutput} || std.mem.Allocator.Error;
pub const ParseError = LibyamlError || std.mem.Allocator.Error;
pub const UpdateError = ParseError || OutputError;

in: In,
out: ?Out,
allocator: std.mem.Allocator,

pub fn init(in: In, out: ?Out, allocator: std.mem.Allocator) This {
    const self = This{
        .in = in,
        .out = out,
        .allocator = allocator,
    };

    return self;
}

pub fn rename(self: *This, old_scalar: []const u8, new_scalar: []const u8) UpdateError!void {
    const parser = try self.getParser();
    defer self.closeParser(parser);

    const emitter = try self.getEmitter();
    defer self.closeEmitter(emitter);

    var events = newEventsList();
    defer deleteEventsList(self.allocator, &events);

    var event: *Event = undefined;
    var done: bool = false;
    var level: usize = 0;
    while (!done) {
        event = try events.addOne(self.allocator);
        try parse(parser, event);
        if (event.type == ly.YAML_MAPPING_START_EVENT) {
            level += 1;
        } else if (event.type == ly.YAML_MAPPING_END_EVENT) {
            level -= 1;
        }

        if (level == 2 and event.type == ly.YAML_SCALAR_EVENT and std.mem.eql(u8, event.data.scalar.value[0..event.data.scalar.length], old_scalar)) {
            const len = new_scalar.len;
            const buf = try c_alloc.dupeZ(u8, new_scalar);
            c_alloc.free(event.data.scalar.value[0..event.data.scalar.length]);
            event.data.scalar.value = buf.ptr;
            event.data.scalar.length = len;
        }

        try emit(emitter, event);

        done = event.type == ly.YAML_STREAM_END_EVENT;
    }

    _ = ly.yaml_emitter_flush(emitter);
}

pub fn getAlloc(self: *This, path: []const []const u8, allocator: std.mem.Allocator) ParseError!?[]u8 {
    const parser = try self.getParser();
    defer self.closeParser(parser);

    for (path) |key| {
        if (!try runTo(parser, key)) return null;
    }

    var event: Event = undefined;
    try parse(parser, &event);
    defer ly.yaml_event_delete(&event);

    if (event.type != ly.YAML_SCALAR_EVENT) {
        return null;
    }

    return try allocator.dupe(u8, event.data.scalar.value[0..event.data.scalar.length]);
}

pub fn get(self: *This, path: []const []const u8, buf: []u8) ParseError!?[]u8 {
    const parser = try self.getParser();
    defer self.closeParser(parser);

    for (path) |key| {
        if (!try runTo(parser, key)) return null;
    }

    var event: Event = undefined;
    try parse(parser, &event);
    defer ly.yaml_event_delete(&event);

    if (event.type != ly.YAML_SCALAR_EVENT) {
        return null;
    }

    const length = @min(buf.len, event.data.scalar.length);
    @memcpy(buf[0..length], event.data.scalar.value[0..length]);
    return buf[0..length];
}

pub fn loadDocument(self: *This, document: *Document) ParseError!void {
    const parser = try self.getParser();
    defer self.closeParser(parser);

    if (ly.yaml_parser_load(parser, document) == 0) return error.LibyamlError;
}

pub fn dumpDocument(self: *This, document: *Document) UpdateError!void {
    const emitter = try self.getEmitter();
    defer self.closeEmitter(emitter);

    if (ly.yaml_emitter_dump(emitter, document) == 0) return error.LibyamlError;
    if (ly.yaml_emitter_flush(emitter) == 0) return error.LibyamlError;
}

pub fn deleteDocument(document: *Document) void {
    ly.yaml_document_delete(@ptrCast(document));
}

fn runTo(parser: *Parser, key: []const u8) ParseError!bool {
    var event: Event = undefined;
    var level: usize = 0;

    while (true) {
        try parse(parser, &event);
        defer ly.yaml_event_delete(&event);

        if (event.type == ly.YAML_STREAM_END_EVENT) {
            break;
        }

        if (event.type == ly.YAML_MAPPING_START_EVENT) {
            level += 1;
        } else if (event.type == ly.YAML_MAPPING_END_EVENT) {
            level -= 1;
        }

        if (level == 1 and event.type == ly.YAML_SCALAR_EVENT and std.mem.eql(u8, event.data.scalar.value[0..event.data.scalar.length], key)) {
            return true;
        }
    }

    return false;
}

fn parse(parser: *Parser, event: *Event) LibyamlError!void {
    if (ly.yaml_parser_parse(parser, event) == 0) {
        return error.LibyamlError;
    }
}

fn emit(emitter: *Emitter, event: *Event) LibyamlError!void {
    if (ly.yaml_emitter_emit(emitter, event) == 0) {
        return error.LibyamlError;
    }
}

fn getParser(self: *This) ParseError!*Parser {
    const parser = try self.allocator.create(Parser);
    errdefer self.allocator.destroy(parser);

    const result = ly.yaml_parser_initialize(parser);
    if (result == 0) return error.LibyamlError;

    switch (self.in) {
        .string => |str| ly.yaml_parser_set_input_string(parser, str.ptr, str.len),
        .reader => |reader| ly.yaml_parser_set_input(parser, &readHandler, @ptrCast(reader)),
    }

    return parser;
}

fn closeParser(self: *This, parser: *Parser) void {
    ly.yaml_parser_delete(parser);
    self.allocator.destroy(parser);
}

fn getEmitter(self: *This) UpdateError!*Emitter {
    const emitter = try self.allocator.create(Emitter);
    errdefer self.allocator.destroy(emitter);

    const result = ly.yaml_emitter_initialize(emitter);
    if (result == 0) return error.LibyamlError;

    ly.yaml_emitter_set_encoding(emitter, ly.YAML_UTF8_ENCODING);
    ly.yaml_emitter_set_width(emitter, std.math.maxInt(c_int));

    if (self.out) |*out| switch (out.*) {
        .string => |str| ly.yaml_emitter_set_output_string(emitter, str.ptr, str.len, &str.len),
        .writer => |writer| ly.yaml_emitter_set_output(emitter, &writeHandler, @ptrCast(writer)),
    } else {
        return error.NoOutput;
    }

    return emitter;
}

fn closeEmitter(self: *This, emitter: *Emitter) void {
    ly.yaml_emitter_delete(emitter);
    self.allocator.destroy(emitter);
}

fn newEventsList() std.SegmentedList(Event, 32) {
    return std.SegmentedList(Event, 32){};
}

fn deleteEventsList(allocator: std.mem.Allocator, events: *std.SegmentedList(Event, 32)) void {
    // var iterator = events.iterator(0);
    // while (iterator.next()) |event| {
    //     libyaml.yaml_event_delete(event);
    // }
    events.deinit(allocator);
}

fn readHandler(context: ?*anyopaque, buffer: [*c]u8, size: usize, length: [*c]usize) callconv(.c) c_int {
    const reader: *std.Io.Reader = @ptrCast(@alignCast(context.?));
    length.* = reader.readSliceShort(buffer[0..size]) catch return 0;
    return 1;
}

fn writeHandler(context: ?*anyopaque, buffer: [*c]u8, size: usize) callconv(.c) c_int {
    const writer: *std.Io.Writer = @ptrCast(@alignCast(context.?));
    writer.writeAll(buffer[0..size]) catch return 0;
    return 1;
}

pub const In = union(enum) {
    string: []const u8,
    reader: *std.Io.Reader,
};

pub const Out = union(enum) {
    string: *[]u8,
    writer: *std.Io.Writer,
};
