const std = @import("std");
const model = @import("model");
const rest = @import("../../rest.zig");
const Omittable = model.deanson.Omittable;
const stringifyWithOmit = model.deanson.stringifyWithOmit;
const Result = rest.Client.Result;
const ApplicationCommandOption = model.interaction.command_option.ApplicationCommandOption;
const ApplicationCommand = model.interaction.command.ApplicationCommand;
const ApplicationCommandType = model.interaction.command.ApplicationCommandType;
const Client = rest.Client;
const Snowflake = model.Snowflake;

/// The objects returned by this endpoint may be augmented with additional fields if localization is active.
///
/// Fetch all of the global commands for your application. Returns an array of application command objects.
pub fn getGlobalApplicationCommands(
    client: *Client,
    applicationId: Snowflake,
    with_localizations: ?bool,
) !Result([]ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/commands", .{applicationId});
    defer client.allocator.free(path);

    var query: ?[]const u8 = null;
    if (with_localizations) |value| {
        query = if (value) "with_localizations=true" else "with_localizations=false";
    }

    const url = try rest.discordApiCallUri(client.allocator, path, query);

    return client.request([]ApplicationCommand, .GET, url);
}

/// Creating a command with the same name as an existing command for your application will overwrite the old command.
///
/// Create a new global command. Returns `201` if a command with the same name does not
/// already exist, or a `200` if it does (in which case the previous command will be overwritten).
/// Both responses include an application command object.
pub fn createGlobalApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    body: CreateGlobalApplicationCommandBody,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/commands", .{application_id});
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody(ApplicationCommand, .POST, url, body, .{});
}

/// Fetch a global command for your application. Returns an application command object.
pub fn getGlobalApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    command_id: Snowflake,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/commands/{d}", .{ application_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.request(ApplicationCommand, .GET, url);
}

/// Edit a global command. Returns `200` and an application command object.
/// All fields are optional, but any fields provided will entirely overwrite the existing values of those fields.
pub fn editGlobalApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    command_id: Snowflake,
    body: EditGlobalApplicationCommandBody,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/commands/{d}", .{ application_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody(ApplicationCommand, .PATCH, url, body, .{});
}

/// Deletes a global command. Returns `204 No Content` on success.
pub fn deleteGlobalApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    command_id: Snowflake,
) !Result(void) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/commands/{d}", .{ application_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.request(void, .DELETE, url);
}

/// Takes a list of application commands, overwriting the existing global command list for this application.
/// Returns `200` and a list of application command objects.
/// Commands that do not already exist will count toward daily application command create limits.
///
/// This will overwrite all types of application commands: slash commands, user commands, and message commands.
pub fn bulkOverwriteGlobalApplicationCommands(
    client: *Client,
    application_id: Snowflake,
    new_commands: []const ApplicationCommand,
) !Result([]ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/commands", .{application_id});
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody([]ApplicationCommand, .PUT, url, new_commands, .{});
}

pub fn getGuildApplicationCommands(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    with_localizations: ?bool,
) !Result([]ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands", .{ application_id, guild_id });
    defer client.allocator.free(path);

    var query: ?[]const u8 = null;
    if (with_localizations) |value| {
        query = if (value) "with_localizations=true" else "with_localizations=false";
    }

    const url = try rest.discordApiCallUri(client.allocator, path, query);

    return client.request([]ApplicationCommand, .GET, url);
}

pub fn createGuildApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    body: CreateGuildApplicationCommandBody,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands", .{ application_id, guild_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody(ApplicationCommand, .POST, url, body, .{});
}

pub fn getGuildApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands/{d}", .{ application_id, guild_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.request(ApplicationCommand, .GET, url);
}

pub fn editGuildApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
    body: EditGuildApplicationCommandBody,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guild/{d}/commands/{d}", .{ application_id, guild_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody(ApplicationCommand, .PATCH, url, body, .{});
}

pub fn deleteGuildApplicationCommand(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Result(ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands/{d}", .{ application_id, guild_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.request(ApplicationCommand, .DELETE, url);
}

pub fn bulkOverwriteGuildApplicationCommands(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    new_commands: []const ApplicationCommand,
) !Result([]ApplicationCommand) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands", .{ application_id, guild_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody([]ApplicationCommand, .PUT, url, new_commands, .{});
}

pub fn getGuildApplicationCommandPermissions(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
) !Result([]GuildApplicationCommandPermissions) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/permissions", .{ application_id, guild_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.request([]GuildApplicationCommandPermissions, .GET, url);
}

pub fn getApplicationCommandPermissions(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
) !Result(GuildApplicationCommandPermissions) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands/{d}/permissions", .{ application_id, guild_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.request(GuildApplicationCommandPermissions, .GET, url);
}

pub fn editApplicationCommandPermissions(
    client: *Client,
    application_id: Snowflake,
    guild_id: Snowflake,
    command_id: Snowflake,
    body: []ApplicationCommandPermission,
) !Result(GuildApplicationCommandPermissions) {
    const path = try std.fmt.allocPrint(client.allocator, "/applications/{d}/guilds/{d}/commands/{d}/permissions", .{ application_id, guild_id, command_id });
    defer client.allocator.free(path);

    const url = try rest.discordApiCallUri(client.allocator, path, null);

    return client.requestWithValueBody(GuildApplicationCommandPermissions, .PUT, url, body, .{});
}

pub const CreateGlobalApplicationCommandBody = struct {
    name: []const u8,
    name_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    description: Omittable([]const u8) = .{ .omitted = void{} },
    description_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    options: Omittable([]const ApplicationCommandOption) = .{ .omitted = void{} },
    default_member_permissions: Omittable(?[]const u8) = .{ .omitted = void{} },
    dm_permission: Omittable(?bool) = .{ .omitted = void{} },
    default_permission: Omittable(bool) = .{ .omitted = void{} },
    type: Omittable(ApplicationCommandType) = .{ .omitted = void{} },
    nsfw: Omittable(bool) = .{ .omitted = void{} },

    pub const jsonStringify = stringifyWithOmit;
};

pub const EditGlobalApplicationCommandBody = struct {
    name: Omittable([]const u8) = .{ .omitted = void{} },
    name_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    description: Omittable([]const u8) = .{ .omitted = void{} },
    description_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    options: Omittable([]const ApplicationCommandOption) = .{ .omitted = void{} },
    default_member_permissions: Omittable(?[]const u8) = .{ .omitted = void{} },
    dm_permission: Omittable(?bool) = .{ .omitted = void{} },
    default_permission: Omittable(bool) = .{ .omitted = void{} },
    nsfw: Omittable(bool) = .{ .omitted = void{} },

    pub const jsonStringify = stringifyWithOmit;
};

pub const CreateGuildApplicationCommandBody = struct {
    name: []const u8,
    name_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    description: Omittable([]const u8) = .{ .omitted = void{} },
    description_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    options: Omittable([]const ApplicationCommandOption) = .{ .omitted = void{} },
    default_member_permissions: Omittable(?[]const u8) = .{ .omitted = void{} },
    default_permission: Omittable(bool) = .{ .omitted = void{} },
    type: Omittable(ApplicationCommandType) = .{ .omitted = void{} },
    nsfw: Omittable(bool) = .{ .omitted = void{} },

    pub const jsonStringify = stringifyWithOmit;
};

pub const EditGuildApplicationCommandBody = struct {
    name: Omittable([]const u8) = .{ .omitted = void{} },
    name_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    description: Omittable([]const u8) = .{ .omitted = void{} },
    description_localizations: Omittable(?model.Localizations) = .{ .omitted = void{} },
    options: Omittable([]const ApplicationCommandOption) = .{ .omitted = void{} },
    default_member_permissions: Omittable(?[]const u8) = .{ .omitted = void{} },
    default_permission: Omittable(bool) = .{ .omitted = void{} },
    nsfw: Omittable(bool) = .{ .omitted = void{} },

    pub const jsonStringify = stringifyWithOmit;
};

pub const GuildApplicationCommandPermissions = struct {
    id: Snowflake,
    application_id: Snowflake,
    guild_id: Snowflake,
    permissions: ApplicationCommandPermission,
};

pub const ApplicationCommandPermission = struct {
    id: Snowflake,
    type: enum(u4) { role = 1, user = 2, channel = 3 },
    permission: bool,
};
