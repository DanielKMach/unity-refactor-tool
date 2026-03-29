const std = @import("std");

const Glep = @This();

// usrl STMT STMT -c
// usrl -c STMT STMT
// usrl STMT -c STMT
// usrl STMT -o out.txt STMT
// usrl -f FILE FILE -o out.txt FILE
// usrl -f -o out.txt -c FILE FILE
// usrl -c -o out.txt --

args: []const [:0]u8,
claimed: []bool,

pub fn init(allocator: std.mem.Allocator) !Glep {
    const args = try std.process.argsAlloc(allocator);
    errdefer std.process.argsFree(allocator, args);

    return .{
        .args = args,
        .claimed = try allocator.alloc(bool, args.len),
    };
}

pub fn deinit(glep: *Glep, allocator: std.mem.Allocator) void {
    std.process.argsFree(allocator, glep.args);
    allocator.free(glep.claimed);
}

pub fn has(glep: *Glep, option: []const u8) bool {
    return for (glep.args, 0..) |arg, i| {
        if (glep.unclaimed(i) and std.mem.eql(u8, option, arg)) {
            _ = glep.claim(i);
            break true;
        }
    } else false;
}

pub fn get(glep: *Glep, option: []const u8) ?[:0]const u8 {
    var found = false;
    return for (glep.args, 0..) |arg, i| {
        if (glep.unclaimed(i)) {
            if (found) break glep.claim(i);
        } else {
            if (std.mem.eql(u8, option, arg)) found = true;
        }
    } else {
        std.debug.assert(found);
        return null;
    };
}

pub fn next(glep: *Glep) ?[:0]const u8 {
    return for (glep.args, 0..) |_, i| {
        if (glep.unclaimed(i)) break glep.claim(i);
    } else null;
}

pub fn peek(glep: Glep) ?[:0]const u8 {
    return for (glep.args, 0..) |arg, i| {
        if (glep.unclaimed(i)) break arg;
    } else null;
}

pub fn remaining(glep: Glep) usize {
    var count: usize = 0;
    for (glep.args, 0..) |_, i| {
        if (glep.unclaimed(i)) count += 1;
    }
    return count;
}

fn unclaimed(glep: Glep, i: usize) bool {
    return !glep.claimed[i];
}

fn claim(glep: *Glep, i: usize) [:0]const u8 {
    std.debug.assert(glep.unclaimed(i));
    glep.claimed[i] = true;
    return glep.args[i];
}
