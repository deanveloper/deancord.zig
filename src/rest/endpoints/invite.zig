const deancord = @import("../../root.zig");
const std = @import("std");
const model = deancord.model;
const rest = deancord.rest;
const jconfig = deancord.jconfig;

pub fn getInvite(
    client: *rest.EndpointClient,
    code: []const u8,
    query: GetInviteQuery,
) !rest.RestClient.Result(model.Invite) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/invites/{s}?{query}", .{ code, query });
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    return client.rest_client.request(model.Invite, .GET, uri);
}

pub fn deleteInvite(
    client: *rest.EndpointClient,
    code: []const u8,
    audit_log_reason: ?[]const u8,
) !rest.RestClient.Result(model.Invite) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/invites/{s}", .{code});
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    return client.rest_client.requestWithAuditLogReason(model.Invite, .DELETE, uri, audit_log_reason);
}

pub const GetInviteQuery = struct {
    with_counts: ?bool,
    with_expiration: ?bool,
    guild_scheduled_event_id: ?model.Snowflake,

    pub usingnamespace rest.QueryStringFormatMixin(@This());
};
