pub inline fn hasFn(comptime T: type, comptime name: []const u8, comptime Fn: type) bool {
    return @hasDecl(T, name) and @TypeOf(@field(T, name)) == Fn;
}
