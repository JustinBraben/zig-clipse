pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            next: ?*Node = null,
            data: T,

            pub const Data = T;

            pub fn insertAfter(node: *Node, new_node: *Node) void {
                new_node.next = node.next;
                node.next = new_node;
            }
        };

        first: ?*Node = null,

        pub fn prepend(list: *Self, new_node: *Node) void {
            new_node.next = list.first;
            list.first = new_node;
        }

        pub fn popFirst(list: *Self) ?*Node {
            const first = list.first orelse return null;
            list.first = first.next;
            return first;
        }
    };
}