const std = @import("std");

const solutions = .{ "merge", "hashmap" };

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var artifacts = std.ArrayListUnmanaged(*std.Build.Step.Compile){};

    inline for (solutions) |solution| {
        const exe = b.addExecutable(.{
            .name = solution,
            .root_source_file = b.path("src/" ++ solution ++ ".zig"),
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibC();
        artifacts.append(b.allocator, exe) catch @panic("OOM");

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const run_step = b.step(solution, "Run " ++ solution);
        run_step.dependOn(&run_cmd.step);
    }

    const bench_system_command_step = b.addSystemCommand(&.{ "hyperfine", "--warmup", "3", "--runs", "250" });
    for (artifacts.items) |artifact| {
        bench_system_command_step.addArtifactArg(artifact);
    }

    const bench_step = b.step("bench", "Hyperfine benchmarks");
    bench_step.dependOn(&bench_system_command_step.step);
}
