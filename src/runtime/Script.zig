const std = @import("std");
const core = @import("root");

statements: []core.stmt.Statement,

pub fn run(this: *const @This(), data: core.runtime.RuntimeData) !core.results.RuntimeResult(void) {
    core.profiling.begin(run);
    defer core.profiling.stop();

    for (this.statements) |stmt| {
        const result = try stmt.run(data);
        switch (result) {
            .ok => {},
            .err => |err| return .ERR(err),
        }
    }
    return .OK(void{});
}
