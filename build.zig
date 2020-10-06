const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("ctradix", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const bench = b.addExecutable("bench", "src/bench.zig");
    bench.setBuildMode(.ReleaseFast);
    const run_step = bench.run();

    const bench_step = b.step("bench", "Runs the benchmark");
    bench_step.dependOn(&run_step.step);
}
