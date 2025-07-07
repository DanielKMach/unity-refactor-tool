//! A struct responsible for managing the transaction lifecycle, including commit and rollback operations.

const std = @import("std");
const builtin = @import("builtin");

const This = @This();
const log = std.log.scoped(.transaction);

allocator: std.mem.Allocator,
backups: std.StringHashMap([]const u8),
temps: std.AutoHashMap(std.fs.File, []const u8),
id: u64,
rand: std.Random.Xoshiro256,

pub fn init(allocator: std.mem.Allocator) This {
    const id: u64 = @intCast(std.time.microTimestamp());
    return This{
        .allocator = allocator,
        .backups = .init(allocator),
        .temps = .init(allocator),
        .rand = .init(id),
        .id = id,
    };
}

pub fn include(self: *This, target: []const u8) !void {
    if (self.backups.contains(target)) {
        return;
    }

    const target_path = try self.allocator.dupe(u8, target);
    const target_file = std.fs.openFileAbsolute(target_path, .{ .mode = .read_only }) catch |err| {
        log.err("Failed ({s}) to open target file: {s}", .{ @errorName(err), target_path });
        return err;
    };
    defer target_file.close();

    const backup_path = try self.makePath("{x}.usrlbackup", self.allocator);
    const backup_file = std.fs.createFileAbsolute(backup_path, .{ .lock = .exclusive }) catch |err| {
        log.err("Failed ({s}) to create backup file: {s}", .{ @errorName(err), backup_path });
        return err;
    };
    defer backup_file.close();

    backup_file.writeFileAll(target_file, .{}) catch |err| {
        log.err("Failed ({s}) to write backup file: {s}", .{ @errorName(err), backup_path });
        return err;
    };

    try self.backups.put(target_path, backup_path);
    log.info("Included '{s}' to the transaction. ({s})", .{ target_path, std.fs.path.basename(backup_path) });
}

pub fn commit(self: *This) !void {
    log.info("Committing changes...", .{});
    try self.eraseBackups();
}

pub fn rollback(self: *This) !void {
    log.info("Rolling back changes...", .{});
    var iterator = self.backups.iterator();
    while (iterator.next()) |backup| {
        const backup_path = backup.key_ptr.*;
        const original_path = backup.value_ptr.*;

        const backup_file = std.fs.openFileAbsolute(backup_path, .{ .mode = .read_only }) catch |err| {
            log.err("Failed ({s}) to open backup file: {s}", .{ @errorName(err), backup_path });
            continue;
        };
        defer backup_file.close();

        const original_file = std.fs.openFileAbsolute(original_path, .{ .mode = .read_write }) catch |err| {
            log.err("Failed ({s}) to open original file: {s}", .{ @errorName(err), original_path });
            continue;
        };
        defer original_file.close();

        original_file.writeFileAll(backup_file, .{}) catch |err| {
            log.err("Failed ({s}) to restore backup file: {s} to original file: {s}", .{ @errorName(err), backup_path, original_path });
        };
    }
    try self.eraseBackups();
}

pub fn getTemp(self: *This) !std.fs.File {
    const temp_path = try self.makePath("{x}.usrltemp", self.allocator);

    const file = std.fs.createFileAbsolute(temp_path, .{ .lock = .exclusive, .read = true }) catch |err| {
        log.err("Failed ({s}) to create temporary file: {s}", .{ @errorName(err), temp_path });
        return err;
    };

    try self.temps.put(file, temp_path);
    return file;
}

pub fn delTemp(self: *This, file: std.fs.File) void {
    const temp_path = self.temps.get(file) orelse {
        log.err("Temporary file not found in transaction map.", .{});
        return;
    };

    file.close();
    std.fs.deleteFileAbsolute(temp_path) catch |err| {
        log.err("Failed ({s}) to delete temporary file: {s}", .{ @errorName(err), temp_path });
    };
    _ = self.temps.remove(file);
    self.allocator.free(temp_path);
}

pub fn deinit(self: *This) void {
    if (self.temps.count() > 0) {
        log.warn("Transaction deinit called with uncleaned temporary files. Cleaning up...", .{});
        var iterator = self.temps.iterator();
        while (iterator.next()) |entry| {
            entry.key_ptr.close();
            std.fs.deleteFileAbsolute(entry.value_ptr.*) catch |err| {
                log.err("Failed ({s}) to delete temporary file: {s}", .{ @errorName(err), entry.value_ptr.* });
            };
            self.allocator.free(entry.value_ptr.*);
        }
        self.temps.clearAndFree();
    }

    std.debug.assert(self.backups.count() == 0);
    self.backups.deinit();
}

fn eraseBackups(self: *This) !void {
    var iterator = self.backups.valueIterator();
    while (iterator.next()) |backup| {
        log.debug("Erasing '{s}'", .{backup.*});
        try std.fs.deleteFileAbsolute(backup.*);
    }
    self.clearBackups();
}

fn clearBackups(self: *This) void {
    var iterator = self.backups.iterator();
    while (iterator.next()) |backup| {
        self.allocator.free(backup.key_ptr.*);
        self.allocator.free(backup.value_ptr.*);
    }
    self.backups.clearAndFree();
}

fn makePath(self: *This, comptime filename_format: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const file_name = try std.fmt.allocPrint(allocator, filename_format, .{self.rand.next()});
    defer allocator.free(file_name);
    return try makeAbsPath(file_name, allocator);
}

fn makeAbsPath(file_name: []const u8, allocator: std.mem.Allocator) ![]const u8 {
    const dir_path = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(dir_path);
    return try std.fs.path.join(allocator, &.{ dir_path, file_name });
}
