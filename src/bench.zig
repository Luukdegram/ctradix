const std = @import("std");
const testing = std.testing;
const Timer = std.time.Timer;
const log = std.log.scoped(.bench);

const words = @embedFile("testdata/words.txt");
const gpa = testing.allocator;

pub fn main() !void {
    comptime var radix = @import("main.zig").StringRadixTree(u32){};
    comptime {
        @setEvalBranchQuota(10_000);
        comptime var index: usize = 0;
        comptime var count: u32 = 0;

        for (words) |c, i| {
            if (c == '\n') {
                _ = radix.insert(words[index..i], count);
                count += 1;
                index = i + 1;
            }
        }
        _ = radix.insert(words[index..], count);
    }

    var map = std.StringHashMap(u32).init(gpa);
    var array_map = std.StringArrayHashMap(u32).init(gpa);
    var map_results: [3]u64 = undefined;
    var array_map_results: [3]u64 = undefined;
    var radix_results: [3]u64 = undefined;

    const loops = 50_000;

    defer map.deinit();

    var it = std.mem.split(words, "\n");
    var i: u32 = 0;
    while (it.next()) |val| : (i += 1) {
        try map.putNoClobber(val, i);
        try array_map.putNoClobber(val, i);
    }

    log.alert("Start benching {} words\t[0]\t[1]\t[2]", .{i});
    std.debug.assert(radix.size == i);

    for (map_results) |*r| {
        var timer = try Timer.start();
        for (@as([loops]u8, undefined)) |_| {
            it.index = 0;
            while (it.next()) |val| {
                _ = map.get(val).?;
            }
        }
        r.* = timer.read();
    }

    log.alert("StringHashMap\t\t{:0>4}ms\t{:0>4}ms\t{:0>4}ms", .{
        map_results[0] / 1_000_000,
        map_results[1] / 1_000_000,
        map_results[2] / 1_000_000,
    });

    for (array_map_results) |*r| {
        var timer = try Timer.start();
        for (@as([loops]u8, undefined)) |_| {
            it.index = 0;
            while (it.next()) |val| {
                _ = array_map.get(val).?;
            }
        }
        r.* = timer.read();
    }

    log.alert("StringArrayHashMap\t{:0>4}ms\t{:0>4}ms\t{:0>4}ms", .{
        array_map_results[0] / 1_000_000,
        array_map_results[1] / 1_000_000,
        array_map_results[2] / 1_000_000,
    });

    for (radix_results) |*r| {
        var timer = try Timer.start();
        for (@as([loops]u8, undefined)) |_| {
            it.index = 0;
            while (it.next()) |val| {
                _ = radix.get(val).?;
            }
        }
        r.* = timer.read();
    }

    log.alert("RadixTree\t\t\t{:0>4}ms\t{:0>4}ms\t{:0>4}ms", .{
        radix_results[0] / 1_000_000,
        radix_results[1] / 1_000_000,
        radix_results[2] / 1_000_000,
    });
}
