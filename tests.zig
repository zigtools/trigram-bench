const std = @import("std");
const common = @import("common.zig");

pub fn tests(allocator: std.mem.Allocator, index: common.Index, query: anytype) !void {
    const results = (try query(allocator, index, &.{
        common.Trigram.fromAscii("4X3".*),
        common.Trigram.fromAscii("X32".*),
        common.Trigram.fromAscii("32_".*),
        common.Trigram.fromAscii("2_1".*),
    })).?;
    defer allocator.free(results);

    std.debug.assert(results.len == 1);
    std.debug.assert(std.mem.eql(u8, index.declarations[results[0]], "DML_RANDOM_GENERATOR_TYPE_PHILOX_4X32_10"));
}
