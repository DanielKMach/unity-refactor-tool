const core = @import("core");

const This = @This();

token: core.Token,

pub fn init(token: core.Token) This {
    return .{ .token = token };
}
