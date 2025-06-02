const std = @import("std");
const core = @import("root");
const results = core.results;

const This = @This();
const RuntimeEnv = core.runtime.RuntimeEnv;
const Tokenizer = core.language.Tokenizer;

dir: []const u8,

pub const default: This = .{ .dir = "." };

pub fn parse(tokens: *Tokenizer.TokenIterator) !results.ParseResult(This) {
    core.profiling.begin(parse);
    defer core.profiling.stop();

    if (tokens.next()) |tkn| {
        if (!tkn.is(.keyword, "IN")) {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .keyword,
                    .expected_value = "IN",
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .keyword,
                .expected_value = "IN",
            },
        });
    }

    var dir: []const u8 = undefined;
    if (tokens.next()) |tkn| {
        if (tkn.isType(.string)) {
            dir = tkn.value;
        } else {
            return .ERR(.{
                .unexpected_token = .{
                    .found = tkn,
                    .expected_type = .string,
                },
            });
        }
    } else {
        return .ERR(.{
            .unexpected_eof = .{
                .expected_type = .string,
            },
        });
    }

    return .OK(.{ .dir = dir });
}

pub fn openDir(self: This, data: RuntimeEnv, options: std.fs.Dir.OpenDirOptions) !std.fs.Dir {
    const dir = try data.cwd.openDir(self.dir, options);
    return dir;
}
