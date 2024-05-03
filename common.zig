const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Trigram = packed struct(u64) {
    codepoint_0: u21,
    codepoint_1: u21,
    codepoint_2: u21,
    padding: u1 = 0,

    pub fn fromAscii(val: [3]u8) Trigram {
        return .{
            .codepoint_0 = val[0],
            .codepoint_1 = val[1],
            .codepoint_2 = val[2],
        };
    }

    pub fn format(value: Trigram, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt; // autofix
        _ = options; // autofix

        inline for (.{ value.codepoint_0, value.codepoint_1, value.codepoint_2 }) |cp| {
            var buf: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(cp, &buf);
            try writer.writeAll(buf[0..len]);
        }
    }
};

pub const Index = struct {
    pub const TrigramToDecls = std.AutoArrayHashMapUnmanaged(Trigram, std.ArrayListUnmanaged(u32));

    declarations: []const []const u8,
    trigram_to_decls: TrigramToDecls,

    pub fn init(allocator: Allocator) (Allocator.Error || std.fs.File.OpenError || std.fs.File.ReadError || std.fs.File.SeekError)!Index {
        var declarations = std.ArrayListUnmanaged([]const u8){};
        var trigram_to_decls = TrigramToDecls{};

        const file = try std.fs.cwd().readFileAlloc(allocator, "symbols.txt", std.math.maxInt(usize));
        defer allocator.free(file);

        var it = std.mem.splitScalar(u8, file, '\n');

        var decl: u32 = 0;
        while (it.next()) |symbol| {
            if (symbol.len < 3) continue;

            try declarations.append(allocator, try allocator.dupe(u8, symbol));
            try trigram_to_decls.ensureUnusedCapacity(allocator, symbol.len - 2);

            const view = try std.unicode.Utf8View.init(symbol);

            var iterator = view.iterator();
            while (iterator.nextCodepoint()) |codepoint_0| {
                const next_idx = iterator.i;
                const codepoint_1 = iterator.nextCodepoint() orelse break;
                const codepoint_2 = iterator.nextCodepoint() orelse break;

                const gop = trigram_to_decls.getOrPutAssumeCapacity(.{
                    .codepoint_0 = codepoint_0,
                    .codepoint_1 = codepoint_1,
                    .codepoint_2 = codepoint_2,
                });

                if (!gop.found_existing) gop.value_ptr.* = .{};

                try gop.value_ptr.*.append(allocator, decl);

                iterator.i = next_idx;
            }

            decl += 1;
        }

        return .{ .declarations = try declarations.toOwnedSlice(allocator), .trigram_to_decls = trigram_to_decls };
    }

    pub fn deinit(index: *Index, allocator: Allocator) void {
        for (index.declarations) |v| {
            allocator.free(v);
        }
        allocator.free(index.declarations);

        for (index.trigram_to_decls.values()) |*v| {
            v.deinit(allocator);
        }
        index.trigram_to_decls.deinit(allocator);
        index.* = undefined;
    }
};
