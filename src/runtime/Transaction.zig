//! A struct responsible for managing the transaction lifecycle, including commit and rollback operations.

const std = @import("std");
const builtin = @import("builtin");
const config = @import("config");

const This = @This();
const log = std.log.scoped(.transaction);

pub const IncludeError = std.fs.File.OpenError || std.fs.File.WriteFileError || MakePathError || std.mem.Allocator.Error;
pub const GetTempError = std.fs.File.OpenError || MakePathError || std.mem.Allocator.Error;
pub const MakePathError = std.fs.Dir.RealPathError || std.mem.Allocator.Error;

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

pub fn include(self: *This, target: []const u8) IncludeError!void {
    if (self.backups.contains(target)) {
        return;
    }

    const target_path = try self.allocator.dupe(u8, target);
    errdefer self.allocator.free(target_path);
    const target_file = std.fs.openFileAbsolute(target_path, .{ .mode = .read_only }) catch |err| {
        log.err("Failed ({s}) to open target file: {s}", .{ @errorName(err), target_path });
        return err;
    };
    defer target_file.close();

    const backup_path = try self.makePath("{x}.usrlbackup", self.allocator);
    errdefer self.allocator.free(backup_path);
    const backup_file = std.fs.createFileAbsolute(backup_path, .{ .lock = .exclusive }) catch |err| {
        log.err("Failed ({s}) to create backup file: {s}", .{ @errorName(err), backup_path });
        return err;
    };
    errdefer std.fs.deleteFileAbsolute(backup_path) catch {};
    defer backup_file.close();

    backup_file.writeFileAll(target_file, .{}) catch |err| {
        log.err("Failed ({s}) to write backup file: {s}", .{ @errorName(err), backup_path });
        return err;
    };

    try self.backups.put(target_path, backup_path);
    log.info("Included '{s}' to the transaction. ({s})", .{ target_path, std.fs.path.basename(backup_path) });
}

pub fn commit(self: *This) void {
    log.info("Committing changes...", .{});
    self.eraseAndClearBackups();
}

pub fn rollback(self: *This) void {
    log.info("Rolling back changes...", .{});
    var iterator = self.backups.iterator();
    while (iterator.next()) |backup| {
        const original_path = backup.key_ptr.*;
        const backup_path = backup.value_ptr.*;

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
    self.eraseAndClearBackups();
}

pub fn getTemp(self: *This) GetTempError!std.fs.File {
    const temp_path = try self.makePath("{x}.usrltemp", self.allocator);
    errdefer self.allocator.free(temp_path);

    const file = std.fs.createFileAbsolute(temp_path, .{ .lock = .exclusive, .read = true }) catch |err| {
        log.err("Failed ({s}) to create temporary file: {s}", .{ @errorName(err), temp_path });
        return err;
    };
    errdefer std.fs.deleteFileAbsolute(temp_path) catch {};
    errdefer file.close();

    try self.temps.put(file, temp_path);
    return file;
}

pub fn delTemp(self: *This, file: std.fs.File) void {
    const temp_path = self.temps.get(file) orelse {
        log.err("Temporary file not found in transaction map.", .{});
        return;
    };

    file.close();
    if (!config.keep_temp) std.fs.deleteFileAbsolute(temp_path) catch |err| {
        log.err("Failed ({s}) to delete temporary file: {s}", .{ @errorName(err), temp_path });
    };
    _ = self.temps.remove(file);
    self.allocator.free(temp_path);
}

pub fn deinit(self: *This) void {
    if (self.temps.count() > 0) {
        log.warn("Transaction deinit called with uncleaned temporary files. Cleaning up...", .{});
        self.eraseAndClearTemps();
    }

    std.debug.assert(self.backups.count() == 0);
    self.backups.deinit();
}

fn eraseAndClearBackups(self: *This) void {
    var iterator = self.backups.iterator();
    while (iterator.next()) |entry| {
        const backup_path = entry.value_ptr.*;
        const original_path = entry.key_ptr.*;
        if (!config.keep_temp) {
            std.fs.deleteFileAbsolute(backup_path) catch |err| {
                log.warn("Failed ({s}) to delete transaction file: {s}", .{ @errorName(err), backup_path });
            };
        }
        self.allocator.free(backup_path);
        self.allocator.free(original_path);
    }
    self.backups.clearAndFree();
}

fn eraseAndClearTemps(self: *This) void {
    var iterator = self.temps.iterator();
    while (iterator.next()) |entry| {
        const file = entry.key_ptr.*;
        const path = entry.value_ptr.*;

        file.close();
        if (!config.keep_temp) std.fs.deleteFileAbsolute(path) catch |err| {
            log.warn("Failed ({s}) to delete temporary file: {s}", .{ @errorName(err), path });
        };
        self.allocator.free(path);
    }
    self.temps.clearAndFree();
}

fn makePath(self: *This, comptime filename_format: []const u8, allocator: std.mem.Allocator) MakePathError![]const u8 {
    var buf: [filename_format.len - 3 + 16]u8 = undefined; // -3 to remove the {x} tag, +16 because thats how many chars a u64 can have in hexdecimal.
    const file_name = std.fmt.bufPrint(&buf, filename_format, .{self.rand.next()}) catch unreachable; // We just counted the precise amount.
    return try makeAbsPath(file_name, allocator);
}

fn makeAbsPath(file_name: []const u8, allocator: std.mem.Allocator) MakePathError![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const dir_path = try std.fs.cwd().realpath(".", &buf);
    return try std.fs.path.join(allocator, &.{ dir_path, file_name });
}
