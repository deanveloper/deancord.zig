const std = @import("std");
const zigtime = @import("zig-time");
const deancord = @import("../root.zig");
const model = deancord.model;
const Snowflake = model.Snowflake;
const deanson = model.deanson;

const Message = @This();

id: Snowflake,
channel_id: Snowflake,
author: MessageAuthor,
content: []const u8,
timestamp: []zigtime.DateTime,
edited_timestamp: ?[]zigtime.DateTime,
tts: bool,
mention_everyone: bool,
mentions: []const model.User,
mention_roles: []const model.Role,
mention_channels: deanson.Omittable([]const ChannelMention) = .omit,
attachments: []const Attachment,
embeds: []const Embed,
reactions: deanson.Omittable([]const Reaction) = .omit,
nonce: deanson.Omittable(Nonce) = .omit,
pinned: bool,
webhook_id: deanson.Omittable(Snowflake) = .omit,
type: Type,
activity: deanson.Omittable(Activity) = .omit,
application: deanson.Omittable(deanson.Partial(model.Application)) = .omit,
application_id: deanson.Omittable(Snowflake) = .omit,
message_reference: deanson.Omittable(Reference) = .omit,
flags: deanson.Omittable(Flags) = .omit,
referenced_message: deanson.Omittable(?*const Message) = .omit,
interaction_metadata: InteractionMetadata,
thread: deanson.Omittable(model.Channel) = .omit,
components: deanson.Omittable([]const model.MessageComponent) = .omit,
sticker_items: deanson.Omittable([]const model.Sticker.Item) = .omit,
stickers: deanson.Omittable([]const model.Sticker) = .omit,
position: deanson.Omittable(i64) = .omit,
role_subscription_data: deanson.Omittable(RoleSubscriptionData) = .omit,
resolved: deanson.Omittable(model.interaction.ResolvedData) = .omit,
poll: deanson.Omittable(model.Poll) = .omit,
call: deanson.Omittable(Call) = .omit,

pub const jsonStringify = model.deanson.stringifyWithOmit;

pub const MessageAuthor = union(enum) {
    user: model.User,
    webhook: struct {
        id: Snowflake,
        username: []const u8,
        avatar: ?[]const u8,
    },

    pub const jsonStringify = model.deanson.stringifyUnionInline;
};

pub const Attachment = struct {
    id: Snowflake,
    filename: []const u8,
    description: deanson.Omittable([]const u8) = .omit,
    content_type: deanson.Omittable([]const u8) = .omit,
    size: u64,
    url: []const u8,
    proxy_url: []const u8,
    height: deanson.Omittable(?[]const u8) = .omit,
    width: deanson.Omittable(?[]const u8) = .omit,
    ephemeral: deanson.Omittable(bool) = .omit,
    duration_secs: deanson.Omittable(f64) = .omit,
    waveform: deanson.Omittable([]const u8) = .omit,
    flags: Flags,

    pub const jsonStringify = model.deanson.stringifyWithOmit;
};

pub const ChannelMention = struct {
    id: Snowflake,
    guild_id: Snowflake,
    type: model.Channel.Type,
    name: []const u8,
};

pub const Embed = struct {
    title: deanson.Omittable([]const u8) = .omit,
    type: deanson.Omittable(EmbedType) = .omit,
    description: deanson.Omittable([]const u8) = .omit,
    url: deanson.Omittable([]const u8) = .omit,
    timestamp: deanson.Omittable([]zigtime.DateTime) = .omit,
    color: deanson.Omittable(i64) = .omit,
    footer: deanson.Omittable(Footer) = .omit,
    image: deanson.Omittable(Media) = .omit,
    thumbnail: deanson.Omittable(Media) = .omit,
    video: deanson.Omittable(Media) = .omit,
    provider: deanson.Omittable(Provider) = .omit,
    author: deanson.Omittable(Author) = .omit,
    fields: deanson.Omittable([]const Field) = .omit,

    pub const jsonStringify = model.deanson.stringifyWithOmit;

    pub const EmbedType = enum {
        rich,
        image,
        video,
        gifv,
        article,
        link,

        // enums are encoded as string by default, no need for custom jsonStringify
    };

    pub const Footer = struct {
        text: []const u8,
        icon_url: deanson.Omittable([]const u8) = .omit,
        proxy_icon_url: deanson.Omittable([]const u8) = .omit,

        pub const jsonStringify = model.deanson.stringifyWithOmit;
    };

    pub const Media = struct {
        url: deanson.Omittable([]const u8) = .omit,
        proxy_url: deanson.Omittable([]const u8) = .omit,
        height: deanson.Omittable(i64) = .omit,
        width: deanson.Omittable(i64) = .omit,

        pub const jsonStringify = model.deanson.stringifyWithOmit;
    };

    pub const Provider = struct {
        name: deanson.Omittable([]const u8) = .omit,
        url: deanson.Omittable([]const u8) = .omit,

        pub const jsonStringify = model.deanson.stringifyWithOmit;
    };

    pub const Author = struct {
        name: []const u8,
        url: deanson.Omittable([]const u8) = .omit,
        icon_url: deanson.Omittable([]const u8) = .omit,
        proxy_icon_url: deanson.Omittable([]const u8) = .omit,

        pub const jsonStringify = model.deanson.stringifyWithOmit;
    };

    pub const Field = struct {
        name: []const u8,
        value: []const u8,
        @"inline": deanson.Omittable(bool) = .omit,
    };
};

pub const Reaction = struct {
    count: i64,
    count_details: CountDetails,
    me: bool,
    me_burst: bool,
    emoji: deanson.Partial(model.Emoji),
    burst_colors: []const i64,

    pub const CountDetails = struct {
        burst: i64,
        normal: i64,
    };
};

pub const Nonce = union(enum) {
    int: i64,
    str: []const u8,

    pub const jsonStringify = model.deanson.stringifyUnionInline;

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, _: std.json.ParseOptions) !Nonce {
        const token = try source.nextAlloc(allocator, .alloc_if_needed);
        switch (token) {
            .number, .allocated_number => |number_str| {
                const number = try std.fmt.parseInt(i64, number_str, 10);
                return .{ .int = number };
            },
            .string, .allocated_string => |string| {
                return .{ .str = string };
            },
            else => return error.UnexpectedToken,
        }
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, source: std.json.Value, _: std.json.ParseOptions) !Nonce {
        return switch (source) {
            .integer => |int| .{ .int = int },
            .string, .number_string => |str| .{ .str = str },
            else => error.UnexpectedType,
        };
    }
};

pub const Type = enum(u8) {
    default = 0,
    recipient_add = 1,
    recipient_remove = 2,
    call = 3,
    channel_name_change = 4,
    channel_icon_change = 5,
    channel_pinned_message = 6,
    user_join = 7,
    guild_boost = 8,
    guild_boost_tier_1 = 9,
    guild_boost_tier_2 = 10,
    guild_boost_tier_3 = 11,
    channel_follow_add = 12,
    guild_discovery_disqualified = 14,
    guild_discovery_requalified = 15,
    guild_discovery_grace_period_initial_warning = 16,
    guild_discovery_grace_period_final_warning = 17,
    thread_created = 18,
    reply = 19,
    chat_input_command = 20,
    thread_starter_message = 21,
    guild_invite_reminder = 22,
    context_menu_command = 23,
    auto_moderation_action = 24,
    role_subscription_purchase = 25,
    interaction_premium_upsell = 26,
    stage_start = 27,
    stage_end = 28,
    stage_speaker = 29,
    stage_topic = 31,
    guild_application_premium_subscription = 32,
    guild_incident_alert_mode_enabled = 36,
    guild_incident_alert_mode_disabled = 37,
    guild_incident_report_raid = 38,
    guild_incident_report_false_alarm = 39,
    purchase_notification = 44,
    _,

    pub const jsonStringify = model.deanson.stringifyEnumAsInt;
};

pub const Activity = struct {
    type: ActivityType,
    party_id: deanson.Omittable([]const u8) = .omit,

    pub const ActivityType = enum(u3) {
        join = 1,
        spectate = 2,
        listen = 3,
        join_request = 5,

        pub const jsonStringify = model.deanson.stringifyEnumAsInt;
    };
};

pub const Reference = struct {
    message_id: deanson.Omittable(Snowflake) = .omit,
    channel_id: deanson.Omittable(Snowflake) = .omit,
    guild_id: deanson.Omittable(Snowflake) = .omit,
    fail_if_not_exists: deanson.Omittable(bool) = .omit,
};

pub const Flags = model.Flags(enum {
    crossposted,
    is_crosspost,
    suppress_embeds,
    source_message_deleted,
    urgent,
    has_thread,
    ephemeral,
    loading,
    failed_to_mention_some_roles_in_thread,
    suppress_notifications,
    is_voice_message,
});

pub const InteractionMetadata = struct {
    id: Snowflake,
    type: model.interaction.InteractionType,
    user: model.User,
    authorizing_integration_owners: std.json.Value, // TODO: https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-authorizing-integration-owners-object
    original_response_message_id: deanson.Omittable(Snowflake) = .omit,
    interacted_message_id: deanson.Omittable(Snowflake) = .omit,
    triggering_interaction_metadata: deanson.Omittable(?*const InteractionMetadata) = .omit,

    pub const jsonStringify = model.deanson.stringifyWithOmit;
};

pub const RoleSubscriptionData = struct {
    role_subscription_listing_id: Snowflake,
    tier_name: []const u8,
    total_months_subscribed: i64,
    is_renwal: bool,
};

pub const Call = struct {
    participants: []const Snowflake,
    ended_timestamp: deanson.Omittable(?[]zigtime.DateTime) = .omit,

    pub const jsonStringify = model.deanson.stringifyWithOmit;
};

pub const AllowedMentions = struct {
    parse: []const AllowedMentionsType,
    roles: []const Snowflake,
    users: []const Snowflake,
    replied_user: bool,

    pub const AllowedMentionsType = enum {
        roles,
        users,
        everyone,
    };
};
