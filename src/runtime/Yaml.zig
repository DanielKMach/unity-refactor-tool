const std = @import("std");
const libyaml = @cImport(@cInclude("yaml.h"));

const This = @This();

const c_alloc = std.heap.raw_c_allocator;

const OutputError = error{NoOutput} || std.mem.Allocator.Error;
const ParseError = error{InvalidYaml} || std.mem.Allocator.Error;
const UpdateError = ParseError || OutputError;

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

    var event: *libyaml.yaml_event_t = undefined;
    var done: bool = false;
    var level: usize = 0;
    while (!done) {
        event = try events.addOne(self.allocator);
        if (libyaml.yaml_parser_parse(parser, event) == 0) {
            return error.InvalidYaml;
        }
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

        if (libyaml.yaml_emitter_emit(emitter, event) == 0) {
            break;
        }

        done = event.type == libyaml.YAML_STREAM_END_EVENT;
    }

    _ = libyaml.yaml_emitter_flush(emitter);
}

pub fn matchGUID(self: *This, guid: []const u8) ParseError!bool {
    const parser = try self.getParser();
    defer self.closeParser(parser);

    if (!try runTo(parser, "MonoBehaviour")) return false;
    if (!try runTo(parser, "m_Script")) return false;
    if (!try runTo(parser, "guid")) return false;

    var event: libyaml.yaml_event_t = undefined;
    if (libyaml.yaml_parser_parse(parser, &event) == 0) {
        return error.InvalidYaml;
    }
    defer libyaml.yaml_event_delete(&event);

    if (event.type != libyaml.YAML_SCALAR_EVENT) {
        return false;
    }

    return std.mem.eql(u8, event.data.scalar.value[0..event.data.scalar.length], guid);
}

fn runTo(parser: *libyaml.yaml_parser_t, key: []const u8) ParseError!bool {
    var event = libyaml.yaml_event_t{};
    var level: usize = 0;

    while (event.type != libyaml.YAML_STREAM_END_EVENT) {
        if (libyaml.yaml_parser_parse(parser, &event) == 0) {
            return error.InvalidYaml;
        }
        defer libyaml.yaml_event_delete(&event);

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

fn getParser(self: *This) std.mem.Allocator.Error!*libyaml.yaml_parser_t {
    const parser = try self.allocator.create(libyaml.yaml_parser_t);
    errdefer self.allocator.destroy(parser);

    const result = libyaml.yaml_parser_initialize(parser);
    if (result == 0) return error.OutOfMemory;

    switch (self.in) {
        .string => |str| libyaml.yaml_parser_set_input_string(parser, str.ptr, str.len),
        .reader => |*reader| libyaml.yaml_parser_set_input(parser, &readHandler, @ptrCast(reader)),
    }

    return parser;
}

fn closeParser(self: *This, parser: *libyaml.yaml_parser_t) void {
    libyaml.yaml_parser_delete(parser);
    self.allocator.destroy(parser);
}

fn getEmitter(self: *This) OutputError!*libyaml.yaml_emitter_t {
    const emitter = try self.allocator.create(libyaml.yaml_emitter_t);
    errdefer self.allocator.destroy(emitter);

    const result = libyaml.yaml_emitter_initialize(emitter);
    if (result == 0) return error.OutOfMemory;

    libyaml.yaml_emitter_set_encoding(emitter, libyaml.YAML_UTF8_ENCODING);

    if (self.out) |*out| switch (out.*) {
        .string => |str| libyaml.yaml_emitter_set_output_string(emitter, str.ptr, str.len, &str.len),
        .writer => |*writer| libyaml.yaml_emitter_set_output(emitter, &writeHandler, @ptrCast(writer)),
    } else {
        return error.NoOutput;
    }

    return emitter;
}

fn closeEmitter(self: *This, emitter: *libyaml.yaml_emitter_t) void {
    libyaml.yaml_emitter_delete(emitter);
    self.allocator.destroy(emitter);
}

fn newEventsList() std.SegmentedList(libyaml.yaml_event_t, 32) {
    return std.SegmentedList(libyaml.yaml_event_t, 32){};
}

fn deleteEventsList(allocator: std.mem.Allocator, events: *std.SegmentedList(libyaml.yaml_event_t, 32)) void {
    // var iterator = events.iterator(0);
    // while (iterator.next()) |event| {
    //     libyaml.yaml_event_delete(event);
    // }
    events.deinit(allocator);
}

fn readHandler(ext: ?*anyopaque, buffer: [*c]u8, size: usize, length: [*c]usize) callconv(.C) c_int {
    const reader: *std.io.AnyReader = @alignCast(@ptrCast(ext.?));
    const read = reader.read(buffer[0..size]);
    if (read) |count| {
        length.* = count;
        return 0;
    } else |_| {
        return 1;
    }
}

fn writeHandler(ext: ?*anyopaque, buffer: [*c]u8, size: usize) callconv(.C) c_int {
    const writer: *std.io.AnyWriter = @alignCast(@ptrCast(ext.?));
    const write = writer.write(buffer[0..size]);
    if (write) |_| {
        return 0;
    } else |_| {
        return 1;
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
