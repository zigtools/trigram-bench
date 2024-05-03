const std = @import("std");
const common = @import("common.zig");
const Allocator = std.mem.Allocator;
const tests = @import("tests.zig").tests;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var index = try common.Index.init(allocator);
    defer index.deinit(allocator);

    try tests(allocator, index, query);
}

pub fn query(allocator: std.mem.Allocator, index: common.Index, trigrams: []const common.Trigram) Allocator.Error!?[]const u32 {
    std.debug.assert(trigrams.len != 0);

    const first = (index.trigram_to_decls.get(trigrams[0]) orelse return null).items;

    var buffer = try std.ArrayListUnmanaged(u32).initCapacity(allocator, first.len * 2);
    buffer.items.len = first.len * 2;

    var len = first.len;

    @memcpy(buffer.items[len..], first);

    for (trigrams[1..]) |trigram| {
        len = mergeIntersection((index.trigram_to_decls.get(trigram) orelse return null).items, buffer.items[len..], buffer.items[0..len]);
        buffer.items.len = len * 2;
        @memcpy(buffer.items[len..], buffer.items[0..len]);
    }

    buffer.items.len = buffer.items.len / 2;
    return try buffer.toOwnedSlice(allocator);
}

/// Asserts `@min(a.len, b.len) <= out.len`.
pub fn mergeIntersection(a: []const u32, b: []const u32, out: []u32) u32 {
    std.debug.assert(@min(a.len, b.len) <= out.len);

    var out_idx: u32 = 0;

    var a_idx: u32 = 0;
    var b_idx: u32 = 0;

    while (a_idx < a.len and b_idx < b.len) {
        const a_val = a[a_idx];
        const b_val = b[b_idx];

        if (a_val == b_val) {
            out[out_idx] = a_val;
            out_idx += 1;
            a_idx += 1;
            b_idx += 1;
        } else if (a_val < b_val) {
            a_idx += 1;
        } else {
            b_idx += 1;
        }
    }

    return out_idx;
}
