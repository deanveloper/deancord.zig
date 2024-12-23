const deancord = @import("../root.zig");
const model = deancord.model;
const Snowflake = model.Snowflake;
const User = model.User;
const Member = model.guild.Member;
const jconfig = deancord.jconfig;
const Omittable = jconfig.Omittable;

id: Snowflake,
type: Type,
guild_id: Omittable(Snowflake) = .omit,
position: Omittable(i64) = .omit,
permission_overwrites: Omittable([]const jconfig.Partial(PermissionOverwrite)) = .omit,
name: Omittable(?[]const u8) = .omit,
topic: Omittable(?[]const u8) = .omit,
nsfw: Omittable(bool) = .omit,
last_message_id: Omittable(?Snowflake) = .omit,
bitrate: Omittable(i64) = .omit,
user_limit: Omittable(i64) = .omit,
rate_limit_per_user: Omittable(i64) = .omit,
recipients: Omittable([]User) = .omit,
icon: Omittable(?[]const u8) = .omit,
owner_id: Omittable(Snowflake) = .omit,
application_id: Omittable(Snowflake) = .omit,
managed: Omittable(bool) = .omit,
parent_id: Omittable(?Snowflake) = .omit,
last_pin_timestamp: Omittable(?model.IsoTime) = .omit,
rtc_region: Omittable(?[]const u8) = .omit,
video_quality_mode: Omittable(VideoQualityMode) = .omit,
message_count: Omittable(i64) = .omit,
member_count: Omittable(i64) = .omit,
thread_metadata: Omittable(ThreadMetadata) = .omit,
member: Omittable(ThreadMember) = .omit,
default_auto_archive_duration: Omittable(i64) = .omit,
permissions: Omittable([]const u8) = .omit,
flags: Omittable(Flags) = .omit,
total_message_sent: Omittable(i64) = .omit,
available_tags: Omittable([]const Tag) = .omit,
applied_tags: Omittable([]const Snowflake) = .omit,
default_reaction_emoji: Omittable(?DefaultReaction) = .omit,
default_thread_rate_limit_per_user: Omittable(i64) = .omit,
default_sort_order: Omittable(?SortOrder) = .omit,
default_forum_layout: Omittable(ForumLayout) = .omit,
newly_created: Omittable(bool) = .omit,

pub const jsonStringify = jconfig.stringifyWithOmit;

pub const Type = enum(u8) {
    guild_text = 0,
    dm = 1,
    guild_voice = 2,
    group_dm = 3,
    guild_category = 4,
    guild_announcement = 5,
    announcement_thread = 10,
    public_thread = 11,
    private_thread = 12,
    guild_stage_voice = 13,
    guild_directory = 14,
    guild_forum = 15,
    guild_media = 16,

    pub const jsonStringify = jconfig.stringifyEnumAsInt;
};

pub const PermissionOverwrite = struct {
    id: Snowflake,
    type: enum {
        role,
        member,

        pub const jsonStringify = jconfig.stringifyEnumAsInt;
    },
    allow: []const u8,
    deny: []const u8,
};

// woah, discord actually used a data structure that follows how programming languages often define enums
pub const DefaultReaction = union(enum) {
    emoji_id: Snowflake,
    emoji_name: []const u8,
};

pub const Flags = packed struct(u64) {
    _unused: u1 = 0,

    // 1 << 1
    pinned: bool = false,

    _unused2: u2 = 0,

    // 1 << 4
    require_tag: bool = false,

    _unused3: u10 = 0,

    // 1 << 15
    hide_media_download_options: bool = false,

    _overflow: u48 = 0,

    pub usingnamespace model.PackedFlagsMixin(@This());
};

pub const ThreadMetadata = struct {
    archived: bool,
    auto_archive_duration: i64,
    archive_timestamp: model.IsoTime,
    locked: bool,
    invitable: Omittable(bool) = .omit,
    create_timestamp: Omittable(model.IsoTime) = .omit,

    pub const jsonStringify = jconfig.stringifyWithOmit;
};

pub const ThreadMember = struct {
    id: Omittable(Snowflake) = .omit,
    user_id: Omittable(Snowflake) = .omit,
    join_timestamp: model.IsoTime,
    flags: ThreadMember.Flags,
    member: Omittable(Member) = .omit,

    pub const jsonStringify = jconfig.stringifyWithOmit;

    pub const Flags = packed struct(u64) {
        notifications: bool = false,
        _overflow: u63 = 0,

        pub usingnamespace model.PackedFlagsMixin(@This());
    };
};

pub const VideoQualityMode = enum(u2) {
    auto = 1,
    full = 2,

    pub const jsonStringify = jconfig.stringifyEnumAsInt;
};

pub const Tag = struct {
    /// id of the tag
    id: Snowflake,
    /// name of the tag
    name: []const u8,
    /// whether this tag can only be added/removed by moderators
    moderated: bool,
    /// id of a guild-specific emoji
    emoji_id: ?Snowflake,
    /// unicode character representing an emoji
    emoji_name: ?[]const u8,
};

pub const Followed = struct {
    channel_id: Snowflake,
    webhook_id: Snowflake,
};

pub const SortOrder = enum(i64) {
    latest_activity = 0,
    creation_date = 1,
};

pub const ForumLayout = enum(i64) {
    not_set = 0,
    list_view = 1,
    gallery_view = 2,
};
