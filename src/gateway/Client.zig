const std = @import("std");
const builtin = @import("builtin");
const TestServer = if (builtin.is_test) @import("./test/TestServer.zig").TestServer else .{};
const websocket = @import("websocket");
const GatewayEvent = @import("./GatewayEvent.zig");

fn JsonHandler(comptime SubHandler: type) type {
    comptime std.debug.assert(std.meta.hasMethod(SubHandler, "onMessage"));

    return struct {
        allocator: std.mem.Allocator,
        host: []const u8,
        port: u16,
        client: websocket.Client,
        sub_handler: *SubHandler,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, host: []const u8, port: u16, sub_handler: *SubHandler) !Self {
            return .{
                .allocator = allocator,
                .client = try websocket.connect(allocator, host, port, .{}),
                .host = host,
                .port = port,
                .sub_handler = sub_handler,
            };
        }

        pub fn deinit(self: *Self) void {
            self.client.deinit();
        }

        pub fn listen(self: *Self, path: []const u8) !std.Thread {
            const headers = try std.fmt.allocPrint(self.allocator, "Host: {s}:{d}", .{ self.host, self.port });
            defer self.allocator.free(headers);

            try self.client.handshake(path, .{
                .timeout_ms = 5000,
                .headers = headers,
            });

            return try self.client.readLoopInNewThread(self);
        }

        pub fn handle(self: *Self, message: websocket.Message) !void {
            const parsed = try std.json.parseFromSlice(std.json.Value, self.allocator, message.data, .{});

            try self.sub_handler.onMessage(parsed);
        }

        pub fn write(self: *Self, data: []u8) !void {
            return self.client.write(data);
        }

        pub fn close(self: *Self) void {
            if (std.meta.hasFn(SubHandler, "close")) {
                self.sub_handler.close();
            }
        }
    };
}

const TestServerHandler = struct {
    const Context = struct {
        server: *TestServer,
    };

    conn: *websocket.Conn,
    context: *Context,

    pub fn init(_: websocket.Handshake, conn: *websocket.Conn, context: *Context) !TestServerHandler {
        return TestServerHandler{
            .conn = conn,
            .context = context,
        };
    }

    pub fn handle(self: *TestServerHandler, message: websocket.Message) !void {
        const data = message.data;
        try self.conn.write(data); // echo the message back
    }

    // called whenever the connection is closed, can do some cleanup in here
    pub fn close(_: *TestServerHandler) void {}
};

const TestClient = struct {
    allocator: std.mem.Allocator,
    messages: std.ArrayList(std.json.Parsed(std.json.Value)),

    pub fn init(alloc: std.mem.Allocator) !TestClient {
        return .{
            .allocator = alloc,
            .messages = std.ArrayList(std.json.Parsed(std.json.Value)).init(alloc),
        };
    }

    pub fn onMessage(self: *TestClient, message: std.json.Parsed(std.json.Value)) !void {
        try self.messages.append(message);
    }

    pub fn close(self: TestClient) void {
        for (self.messages.items) |parsed| {
            parsed.deinit();
        }
        self.messages.deinit();
    }
};

fn cloneJsonValue(allocator: std.mem.Allocator, value: std.json.Value) !std.json.Parsed(std.json.Value) {
    var arena = std.heap.ArenaAllocator.init(allocator);
    var arena_alloc = arena.allocator();
    const new_value = switch (value) {
        .null => |old| old,
        .bool => |old| old,
        .integer => |old| old,
        .float => |old| old,
        .number_string => |old| .{ .number_string = try arena_alloc.alloc(u8, old.len) },
        .string => |old| .{ .string = try arena_alloc.alloc(u8, old.len) },
        .array => |old| .{ .array = std.json.Array.initCapacity(arena_alloc, old.items.len).appendSlice(old.items) },
        .object => |old| .{ .object = old.cloneWithAllocator(arena_alloc) },
    };
    return std.json.Parsed(std.json.Value){
        .arena = arena,
        .value = new_value,
    };
}

test "lol" {
    const allocator = std.testing.allocator;

    var test_server = try TestServer.init("127.0.0.1", 1337);
    defer test_server.deinit();

    var client = try TestClient.init(allocator);
    var handler = try JsonHandler(TestClient).init(allocator, "127.0.0.1", 1337, &client);
    errdefer handler.deinit();

    var context = TestServerHandler.Context{ .server = &test_server };
    const server_thread = try std.Thread.spawn(.{ .allocator = allocator }, TestServer.accept, .{ &test_server, TestServerHandler, TestServerHandler.Context, &context });
    server_thread.detach();

    std.time.sleep(std.time.ns_per_s);

    const client_thread = try handler.listen("/");

    const data = try allocator.dupe(u8, "\"hello world\"");
    defer allocator.free(data);
    try handler.write(data);

    std.time.sleep(std.time.ns_per_s);

    try std.testing.expectEqual(1, client.messages.items.len);
    try std.testing.expect(client.messages.items[0].value == .string);
    try std.testing.expectEqualStrings("hello world", client.messages.items[0].value.string);

    handler.deinit();

    client_thread.join();
}
