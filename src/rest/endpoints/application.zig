const std = @import("std");
const root = @import("../../root.zig");
const model = root.model;
const rest = root.rest;
const Application = model.Application;

pub fn getCurrentApplication(client: *rest.EndpointClient) !rest.RestClient.Result(Application) {
    const url = rest.base_url ++ "/application/@me";
    return client.rest_client.request(Application, .GET, try std.Uri.parse(url));
}

pub fn editCurrentApplication(client: *rest.EndpointClient, params: EditParams) !rest.RestClient.Result(Application) {
    const url = rest.base_url ++ "/application/@me";

    return client.rest_client.requestWithValueBody(Application, .PATCH, try std.Uri.parse(url), params, .{});
}

pub const EditParams = struct {
    custom_install_url: []const u8,
    description: ?[]const u8,
    role_connections_verification_url: ?[]const u8,
    install_params: ?InstallParams,
    flags: ?model.Application.Flags,
    icon: ?union(enum) {
        remove: void,
        set: []const u8,
    },
    cover_image: ?union(enum) {
        remove: void,
        set: []const u8,
    },
    interactions_endpoint_url: []const u8,
    tags: []const []const u8,

    pub const InstallParams = struct {
        scopes: []const []const u8,
        permissions: []const u8,
    };
};
