const std = @import("std");

pub fn RadixTree(comptime T: type) type {
    return struct {
        const Self = @This();

        const Node = struct {
            leaf: ?Leaf,
            prefix: []const u8,
            edges: []Edge,

            fn isLeaf(self: Node) bool {
                return self.leaf != null;
            }

            fn addEdge(self: *Node, comptime e: Edge) void {}

            fn lessThan(node: Node, lhs: u8, rhs: u8) bool {
                return node.edges[lhs].label < node.edges[rhs].label;
            }

            fn edge(self: Node, label: u8) ?Node {
                const idx = blk: {
                    var i: usize = 0;
                    while (i < self.edges.len) : (i += 1) {
                        if (self.edges[i].label >= label) break;
                    }
                    break :blk i;
                };

                if (idx < self.edges.len and self.edges[idx].label == label)
                    return self.edges[idx].node;

                return null;
            }
        };

        const Leaf = struct {
            key: []const u8,
            data: T,
        };

        const Edge = struct {
            label: u8,
            node: Node,
        };

        root: Node = .{
            .leaf = null,
            .prefix = "",
            .edges = &[_]Edge{},
        },
        size: usize = 0,

        pub fn insert(self: *Self, comptime key: []const u8, comptime data: T) ?T {
            var parent: Node = undefined;

            var current: Node = self.root;
            comptime var search: []const u8 = key;

            while (true) {
                if (search.len == 0) {
                    if (current.isLeaf()) {
                        const temp = current.leaf.?.data;
                        current.leaf.?.data = data;
                        return temp;
                    }

                    current.leaf = Leaf{
                        .key = key,
                        .data = data,
                    };
                    self.size += 1;
                    return null;
                }

                parent = current;
                if (current.edge(search[0])) |n| {
                    current = n;
                } else {
                    parent.addEdge(comptime .{
                        .label = search[0],
                        .node = Node{
                            .leaf = Leaf{
                                .key = key,
                                .data = data,
                            },
                            .prefix = search,
                            .edges = &[_]Edge{},
                        },
                    });
                    self.size += 1;
                    return null;
                }
            }
        }

        fn longestPrefix(self: *Self, comptime key: []const u8) ?[]const u8 {
            var last: ?*Leaf = undefined;

            var current = self.root;
            var search = key;

            while (true) {
                if (current.isLeaf())
                    last = current.leaf.?;

                if (search.len == 0) break;

                current = current.edge(search[0]) orelse break;

                if (std.mem.startsWith(u8, search, current.prefix))
                    search = search[current.prefix.len..]
                else
                    break;
            }
        }
    };
}

/// Finds the length of the longest prefix between 2 strings
fn longestPrefix(lhs: []const u8, rhs: []const u8) usize {
    var max = std.math.max(lhs.len, rhs.len);

    var i: usize = 0;
    return while (i < max) : (i += 1) {
        if (lhs[i] != rhs[i]) break i;
    } else break i;
}

test "Insertion" {
    comptime var radix = RadixTree(u32){};
    comptime _ = radix.insert("hi", 1);
}
