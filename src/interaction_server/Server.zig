//! Server which listens for Discord Interactions.
//! Only need to call `deinit()` if created via `init(Address)`.
//! If you have an existing `std.net.Address`, it is okay to create this struct via struct initialization.

const std = @import("std");
const deancord = @import("../root.zig");
const Request = @import("./Request.zig");

net_server: std.net.Server,

const Server = @This();

pub fn init(address: std.net.Address) !Server {
    const net_server = try address.listen(.{});
    return .{ .net_server = net_server };
}

/// Only need to call `deinit()` if created via `init(Address)`
pub fn deinit(self: *Server) void {
    self.net_server.deinit();
}

pub fn receiveInteraction(self: Server) !Request {
    var buf: [1000]u8 = undefined;
    const conn = try self.net_server.accept();
    var http_server = std.http.Server.init(conn, &buf);

    var req = try http_server.receiveHead();
    return try Request.init(&req);
}
