const std = @import("std");
const common = @import("common.zig");
const Allocator = std.mem.Allocator;
const tests = @import("tests.zig").tests;
const BinnedAllocator = @import("binned_allocator.zig").BinnedAllocator;

pub fn main() !void {
    var binned_allocator = BinnedAllocator(.{}){};
    defer binned_allocator.deinit();
    const allocator = binned_allocator.allocator();

    var index = try common.Index.init(allocator);
    defer index.deinit(allocator);

    try tests(allocator, index, query);
}

pub fn query(allocator: std.mem.Allocator, index: common.Index, trigrams: []const common.Trigram) Allocator.Error!?[]const u32 {
    std.debug.assert(trigrams.len != 0);

    var results = std.ArrayListUnmanaged(u32){};
    var match_map = std.AutoHashMapUnmanaged(u32, void){};
    defer match_map.deinit(allocator);

    try results.appendSlice(allocator, (index.trigram_to_decls.get(trigrams[0]) orelse return null).items);

    for (trigrams[1..]) |trigram| {
        const decls = index.trigram_to_decls.get(trigram) orelse return null;

        try match_map.ensureTotalCapacity(allocator, @intCast(decls.items.len));
        for (decls.items) |decl| {
            match_map.putAssumeCapacity(decl, {});
        }

        var result_index: usize = 0;
        while (result_index < results.items.len) {
            if (!match_map.contains(results.items[result_index])) {
                _ = results.swapRemove(result_index);
            } else {
                result_index += 1;
            }
        }

        match_map.clearRetainingCapacity();
    }

    return try results.toOwnedSlice(allocator);
}
