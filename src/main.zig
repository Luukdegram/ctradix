const std = @import("std");
const testing = std.testing;

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

            fn addEdge(self: *Node, comptime e: Edge) void {
                if (self.edges.len == 0) {
                    var edges: [1]Edge = .{e};
                    self.edges = &edges;
                    return;
                }
                var edges: [self.edges.len + 1]Edge = undefined;
                std.mem.copy(Edge, &edges, self.edges[0..]);
                edges[edges.len - 1] = e;

                std.sort.sort(Edge, &edges, {}, lessThan);
                self.edges = &edges;
            }

            fn updateEdge(self: *Node, comptime label: u8, comptime node: Node) void {
                const idx = blk: {
                    var i: usize = 0;
                    while (i < self.edges.len) : (i += 1) {
                        if (self.edges[i].label >= label) break;
                    }
                    break :blk i;
                };

                if (idx < self.edges.len and self.edges[idx].label == label) {
                    self.edges[idx] = node;
                }

                @compileError("Edge with label '" ++ &[_]u8{u8} ++ "' does not exist\n");
            }

            fn lessThan(ctx: void, comptime lhs: Edge, comptime rhs: Edge) bool {
                return lhs.label < rhs.label;
            }

            fn edge(self: *Node, comptime label: u8) ?*Node {
                const idx = blk: {
                    var i: usize = 0;
                    while (i < self.edges.len) : (i += 1) {
                        if (self.edges[i].label >= label) break;
                    }
                    break :blk i;
                };

                if (idx < self.edges.len and self.edges[idx].label == label)
                    return &self.edges[idx].node;

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
            var parent: *Node = undefined;

            var current: *Node = &self.root;
            var search: []const u8 = key;

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
                    var leaf = Leaf{
                        .key = key,
                        .data = data,
                    };

                    var new_node = Node{
                        .leaf = leaf,
                        .prefix = search,
                        .edges = &[_]Edge{},
                    };

                    parent.addEdge(.{
                        .label = search[0],
                        .node = new_node,
                    });
                    self.size += 1;
                    return null;
                }

                const prefix = longestPrefix(search, current.prefix);
                if (prefix == current.prefix.len) {
                    search = search[prefix..];
                    continue;
                }

                self.size += 1;

                var child = Node{
                    .leaf = null,
                    .edges = &[_]Edge{},
                    .prefix = search[0..prefix],
                };

                parent.updateEdge(search[0], child);

                child.addEdge(.{
                    .label = current.prefix[prefix],
                    .node = current,
                });

                current.prefix = current.prefix[prefix..];

                var leaf = Leaf{
                    .key = key,
                    .data = data,
                };

                search = search[prefix..];
                if (search.len == 0) {
                    child.leaf = leaf;
                    return null;
                }

                const new_node = Node{
                    .leaf = leaf,
                    .prefix = search,
                    .edges = &[_]Edge{},
                };

                child.addEdge(.{
                    .label = search[0],
                    .node = new_node,
                });

                return null;
            }
        }
    };
}

/// Finds the length of the longest prefix between 2 strings
fn longestPrefix(comptime lhs: []const u8, comptime rhs: []const u8) usize {
    var max = std.math.min(lhs.len, rhs.len);

    var i: usize = 0;
    return while (i < max) : (i += 1) {
        if (lhs[i] != rhs[i]) break i;
    } else i;
}

test "Insertion" {
    comptime var radix = RadixTree(u32){};
    comptime const a = radix.insert("hi", 1);
    comptime const b = radix.insert("hi2", 2);
    comptime const c = radix.insert("hi2", 3);

    testing.expectEqual(@as(usize, 2), radix.size);
    testing.expectEqual(@as(?u32, null), a);
    testing.expectEqual(@as(?u32, null), b);
    testing.expectEqual(@as(?u32, 2), c);
}
