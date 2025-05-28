const std = @import("std");
const libyaml = @import("libyaml");
const log = std.log.scoped(.yaml);

const This = @This();

const Parser = libyaml.yaml_parser_t;
const Emitter = libyaml.yaml_emitter_t;
const Event = libyaml.yaml_event_t;
const parser_init = libyaml.yaml_parser_initialize;
const parser_parse = libyaml.yaml_parser_parse;
const parser_deinit = libyaml.yaml_parser_delete;
const emitter_init = libyaml.yaml_emitter_initialize;
const emitter_emit = libyaml.yaml_emitter_emit;
const emitter_deinit = libyaml.yaml_emitter_delete;
const event_deinit = libyaml.yaml_event_delete;

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
        if (event.type == libyaml.YAML_MAPPING_START_EVENT) {
            level += 1;
        } else if (event.type == libyaml.YAML_MAPPING_END_EVENT) {
            level -= 1;
        }

        if (level == 2 and event.type == libyaml.YAML_SCALAR_EVENT and std.mem.eql(u8, event.data.scalar.value[0..event.data.scalar.length], old_scalar)) {
            const len = new_scalar.len;
            const buf = try c_alloc.dupeZ(u8, new_scalar);
            c_alloc.free(event.data.scalar.value[0..event.data.scalar.length]);
            event.data.scalar.value = buf.ptr;
            event.data.scalar.length = len;
        }

        try emit(emitter, event);

        done = event.type == libyaml.YAML_STREAM_END_EVENT;
    }

    _ = libyaml.yaml_emitter_flush(emitter);
}

pub fn getAlloc(self: *This, path: []const []const u8, allocator: std.mem.Allocator) ParseError!?[]u8 {
    const parser = try self.getParser();
    defer self.closeParser(parser);

    for (path) |key| {
        if (!try runTo(parser, key)) return null;
    }

    var event: Event = undefined;
    try parse(parser, &event);
    defer event_deinit(&event);

    if (event.type != libyaml.YAML_SCALAR_EVENT) {
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
    defer event_deinit(&event);

    if (event.type != libyaml.YAML_SCALAR_EVENT) {
        return null;
    }

    const length = @min(buf.len, event.data.scalar.length);
    @memcpy(buf[0..length], event.data.scalar.value[0..length]);
    return buf[0..length];
}

fn runTo(parser: *Parser, key: []const u8) ParseError!bool {
    var event: Event = undefined;
    var level: usize = 0;

    while (true) {
        try parse(parser, &event);
        defer event_deinit(&event);

        if (event.type == libyaml.YAML_STREAM_END_EVENT) {
            break;
        }

        if (event.type == libyaml.YAML_MAPPING_START_EVENT) {
            level += 1;
        } else if (event.type == libyaml.YAML_MAPPING_END_EVENT) {
            level -= 1;
        }

        if (level == 1 and event.type == libyaml.YAML_SCALAR_EVENT and std.mem.eql(u8, event.data.scalar.value[0..event.data.scalar.length], key)) {
            return true;
        }
    }

    return false;
}

fn parse(parser: *Parser, event: *Event) LibyamlError!void {
    if (libyaml.yaml_parser_parse(parser, event) == 0) {
        return error.LibyamlError;
    }
}

fn emit(emitter: *Emitter, event: *Event) LibyamlError!void {
    if (libyaml.yaml_emitter_emit(emitter, event) == 0) {
        return error.LibyamlError;
    }
}

fn getParser(self: *This) ParseError!*Parser {
    const parser = try self.allocator.create(Parser);
    errdefer self.allocator.destroy(parser);

    const result = parser_init(parser);
    if (result == 0) return error.LibyamlError;

    switch (self.in) {
        .string => |str| libyaml.yaml_parser_set_input_string(parser, str.ptr, str.len),
        .reader => |*reader| libyaml.yaml_parser_set_input(parser, &readHandler, @ptrCast(reader)),
    }

    return parser;
}

fn closeParser(self: *This, parser: *Parser) void {
    parser_deinit(parser);
    self.allocator.destroy(parser);
}

fn getEmitter(self: *This) UpdateError!*Emitter {
    const emitter = try self.allocator.create(Emitter);
    errdefer self.allocator.destroy(emitter);

    const result = emitter_init(emitter);
    if (result == 0) return error.LibyamlError;

    libyaml.yaml_emitter_set_encoding(emitter, libyaml.YAML_UTF8_ENCODING);
    libyaml.yaml_emitter_set_width(emitter, std.math.maxInt(c_int));

    if (self.out) |*out| switch (out.*) {
        .string => |str| libyaml.yaml_emitter_set_output_string(emitter, str.ptr, str.len, &str.len),
        .writer => |*writer| libyaml.yaml_emitter_set_output(emitter, &writeHandler, @ptrCast(writer)),
    } else {
        return error.NoOutput;
    }

    return emitter;
}

fn closeEmitter(self: *This, emitter: *Emitter) void {
    emitter_deinit(emitter);
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

fn readHandler(context: ?*anyopaque, buffer: [*c]u8, size: usize, length: [*c]usize) callconv(.C) c_int {
    const reader: *std.io.AnyReader = @alignCast(@ptrCast(context.?));
    const read = reader.read(buffer[0..size]);
    if (read) |count| {
        length.* = count;
        return 1;
    } else |_| {
        return 0;
    }
}

fn writeHandler(context: ?*anyopaque, buffer: [*c]u8, size: usize) callconv(.C) c_int {
    const writer: *std.io.AnyWriter = @alignCast(@ptrCast(context.?));
    const write = writer.write(buffer[0..size]);
    if (write) |_| {
        return 1;
    } else |_| {
        return 0;
    }
}

pub const In = union(enum) {
    string: []const u8,
    reader: std.io.AnyReader,
};

pub const Out = union(enum) {
    string: *[]u8,
    writer: std.io.AnyWriter,
};
