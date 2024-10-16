const std = @import("std");
const deancord = @import("../../root.zig");
const model = deancord.model;
const rest = deancord.rest;

pub fn createInteractionResponse(
    client: *rest.EndpointClient,
    interaction_id: model.Snowflake,
    interaction_token: []const u8,
    body: model.interaction.InteractionResponse,
) !rest.RestClient.Result(void) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/interactions/{}/{s}/callback", .{ interaction_id, interaction_token });
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    return client.rest_client.requestWithValueBody(void, .POST, uri, body, .{});
}

pub fn createInteractionResponseMultipart(
    client: *rest.EndpointClient,
    interaction_id: model.Snowflake,
    interaction_token: []const u8,
    form: CreateInteractionResponseFormBody,
) !rest.RestClient.Result(void) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/interactions/{}/{s}/callback", .{ interaction_id, interaction_token });
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    var pending_request = try client.rest_client.beginMultipartRequest(void, .POST, uri, .chunked, rest.multipart_boundary, null);
    defer pending_request.deinit();

    try std.fmt.format(pending_request.writer(), "{form}", .{form});

    return pending_request.waitForResponse();
}

pub fn getOriginalInteractionResponse(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
) !rest.RestClient.Result(model.Message) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/webhooks/{}/{s}/messages/@original", .{ application_id, interaction_token });
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    return client.rest_client.request(model.Message, .GET, uri);
}

pub fn editOriginalInteractionResponse(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
    body: rest.endpoints.EditWebhookMessageFormBody,
) !rest.RestClient.Result(model.Message) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/webhooks/{}/{s}/messages/@original", .{ application_id, interaction_token });
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    var pending_request = try client.rest_client.beginMultipartRequest(model.Message, .PATCH, uri, .chunked, rest.multipart_boundary, null);
    defer pending_request.deinit();

    try std.fmt.format(pending_request.writer(), "{form}", .{body});

    return pending_request.waitForResponse();
}

pub fn deleteOriginalInteractionResponse(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
) !rest.RestClient.Result(void) {
    const uri_str = try rest.allocDiscordUriStr(client.rest_client.allocator, "/webhooks/{}/{s}/messages/@original", .{ application_id, interaction_token });
    defer client.rest_client.allocator.free(uri_str);
    const uri = try std.Uri.parse(uri_str);

    return client.rest_client.request(void, .DELETE, uri);
}

pub fn createFollowupMessage(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
    body: rest.endpoints.ExecuteWebhookFormBody,
) !rest.RestClient.Result(model.Message) {
    return rest.endpoints.executeWebhookWait(client, application_id, interaction_token, .{}, body);
}

pub fn getFollowupMessage(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
    message_id: model.Snowflake,
) !rest.RestClient.Result(model.Message) {
    return rest.endpoints.getWebhookMessage(client, application_id, interaction_token, message_id, .{});
}

pub fn editFollowupMessage(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
    message_id: model.Snowflake,
    body: rest.endpoints.EditWebhookMessageFormBody,
) !rest.RestClient.Result(model.Message) {
    return rest.endpoints.editWebhookMessage(client, application_id, interaction_token, message_id, .{}, body);
}

pub fn deleteFollowupMessage(
    client: *rest.EndpointClient,
    application_id: model.Snowflake,
    interaction_token: []const u8,
    message_id: model.Snowflake,
) !rest.RestClient.Result(void) {
    return rest.endpoints.deleteWebhookMessage(client, application_id, interaction_token, message_id, .{});
}

pub const CreateInteractionResponseFormBody = struct {
    type: model.interaction.InteractionResponse.Type,
    data: ?model.interaction.InteractionCallbackData = null,
    files: ?[]const ?std.io.AnyReader = null,

    pub fn format(self: CreateInteractionResponseFormBody, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (comptime !std.mem.eql(u8, fmt, "form")) {
            @compileError("CreateInteractionResponseFormBody.format should only be called with fmt string {form}");
        }

        try rest.writeMultipartFormDataBody(self, "files", writer);
    }
};
