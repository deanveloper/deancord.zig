const std = @import("std");
const model = @import("../model.zig");
const deanson = model.deanson;
const Omittable = deanson.Omittable;
const builtin = @import("builtin");

pub const Opcode = enum(i64) {
    dispatch = 0,
    heartbeat = 1,
    identify = 2,
    presence_update = 3,
    voice_state_update = 4,
    @"resume" = 6,
    reconnect = 7,
    request_guild_members = 8,
    invalid_session = 9,
    hello = 10,
    heartbeat_ack = 11,
    _,
};

pub const GatewayEvent = struct {
    op: Opcode,
    d: ?EventData,
    s: ?i64,
    t: ?[]const u8,

    pub fn jsonParseFromValue(alloc: std.mem.Allocator, source: std.json.Value, _: std.json.ParseOptions) !GatewayEvent {
        const object = if (source == .object) source.object else return error.ExpectedObject;

        const opValue = object.get("op") orelse return error.ExpectedOpcode;
        const dOpt = object.get("d");
        const sOpt = object.get("s");
        const tValue = object.get("t") orelse std.json.Value{ .null = void{} };

        const typee = switch (tValue) {
            .null => null,
            .string => |str| str,
            else => return error.TypeShouldBeString,
        };
        const opInt = if (opValue == .integer) opValue.integer else return error.OpcodeShouldBeInt;
        const opCode: Opcode = @enumFromInt(opInt);
        const data: ?EventData = switch (opCode) {
            _ => return .{ .unknown = dOpt },
            .dispatch => try parseDispatch(alloc, dOpt orelse return error.DPropertyExpected, typee orelse return error.TypeExpected),
            .heartbeat => .{ .number = try std.json.innerParseFromValue(i64, alloc, dOpt orelse return error.DPropertyExpected, .{}) },
            .identify => @panic("todo"),
            .presence_update => @panic("todo"),
            .voice_state_update => @panic("todo"),
            .@"resume" => .{ .none = void{} },
            .reconnect => .{ .none = void{} },
            .request_guild_members => @panic("todo"),
            .invalid_session => try parseInvalidSession(dOpt orelse return error.DPropertyExpected),
            .hello => .{ .hello = try std.json.innerParseFromValue(EventData.Hello, alloc, dOpt orelse return error.DPropertyExpected, .{}) },
            .heartbeat_ack => @panic("todo"),
        };
        const sequence = blk: {
            if (sOpt) |sVal| {
                if (sVal == .integer) {
                    break :blk sVal.integer;
                } else {
                    return error.SExpectedInteger;
                }
            } else {
                break :blk null;
            }
        };

        return GatewayEvent{
            .op = opCode,
            .d = data,
            .s = sequence,
            .t = typee,
        };
    }

    fn parseDispatch(alloc: std.mem.Allocator, value: std.json.Value, typee: []const u8) !EventData {
        if (std.mem.eql(u8, typee, "READY")) {
            return .{ .ready = try std.json.innerParseFromValue(EventData.Ready, alloc, value, .{}) };
        }
        if (std.mem.eql(u8, typee, "APPLICATION_COMMAND_PERMISSIONS_UPDATE")) {
            return .{ .application_commands_permissions = try std.json.innerParseFromValue(model.interaction.command.ApplicationCommandPermissions, alloc, value, .{}) };
        }

        const auto_mod_rule_prefix = "AUTO_MODERATION_RULE_";
        if (std.mem.startsWith(u8, typee, auto_mod_rule_prefix)) {
            const suffix = typee[auto_mod_rule_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .auto_moderation_rule = try std.json.innerParseFromValue(model.AutoModerationRule, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .auto_moderation_rule = try std.json.innerParseFromValue(model.AutoModerationRule, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .auto_moderation_rule = try std.json.innerParseFromValue(model.AutoModerationRule, alloc, value, .{}) };
            }
        }

        if (std.mem.eql(u8, typee, "AUTO_MODERATION_ACTION_EXECUTION")) {
            return .{ .auto_moderation_action_execution_event = try std.json.innerParseFromValue(EventData.AutoModerationActionExecutionEvent, alloc, value, .{}) };
        }

        const channel_prefix = "CHANNEL_";
        if (std.mem.startsWith(u8, typee, channel_prefix)) {
            const suffix = typee[channel_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .channel = try std.json.innerParseFromValue(model.guild.channel.Channel, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .channel = try std.json.innerParseFromValue(model.guild.channel.Channel, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .channel = try std.json.innerParseFromValue(model.guild.channel.Channel, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "PINS_UPDATE")) {
                return .{ .channel_pin_update = try std.json.innerParseFromValue(EventData.ChannelPinsUpdate, alloc, value, .{}) };
            }
        }

        const thread_prefix = "THREAD_";
        if (std.mem.startsWith(u8, typee, thread_prefix)) {
            const suffix = typee[thread_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .channel = try std.json.innerParseFromValue(model.guild.channel.Channel, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .channel = try std.json.innerParseFromValue(model.guild.channel.Channel, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .thread_delete = try std.json.innerParseFromValue(EventData.ThreadDelete, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "LIST_SYNC")) {
                return .{ .thread_list_sync = try std.json.innerParseFromValue(EventData.ThreadListSync, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "MEMBER_UPDATE")) {
                return .{ .thread_member_with_guild_id = try std.json.innerParseFromValue(EventData.ThreadMemberUpdate, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "MEMBERS_UPDATE")) {
                return .{ .thread_members_update = try std.json.innerParseFromValue(EventData.ThreadMembersUpdate, alloc, value, .{}) };
            }
        }

        const entitlement_prefix = "ENTITLEMENT_";
        if (std.mem.startsWith(u8, typee, entitlement_prefix)) {
            const suffix = typee[entitlement_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .entitlement = try std.json.innerParseFromValue(model.Entitlement, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .entitlement = try std.json.innerParseFromValue(model.Entitlement, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .entitlement = try std.json.innerParseFromValue(model.Entitlement, alloc, value, .{}) };
            }
        }

        const guild_prefix = "GUILD_";
        if (std.mem.startsWith(u8, typee, guild_prefix)) {
            const suffix = typee[guild_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .guild_create = try std.json.innerParseFromValue(EventData.GuildCreate, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .guild = try std.json.innerParseFromValue(model.guild.Guild, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .unavailable_guild = try std.json.innerParseFromValue(model.guild.UnavailableGuild, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "AUDIT_LOG_ENTRY_CREATE")) {
                return .{ .audit_log_entry_create = try std.json.innerParseFromValue(EventData.AuditLogEntryCreate, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "BAN_ADD")) {
                return .{ .guild_and_user = try std.json.innerParseFromValue(EventData.GuildAndUser, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "BAN_REMOVE")) {
                return .{ .guild_and_user = try std.json.innerParseFromValue(EventData.GuildAndUser, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "EMOJIS_UPDATE")) {
                return .{ .guild_and_emojis = try std.json.innerParseFromValue(EventData.GuildAndUser, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "EMOJIS_UPDATE")) {
                return .{ .guild_and_emojis = try std.json.innerParseFromValue(EventData.GuildAndEmojis, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "STICKERS_UPDATE")) {
                return .{ .guild_and_stickers = try std.json.innerParseFromValue(EventData.GuildAndStickers, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "INTEGRATIONS_UPDATE")) {
                return .{ .guild_id = try std.json.innerParseFromValue(EventData.GuildId, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "INTEGRATIONS_UPDATE")) {
                return .{ .guild_id = try std.json.innerParseFromValue(EventData.GuildId, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "MEMBER_ADD")) {
                return .{ .guild_id = try std.json.innerParseFromValue(EventData.GuildId, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "MEMBER_REMOVE")) {
                return .{ .guild_and_user = try std.json.innerParseFromValue(EventData.GuildAndUser, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "MEMBER_UPDATE")) {
                return .{ .guild_member_update = try std.json.innerParseFromValue(EventData.GuildMemberUpdate, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "MEMBERS_CHUNK")) {
                return .{ .guild_members_chunk = try std.json.innerParseFromValue(EventData.GuildMembersChunk, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "ROLE_UPDATE")) {
                return .{ .guild_and_role = try std.json.innerParseFromValue(EventData.GuildAndRole, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "ROLE_DELETE")) {
                return .{ .guild_and_role_id = try std.json.innerParseFromValue(EventData.GuildAndRoleId, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "SCHEDULED_EVENT_CREATE")) {
                return .{ .guild_scheduled_event = try std.json.innerParseFromValue(model.guild.GuildScheduledEvent, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "SCHEDULED_EVENT_UPDATE")) {
                return .{ .guild_scheduled_event = try std.json.innerParseFromValue(model.guild.GuildScheduledEvent, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "SCHEDULED_EVENT_DELETE")) {
                return .{ .guild_scheduled_event = try std.json.innerParseFromValue(model.guild.GuildScheduledEvent, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "SCHEDULED_EVENT_USER_ADD")) {
                return .{ .guild_event_and_user = try std.json.innerParseFromValue(EventData.GuildEventAndUser, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "SCHEDULED_EVENT_USER_REMOVE")) {
                return .{ .guild_event_and_user = try std.json.innerParseFromValue(EventData.GuildEventAndUser, alloc, value, .{}) };
            }
        }

        const integration_prefix = "INTEGRATION_";
        if (std.mem.startsWith(u8, typee, integration_prefix)) {
            const suffix = typee[integration_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .integration_with_guild_id = try std.json.innerParseFromValue(EventData.IntegrationWithGuildId, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .integration_with_guild_id = try std.json.innerParseFromValue(EventData.IntegrationWithGuildId, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .integration_delete = try std.json.innerParseFromValue(EventData.IntegrationDelete, alloc, value, .{}) };
            }
        }

        if (std.mem.eql(u8, typee, "INTERACTION_CREATE")) {
            return .{ .interaction = try std.json.innerParseFromValue(model.interaction.Interaction, alloc, value, .{}) };
        }

        if (std.mem.eql(u8, typee, "INVITE_CREATE")) {
            return .{ .invite_create = try std.json.innerParseFromValue(EventData.InviteCreate, alloc, value, .{}) };
        }
        if (std.mem.eql(u8, typee, "INVITE_DELETE")) {
            return .{ .invite_delete = try std.json.innerParseFromValue(EventData.InviteDelete, alloc, value, .{}) };
        }

        const message_prefix = "MESSAGE_";
        if (std.mem.startsWith(u8, typee, message_prefix)) {
            const suffix = typee[message_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .message_update = try std.json.innerParseFromValue(EventData.MessageUpdate, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .message_update = try std.json.innerParseFromValue(EventData.MessageUpdate, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .message_delete = try std.json.innerParseFromValue(EventData.MessageDelete, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE_BULK")) {
                return .{ .message_delete_bulk = try std.json.innerParseFromValue(EventData.MessageDeleteBulk, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "REACTION_ADD")) {
                return .{ .message_reaction_add = try std.json.innerParseFromValue(EventData.MessageReactionAdd, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "REACTION_REMOVE")) {
                return .{ .message_reaction_remove = try std.json.innerParseFromValue(EventData.MessageReactionRemove, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "REACTION_REMOVE_ALL")) {
                return .{ .message_reaction_remove_all = try std.json.innerParseFromValue(EventData.MessageReactionRemoveAll, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "REACTION_REMOVE_EMOJI")) {
                return .{ .message_reaction_remove_emoji = try std.json.innerParseFromValue(EventData.MessageReactionRemoveEmoji, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "POLL_VOTE_ADD")) {
                return .{ .message_poll_vote = try std.json.innerParseFromValue(EventData.MessagePollVote, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "POLL_VOTE_REMOVE")) {
                return .{ .message_poll_vote = try std.json.innerParseFromValue(EventData.MessagePollVote, alloc, value, .{}) };
            }
        }

        if (std.mem.eql(u8, typee, "PRESENCE_UPDATE")) {
            return .{ .presence_update = try std.json.innerParseFromValue(EventData.PresenceUpdate, alloc, value, .{}) };
        }

        const stage_instance_prefix = "STAGE_INSTANCE_";
        if (std.mem.startsWith(u8, typee, stage_instance_prefix)) {
            const suffix = typee[stage_instance_prefix.len..];

            if (std.mem.eql(u8, suffix, "CREATE")) {
                return .{ .stage_instance = try std.json.innerParseFromValue(model.guild.StageInstance, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "UPDATE")) {
                return .{ .stage_instance = try std.json.innerParseFromValue(model.guild.StageInstance, alloc, value, .{}) };
            }
            if (std.mem.eql(u8, suffix, "DELETE")) {
                return .{ .stage_instance = try std.json.innerParseFromValue(model.guild.StageInstance, alloc, value, .{}) };
            }
        }

        if (std.mem.eql(u8, typee, "TYPING_START")) {
            return .{ .typing_start = try std.json.innerParseFromValue(EventData.TypingStart, alloc, value, .{}) };
        }
        if (std.mem.eql(u8, typee, "USER_UPDATE")) {
            return .{ .user = try std.json.innerParseFromValue(model.User, alloc, value, .{}) };
        }
        if (std.mem.eql(u8, typee, "VOICE_STATE_UPDATE")) {
            return .{ .voice_state = try std.json.innerParseFromValue(model.voice.VoiceState, alloc, value, .{}) };
        }
        if (std.mem.eql(u8, typee, "VOICE_SERVER_UPDATE")) {
            return .{ .voice_server_update = try std.json.innerParseFromValue(EventData.VoiceServerUpdate, alloc, value, .{}) };
        }
        if (std.mem.eql(u8, typee, "WEBHOOKS_UPDATE")) {
            return .{ .webooks_update = try std.json.innerParseFromValue(EventData.WebhooksUpdate, alloc, value, .{}) };
        }

        return .{ .unknown = value };
    }

    fn parseHello(value: std.json.Value) !EventData {
        const heartbeat_interval = if (value == .integer) value.integer else return error.HeartbeatIntervalShouldBeInteger;
        return .{ .hello = .{ .heartbeat_interval = heartbeat_interval } };
    }

    fn parseInvalidSession(value: std.json.Value) !EventData {
        const resumable = if (value == .bool) value.bool else return error.InvalidSessionShouldBeBool;
        return .{ .invalid_session = resumable };
    }
};

pub const EventData = union(Opcode) {
    none: void,
    number: i64,
    hello: Hello,
    ready: Ready,
    identify: Identify,
    invalid_session: bool,
    application_commands_permissions: model.interaction.command.ApplicationCommandPermissions,
    auto_moderation_rule: model.AutoModerationRule,
    auto_moderation_action_execution_event: AutoModerationActionExecutionEvent,
    channel: model.guild.channel.Channel,
    channel_pin_update: ChannelPinsUpdate,
    thread_delete: ThreadDelete,
    thread_list_sync: ThreadListSync,
    thread_member_update: ThreadMemberUpdate,
    thread_members_update: ThreadMembersUpdate,
    guild: model.guild.Guild,
    guild_create: GuildCreate,
    unavailable_guild: model.guild.UnavailableGuild,
    entitlement: model.Entitlement,
    audit_log_entry_create: AuditLogEntryCreate,
    guild_and_user: GuildAndUser,
    guild_and_emojis: GuildAndEmojis,
    guild_and_stickers: GuildAndStickers,
    guild_id: GuildId,
    guild_member_update: GuildMemberUpdate,
    guild_members_chunk: GuildMembersChunk,
    guild_and_role: GuildAndRole,
    guild_scheduled_event: model.guild.GuildScheduledEvent,
    guild_event_and_user: GuildEventAndUser,
    integration_with_guild_id: IntegrationWithGuildId,
    integration_delete: IntegrationDelete,
    interaction: model.interaction.Interaction,
    invite_create: InviteCreate,
    invite_delete: InviteDelete,
    message_update: MessageUpdate,
    message_reaction_add: MessageReactionAdd,
    message_reaction_remove: MessageReactionRemove,
    message_reaction_remove_all: MessageReactionRemoveAll,
    message_reaction_remove_emoji: MessageReactionRemoveEmoji,
    presence_update: PresenceUpdate,
    stage_instance: model.guild.StageInstance,
    typing_start: TypingStart,
    user: model.User,
    voice_state: model.voice.VoiceState,
    voice_server_update: VoiceServerUpdate,
    webhooks_update: WebhooksUpdate,
    message_poll_vote: MessagePollVote,

    unknown: ?std.json.Value,

    pub const jsonStringify = deanson.stringifyUnionInline;

    pub const Hello = struct { heartbeat_interval: i64 };
    pub const Ready = struct {
        v: i64,
        user: model.User,
        guilds: []const model.guild.UnavailableGuild,
        session_id: []const u8,
        resume_gateway_url: []const u8,
        shard: [2]i64,
        application: PartialApplication,

        pub const PartialApplication = struct {
            id: model.Snowflake,
            flags: deanson.Omittable(model.Application.Flags) = .{ .omitted = void{} },

            pub const jsonStringify = deanson.stringifyWithOmit;
        };

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const Identify = struct {
        token: []const u8,
        properties: ConnectionProperties,
        compress: Omittable(bool) = .{ .omitted = void{} },
        large_threshold: Omittable(i64) = .{ .omitted = void{} },
        shard: Omittable([2]i64) = .{ .omitted = void{} },
        presence: Omittable(PresenceUpdate) = .{ .omitted = void{} },
        intents: i64,

        pub const jsonStringify = deanson.stringifyWithOmit;

        pub const ConnectionProperties = struct {
            os: []const u8,
            browser: []const u8,
            device: []const u8,
        };
    };
    pub const AutoModerationActionExecutionEvent = struct {
        guild_id: model.Snowflake,
        action: model.AutoModerationAction,
        rule_id: model.Snowflake,
        rule_trigger_type: TriggerType,
        user_id: model.Snowflake,
        channel_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        message_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        alert_system_message_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        content: Omittable([]const u8) = .{ .omitted = void{} },
        matched_keyword: ?[]const u8,
        matched_content: Omittable(?[]const u8) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;

        pub const TriggerType = enum(u8) {
            keyword = 1,
            spam = 3,
            keyword_preset = 4,
            mention_spam = 5,
            member_profile = 6,

            pub const jsonStringify = deanson.stringifyEnumAsInt;
        };
    };
    pub const ChannelPinsUpdate = struct {
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        channel_id: model.Snowflake,
        last_pin_timestamp: Omittable([]const u8) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const ThreadDelete = struct {
        id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        parent_id: Omittable(?model.Snowflake) = .{ .omitted = void{} },
        type: model.guild.channel.Type,

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const ThreadListSync = struct {
        guild_id: model.Snowflake,
        channel_ids: Omittable([]const model.Snowflake) = .{ .omitted = void{} },
        threads: []const model.guild.channel.Channel,
        members: []const model.guild.channel.ThreadMember,

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const ThreadMemberUpdate = deanson.Extend(
        model.guild.channel.ThreadMember,
        struct {
            guild_id: model.Snowflake,

            pub const jsonStringify = deanson.stringifyWithOmit;
        },
    );
    pub const ThreadMembersUpdate = struct {
        id: model.Snowflake,
        guild_id: model.Snowflake,
        member_count: i64,
        added_members: Omittable([]const model.guild.channel.ThreadMember) = .{ .omitted = void{} },
        removed_member_ids: Omittable([]const model.Snowflake) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const GuildCreate = union(enum) {
        available: deanson.Extend(model.guild.Guild, struct {
            joined_at: []const u8,
            large: bool,
            unavailable: Omittable(bool) = .{ .omitted = void{} },
            member_count: i64,
            voice_states: []const model.voice.VoiceState,
            members: []const model.guild.Member,
            presences: []const PresenceUpdate,
            stage_instances: []const model.guild.StageInstance,
            guild_scheduled_events: []const model.guild.GuildScheduledEvent,

            pub const jsonStringify = deanson.stringifyWithOmit;
        }),
        unavailable: model.guild.UnavailableGuild,
    };

    pub const PresenceUpdate = struct {
        /// discord decided to be a little funny and document that the user field
        /// for this event in particular could have any arrangement of fields,
        /// and that types aren't guaranteed to be accurate.
        /// The only guarantee is that the `id` field will be sent.
        ///
        /// see https://discord.com/developers/docs/topics/gateway-events#presence-update
        user: std.json.Value,
        guild_id: model.Snowflake,
        status: []const u8,
        activities: []const Activity,
        client_status: ClientStatus,

        pub const Activity = struct {
            name: []const u8,
            type: i64,
            url: Omittable(?[]const u8) = .{ .omitted = void{} },
            created_at: i64,
            timestamps: Omittable(Timestamp) = .{ .omitted = void{} },
            application_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
            details: Omittable(?[]const u8) = .{ .omitted = void{} },
            state: Omittable(?[]const u8) = .{ .omitted = void{} },
            emoji: Omittable(?Emoji) = .{ .omitted = void{} },
            party: Omittable(Party) = .{ .omitted = void{} },
            assets: Omittable(Assets) = .{ .omitted = void{} },
            secrets: Omittable(Secrets) = .{ .omitted = void{} },
            instance: Omittable(bool) = .{ .omitted = void{} },
            flags: Omittable(Flags) = .{ .omitted = void{} },
            buttons: Omittable(Button) = .{ .omitted = void{} },

            pub const jsonStringify = deanson.stringifyWithOmit;

            pub const Timestamp = struct {
                start: i64,
                end: i64,
            };
            pub const Type = enum(u8) {
                game = 0,
                streaming = 1,
                listening = 2,
                watching = 3,
                custom = 4,
                competing = 5,
            };
            pub const Emoji = struct {
                name: []const u8,
                id: Omittable(model.Snowflake) = .{ .omitted = void{} },
                animated: Omittable(bool) = .{ .omitted = void{} },

                pub const jsonStringify = deanson.stringifyWithOmit;
            };
            pub const Party = struct {
                id: Omittable([]const u8) = .{ .omitted = void{} },
                size: Omittable([2]i64) = .{ .omitted = void{} },

                pub const jsonStringify = deanson.stringifyWithOmit;
            };
            pub const Assets = struct {
                large_image: Omittable([]const u8) = .{ .omitted = void{} },
                large_text: Omittable([]const u8) = .{ .omitted = void{} },
                small_image: Omittable([]const u8) = .{ .omitted = void{} },
                small_text: Omittable([]const u8) = .{ .omitted = void{} },

                pub const jsonStringify = deanson.stringifyWithOmit;
            };
            pub const Secrets = struct {
                join: Omittable([]const u8) = .{ .omitted = void{} },
                spectate: Omittable([]const u8) = .{ .omitted = void{} },
                match: Omittable([]const u8) = .{ .omitted = void{} },

                pub const jsonStringify = deanson.stringifyWithOmit;
            };
            pub const Flags = model.Flags(enum(u6) {
                instance = 0,
                join = 1,
                spectate = 2,
                join_request = 3,
                sync = 4,
                play = 5,
                party_privacy_friends = 6,
                party_privacy_voice_channel = 7,
                embedded = 8,
            });
            pub const Button = struct {
                label: []const u8,
                url: []const u8,
            };
        };
        pub const ClientStatus = struct {
            desktop: Omittable([]const u8) = .{ .omitted = void{} },
            mobile: Omittable([]const u8) = .{ .omitted = void{} },
            web: Omittable([]const u8) = .{ .omitted = void{} },

            pub const jsonStringify = deanson.stringifyWithOmit;
        };
    };
    pub const AuditLogEntryCreate = deanson.Extend(
        model.AuditLog.Entry,
        struct {
            guild_id: model.Snowflake,

            pub const jsonStringify = deanson.stringifyWithOmit;
        },
    );
    pub const GuildAndUser = struct {
        guild_id: model.Snowflake,
        user: model.User,
    };
    pub const GuildAndEmojis = struct {
        guild_id: model.Snowflake,
        emojis: []const model.Emoji,
    };
    pub const GuildAndStickers = struct {
        guild_id: model.Snowflake,
        stickers: []const model.Sticker,
    };
    pub const GuildId = struct {
        guild_id: model.Snowflake,
    };
    pub const GuildMemberUpdate = struct {
        guild_id: model.Snowflake,
        roles: []const model.Snowflake,
        user: model.User,
        nick: Omittable(?[]const u8) = .{ .omitted = void{} },
        avatar: ?[]const u8,
        joined_at: ?[]const u8,
        premium_since: Omittable(?[]const u8) = .{ .omitted = void{} },
        deaf: Omittable(bool) = .{ .omitted = void{} },
        mute: Omittable(bool) = .{ .omitted = void{} },
        pending: Omittable(bool) = .{ .omitted = void{} },
        communication_disabled_until: Omittable(?[]const u8) = .{ .omitted = void{} },
        flags: Omittable(model.guild.Member.Flags) = .{ .omitted = void{} },
        avatar_decoration_data: Omittable(model.User.AvatarDecorationData) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const GuildMembersChunk = struct {
        guild_id: model.Snowflake,
        members: []const model.guild.Member,
        chunk_index: i64,
        chunk_count: i64,
        not_found: Omittable([]const model.Snowflake) = .{ .omitted = void{} },
        presences: Omittable([]const PresenceUpdate) = .{ .omitted = void{} },
        nonce: Omittable([]const u8) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const GuildAndRole = struct {
        guild_id: model.Snowflake,
        role: model.guild.Role,
    };
    pub const GuildAndRoleId = struct {
        guild_id: model.Snowflake,
        role_id: model.Snowflake,
    };
    pub const GuildEventAndUser = struct {
        guild_scheduled_event_id: model.Snowflake,
        user_id: model.Snowflake,
        guild_id: model.Snowflake,
    };
    pub const IntegrationWithGuildId = deanson.Extend(
        model.guild.Integration,
        struct {
            guild_id: model.Snowflake,
            pub const jsonStringify = deanson.stringifyWithOmit;
        },
    );
    pub const IntegrationDelete = struct {
        id: model.Snowflake,
        guild_id: model.Snowflake,
        application_id: Omittable(model.Snowflake) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const InviteCreate = struct {
        channel_id: model.Snowflake,
        code: []const u8,
        created_at: []const u8,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        inviter: Omittable(model.User) = .{ .omitted = void{} },
        max_age: i64,
        max_uses: i64,
        target_type: Omittable(TargetType) = .{ .omitted = void{} },
        target_user: Omittable(model.User) = .{ .omitted = void{} },
        // says "partial application" but doesn't say what's excluded
        target_application: Omittable(std.json.Value) = .{ .omitted = void{} },
        temporary: bool,
        uses: i64,

        pub const jsonStringify = deanson.stringifyWithOmit;

        pub const TargetType = enum(u2) {
            stream = 1,
            embedded_application = 2,

            pub const jsonStringify = deanson.stringifyEnumAsInt;
        };
    };
    pub const InviteDelete = struct {
        channel_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        code: []const u8,

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const MessageUpdate = deanson.Extend(
        model.Message,
        struct {
            guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
            // says "partial member" but doesn't say what's excluded
            member: Omittable(std.json.Value) = .{ .omitted = void{} },
            mentions: []const MentionedUser,

            pub const jsonStringify = deanson.stringifyWithOmit;

            pub const MentionedUser = deanson.Extend(
                model.User,
                struct {
                    // says "partial member" but doesn't say what's excluded
                    member: std.json.Value,

                    pub const jsonStringify = deanson.stringifyWithOmit;
                },
            );
        },
    );
    pub const MessageDelete = struct {
        id: model.Snowflake,
        channel_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const MessageDeleteBulk = struct {
        ids: []const model.Snowflake,
        channel_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const MessageReactionAdd = struct {
        user_id: model.Snowflake,
        channel_id: model.Snowflake,
        message_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        member: Omittable(model.guild.Member) = .{ .omitted = void{} },
        emoji: model.Emoji,
        message_author_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        burst: bool,
        burst_colors: []const []const u8,
        type: Type,

        pub const jsonStringify = deanson.stringifyWithOmit;

        pub const Type = enum(u1) {
            normal = 0,
            burst = 1,
        };
    };
    pub const MessageReactionRemove = struct {
        user_id: model.Snowflake,
        channel_id: model.Snowflake,
        message_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        emoji: model.Emoji,
        burst: bool,
        type: Type,

        pub const jsonStringify = deanson.stringifyWithOmit;

        pub const Type = enum(u1) {
            normal = 0,
            burst = 1,
        };
    };
    pub const MessageReactionRemoveAll = struct {
        channel_id: model.Snowflake,
        message_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const MessageReactionRemoveEmoji = struct {
        channel_id: model.Snowflake,
        message_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        emoji: model.Emoji,

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const TypingStart = struct {
        channel_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        user_id: model.Snowflake,
        timestamp: i64,
        member: model.guild.Member,

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
    pub const VoiceServerUpdate = struct {
        token: []const u8,
        guild_id: model.Snowflake,
        endpoint: ?[]const u8,
    };
    pub const WebhooksUpdate = struct {
        guild_id: model.Snowflake,
        channel_id: model.Snowflake,
    };
    pub const MessagePollVote = struct {
        user_id: model.Snowflake,
        channel_id: model.Snowflake,
        message_id: model.Snowflake,
        guild_id: Omittable(model.Snowflake) = .{ .omitted = void{} },
        answer_id: i64,

        pub const jsonStringify = deanson.stringifyWithOmit;
    };
};
