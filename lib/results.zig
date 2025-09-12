const std = @import("std");
const core = @import("core");

pub fn Result(T: type, E: type) type {
    return union(enum) {
        pub const Type = @typeInfo(This).@"union".tag_type orelse unreachable;

        const This = @This();

        ok: T,
        err: E,

        pub fn OK(okv: T) This {
            return .{ .ok = okv };
        }

        pub fn ERR(errv: E) This {
            return .{ .err = errv };
        }

        pub fn isOk(self: This) ?T {
            return if (self == .ok) self.ok else null;
        }

        pub fn isErr(self: This) ?E {
            return if (self == .err) self.err else null;
        }
    };
}
