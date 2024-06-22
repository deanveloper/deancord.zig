const std = @import("std");
const websocket = @import("websocket");

pub const TestServer = struct {
    net_server: std.net.Server,
    ws_server: websocket.Server,

    pub fn init(host: []const u8, port: u16) !TestServer {
        const allocator = std.testing.allocator;

        const ws_server = try websocket.Server.init(allocator, .{
            .port = port,
            .max_headers = 10,
            .address = host,
        });

        const address = try std.net.Address.parseIp(host, port);
        const net_server = try address.listen(.{
            .reuse_address = true,
            .kernel_backlog = 1024,
        });

        return .{
            .net_server = net_server,
            .ws_server = ws_server,
        };
    }

    pub fn accept(self: *TestServer, comptime H: type, comptime C: type, ctx: *C) !void {
        const conn = try self.net_server.accept();
        self.ws_server.accept(H, ctx, conn.stream);
    }

    pub fn listen(self: *TestServer, comptime H: type, comptime C: type, ctx: *C) !void {
        while (true) {
            try self.accept(H, C, ctx);
        }
    }

    pub fn deinit(self: *TestServer) void {
        self.ws_server.deinit(std.testing.allocator);
    }
};

const Context = struct {
    server: *TestServer,
};
