const std = @import("std");
const Person = @import("person.zig").Person;
const print = std.debug.print;

const TypeHashFn = std.hash.Fnv1a_64;

pub fn main() !void {
    print("Hello\n", .{});

    const p1 = Person{
        .name = "Landon",
        .age = 22,
        .isStudent = true,
    };

    comptime var p2 = Person{
        .name = "Steve",
        .age = 27,
        .isStudent = false,
    };
    p2.age = 28;

    const allocator = std.heap.page_allocator;
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try serialize(buf.writer(), @TypeOf(p1), p1);

    print("Serial data : {s}\n", .{buf.items});

    var stream = std.io.fixedBufferStream(buf.items);
    const deserial_data = try deserializeAlloc(stream.reader(), @TypeOf(p1), allocator);
    print("Deserialized data : {}\n", .{deserial_data});
}

fn printTypeName(comptime T: type) void {
    std.debug.print("Type name for object is {s}\n", .{@typeName(T)});
}

fn printFields(comptime T: type) void {
    inline for (std.meta.fields(T)) |field| {
        std.debug.print("Field Name \t: {s}\n", .{field.name});
        std.debug.print("Field type \t: {}\n", .{field.type});
        std.debug.print("\n", .{});
    }
}

pub fn serialize(stream: anytype, comptime T: type, value: T) @TypeOf(stream).Error!void {
    comptime validateTopLevelType(T);
    const type_hash = comptime computeTypeHash(T);
    try stream.writeAll(type_hash[0..]);
    try serializeRecursive(stream, T, value);
}

pub fn deserialize(stream: anytype, comptime T: type) (@TypeOf(stream).Error || error{ UnexpectedData, EndOfStream })!T {
    comptime validateTopLevelType(T);
    if (comptime requiresAllocationForDeserialize(T)) {
        @compileError(@typeName(T) ++ " requires allocation to be deserialized. Use deserializeAlloc instead of deserialize!");
    }
    return deserializeInternal(stream, T, null) catch |err| switch (err) {
        error.OutOfMemory => unreachable,
        else => |e| return e,
    };
}

pub fn deserializeAlloc(
    stream: anytype,
    comptime T: type,
    allocator: ?std.mem.Allocator,
) (@TypeOf(stream).Error || error{ UnexpectedData, OutOfMemory, EndOfStream })!T {
    comptime validateTopLevelType(T);
    return deserializeInternal(stream, T, allocator);
}

fn deserializeInternal(
    stream: anytype,
    comptime T: type,
    allocator: ?std.mem.Allocator,
) (@TypeOf(stream).Error || error{ UnexpectedData, OutOfMemory, EndOfStream })!T {
    const type_hash = comptime computeTypeHash(T);

    var ref_hash: [type_hash.len]u8 = undefined;
    try stream.readNoEof(&ref_hash);
    if (!std.mem.eql(u8, type_hash[0..], ref_hash[0..])) {
        return error.UnexpectedData;
    }

    var result: T = undefined;
    try recursiveDeserialize(stream, T, allocator, &result);
    return result;
}

fn recursiveDeserialize(
    stream: anytype,
    comptime T: type,
    allocator: ?std.mem.Allocator,
    target: *T,
) (@TypeOf(stream).Error || error{ UnexpectedData, OutOfMemory, EndOfStream })!void {
    switch (@typeInfo(T)) {
        // Primitives
        .Void => target.* = {},

        .Bool => target.* = (try stream.readByte()) != 0,

        .Float => target.* = @bitCast(switch (T) {
            f16 => try stream.readInt(u16, .little),
            f32 => try stream.readInt(u32, .little),
            f64 => try stream.readInt(u64, .little),
            f80 => try stream.readInt(u80, .little),
            f128 => try stream.readInt(u128, .little),
            else => unreachable,
        }),

        .Int => target.* = if (T == usize)
            std.math.cast(usize, try stream.readInt(u64, .little)) orelse return error.UnexpectedData
        else
            @as(AlignedInt(T), @truncate(try stream.readInt(AlignedInt(T), .little))),

        .Pointer => |ptr| {
            if (ptr.sentinel != null) @compileError("Sentinels are not supported yet!");
            switch (ptr.size) {
                .One => {
                    const pointer = try allocator.?.create(ptr.child);
                    errdefer allocator.?.destroy(pointer);

                    try recursiveDeserialize(stream, ptr.child, allocator, pointer);

                    target.* = pointer;
                },

                .Slice => {
                    const length = std.math.cast(usize, try stream.readInt(u64, .little)) orelse return error.UnexpectedData;

                    const slice = try allocator.?.alloc(ptr.child, length);
                    errdefer allocator.?.free(slice);

                    if (ptr.child == u8) {
                        try stream.readNoEof(slice);
                    } else {
                        for (slice) |*item| {
                            try recursiveDeserialize(stream, ptr.child, allocator, item);
                        }
                    }

                    target.* = slice;
                },

                // Unsupported types
                .C, .Many => unreachable,
            }
        },

        .Array => |arr| {
            if (arr.child == u8) {
                try stream.readNoEof(target);
            } else {
                for (&target.*) |*item| {
                    try recursiveDeserialize(stream, arr.child, allocator, item);
                }
            }
        },

        .Struct => |str| {
            // Iterate over the fields in the struct and deserialize them

            inline for (str.fields) |field| {
                try recursiveDeserialize(stream, field.type, allocator, &@field(target.*, field.name));
            }
        },

        // Unsupported types:
        .Optional,
        .ErrorUnion,
        .ErrorSet,
        .Enum,
        .Union,
        .Vector,
        .NoReturn,
        .Type,
        .ComptimeFloat,
        .ComptimeInt,
        .Undefined,
        .Null,
        .Fn,
        .Opaque,
        .Frame,
        .AnyFrame,
        .EnumLiteral,
        => unreachable,
    }
}

/// Recursively looks through the type and determines if it requires allocation for deserialization
/// If it finds a Pointer type, it will return true
fn requiresAllocationForDeserialize(comptime T: type) bool {
    switch (@typeInfo(T)) {
        .Pointer => return true,
        .Struct, .Union => {
            inline for (comptime std.meta.fields(T)) |field| {
                if (requiresAllocationForDeserialize(field.type)) {
                    return true;
                }
            }
            return false;
        },
        .ErrorUnion => |err_union| {
            return requiresAllocationForDeserialize(err_union.payload);
        },
        else => return false,
    }
}

fn serializeRecursive(stream: anytype, comptime T: type, value: T) @TypeOf(stream).Error!void {
    switch (@typeInfo(T)) {
        // Primitives
        .Void => {},
        .Bool => try stream.writeByte(@intFromBool(value)),
        .Float => try switch (T) {
            f16 => try stream.writeInt(u16, @bitCast(value), .little),
            f32 => try stream.writeInt(u32, @bitCast(value), .little),
            f64 => try stream.writeInt(u64, @bitCast(value), .little),
            f80 => try stream.writeInt(u80, @bitCast(value), .little),
            f128 => try stream.writeInt(u128, @bitCast(value), .little),
            else => unreachable,
        },
        .Int => {
            if (T == usize) {
                try stream.writeInt(u64, value, .little);
            } else {
                try stream.writeInt(AlignedInt(T), value, .little);
            }
        },
        .Pointer => |ptr| {
            if (ptr.sentinel != null) @compileError("Sentinels are not supported yet!");
            switch (ptr.size) {
                .One => try serializeRecursive(stream, ptr.child, value.*),
                .Slice => {
                    try stream.writeInt(u64, value.len, .little);
                    if (ptr.child == u8) {
                        try stream.writeAll(value);
                    } else {
                        for (value) |item| {
                            try serializeRecursive(stream, ptr.child, item);
                        }
                    }
                },
                .C => unreachable,
                .Many => unreachable,
            }
        },
        .Array => |arr| {
            if (arr.child == u8) {
                try stream.writeAll(&value);
            } else {
                for (value) |item| {
                    try serializeRecursive(stream, arr.child, item);
                }
            }
        },
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                try serializeRecursive(stream, field.type, @field(value, field.name));
            }
        },

        // Unsupported types:
        .Optional,
        .ErrorUnion,
        .ErrorSet,
        .Enum,
        .Union,
        .Vector,
        .NoReturn,
        .Type,
        .ComptimeFloat,
        .ComptimeInt,
        .Undefined,
        .Null,
        .Fn,
        .Opaque,
        .Frame,
        .AnyFrame,
        .EnumLiteral,
        => unreachable,
    }
}

/// Validates that the type is not an error set or error union
fn validateTopLevelType(comptime T: type) void {
    switch (@typeInfo(T)) {
        .ErrorSet, .ErrorUnion => @compileError("Unsupported top level type " ++ @typeName(T) ++ ". Wrap into struct to serialize these."),
        else => {},
    }
}

/// Computes a hash of the type
fn computeTypeHash(comptime T: type) [8]u8 {
    var hasher = TypeHashFn.init();

    computeTypeHashInternal(&hasher, T);

    return intToLittleEndianBytes(hasher.final());
}

/// Computes a hash of the type
/// TODO: Add implementations for unsupported types
fn computeTypeHashInternal(hasher: *TypeHashFn, comptime T: type) void {
    @setEvalBranchQuota(10_000);

    switch (@typeInfo(T)) {
        // Primitives
        .Void,
        .Bool,
        .Float,
        => hasher.update(@typeName(T)),

        .Int => {
            if (T == usize) {
                hasher.update(@typeName(u64));
            } else {
                hasher.update(@typeName(T));
            }
        },

        .Pointer => |ptr| {
            if (ptr.is_volatile) @compileError("Serializing volatile pointers is most likely a mistake.");
            if (ptr.sentinel != null) @compileError("Sentinels are not supported yet!");
            switch (ptr.size) {
                .One => {
                    hasher.update("pointer");
                    computeTypeHashInternal(hasher, ptr.child);
                },
                .Slice => {
                    hasher.update("slice");
                    computeTypeHashInternal(hasher, ptr.child);
                },
                .C => @compileError("C-pointers are not supported"),
                .Many => @compileError("Many-pointers are not supported"),
            }
        },

        .Struct => |str| {
            // we can safely ignore the struct layout here as we will serialize the data by field order,
            // instead of memory representation

            // add some generic marker to the hash so emtpy structs get
            // added as information
            hasher.update("struct");

            for (str.fields) |fld| {
                if (fld.is_comptime) @compileError("comptime fields are not supported.");
                computeTypeHashInternal(hasher, fld.type);
            }
        },

        // Unsupported types
        .Array,
        .Optional,
        .ErrorUnion,
        .ErrorSet,
        .Enum,
        .Union,
        .Vector,
        .NoReturn,
        .Type,
        .ComptimeFloat,
        .ComptimeInt,
        .Undefined,
        .Null,
        .Fn,
        .Opaque,
        .Frame,
        .AnyFrame,
        .EnumLiteral,
        => @compileError("Unsupported type " ++ @typeName(T)),
    }
}

fn intToLittleEndianBytes(val: anytype) [@sizeOf(@TypeOf(val))]u8 {
    const T = @TypeOf(val);
    var res: [@sizeOf(T)]u8 = undefined;
    std.mem.writeInt(AlignedInt(T), &res, val, .little);
    return res;
}

/// Determines the size of the next byte aligned integer type that can accommodate the same range of values as `T`
fn AlignedInt(comptime T: type) type {
    return std.math.ByteAlignedInt(T);
}
