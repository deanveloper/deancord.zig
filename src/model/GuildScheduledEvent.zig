const std = @import("std");
const model = @import("../root.zig").model;
const jconfig = @import("../root.zig").jconfig;
const Omittable = jconfig.Omittable;

id: model.Snowflake,
guild_id: model.Snowflake,
channel_id: ?model.Snowflake,
creator_id: Omittable(?model.Snowflake) = .omit,
name: []const u8,
description: Omittable(?[]const u8) = .omit,
scheduled_start_time: model.IsoTime,
scheduled_end_time: ?model.IsoTime,
privacy_level: PrivacyLevel,
status: EventStatus,
entity_type: EntityType,
entity_id: ?model.Snowflake,
entity_metadata: ?EntityMetadata,
creator: Omittable(model.User) = .omit,
user_count: i64,
image: Omittable(?[]const u8) = .omit,

pub usingnamespace jconfig.OmittableFieldsMixin(@This());

pub const PrivacyLevel = enum(u2) {
    guild_only = 2,

    pub const jsonStringify = jconfig.stringifyEnumAsInt;
};
pub const EventStatus = enum(u3) {
    scheduled = 1,
    active = 2,
    completed = 3,
    canceled = 4,

    pub const jsonStringify = jconfig.stringifyEnumAsInt;
};
pub const EntityType = enum(u3) {
    stage_instance = 1,
    voice = 2,
    external = 3,
};
pub const EntityMetadata = struct {
    location: Omittable([]const u8) = .omit,

    pub usingnamespace jconfig.OmittableFieldsMixin(@This());
};
pub const EventUser = struct {
    guild_scheduled_event_id: model.Snowflake,
    user: model.User,
    member: Omittable(model.guild.Member),

    pub usingnamespace jconfig.OmittableFieldsMixin(@This());
};
