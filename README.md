<!--
 Copyright (c) 2020 Luuk de Gram
 
 This software is released under the MIT License.
 https://opensource.org/licenses/MIT
-->

# ctradix

Comptime radix trie implemented in [Zig](https://ziglang.org).
This library was experimental to see how feasible it is to implement a comptime radix trie
where all data is known at compile time. The main use case for this library is to be used
within [apple_pie](https://github.com/Luukdegram/apple_pie) for routing support.

The implementation is based on Hashicorp's [implementation](https://github.com/hashicorp/go-immutable-radix).

For a fast, adaptive radix tree implementation in Zig I'd recommend [art.zig](https://github.com/travisstaloch/art.zig).

## Example

```zig
comptime var radix = RadixTree(u32){};
comptime _ = radix.insert("foo", 1);
comptime _ = radix.insert("bar", 2);

const foo = radix.get("foo");
const bar = radix.getLongestPrefix("barfoo");

std.log.info("{}", .{foo}); //1
std.log.info("{}", .{bar}); //2
```

## Benchmarks

To run the benchmarks, run `zig build bench`. Note that the benchmark is always ran as ReleaseFast.
edit build.zig if you want to enable other build modes as well.


Searches for 300 words, 50.000 times for 3 instances
```
StringHashMap             0177ms  0175ms  0175ms
StringArrayHashMap        0228ms  0241ms  0241ms
RadixTree                 0393ms  0389ms  0392ms
```