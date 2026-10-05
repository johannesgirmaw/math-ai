import {
  boolean,
  date,
  index,
  integer,
  jsonb,
  numeric,
  pgTable,
  primaryKey,
  text,
  timestamp,
  unique,
  uuid,
} from "drizzle-orm/pg-core";

export const user = pgTable("user", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  emailVerified: boolean("email_verified").notNull().default(false),
  image: text("image"),
  role: text("role").notNull().default("learner"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const session = pgTable(
  "session",
  {
    id: text("id").primaryKey(),
    expiresAt: timestamp("expires_at").notNull(),
    token: text("token").notNull().unique(),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
    ipAddress: text("ip_address"),
    userAgent: text("user_agent"),
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
  },
  (table) => [index("session_user_id_idx").on(table.userId)],
);

export const account = pgTable(
  "account",
  {
    id: text("id").primaryKey(),
    accountId: text("account_id").notNull(),
    providerId: text("provider_id").notNull(),
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
    accessToken: text("access_token"),
    refreshToken: text("refresh_token"),
    idToken: text("id_token"),
    accessTokenExpiresAt: timestamp("access_token_expires_at"),
    refreshTokenExpiresAt: timestamp("refresh_token_expires_at"),
    scope: text("scope"),
    password: text("password"),
    createdAt: timestamp("created_at").notNull().defaultNow(),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (table) => [index("account_user_id_idx").on(table.userId)],
);

export const verification = pgTable("verification", {
  id: text("id").primaryKey(),
  identifier: text("identifier").notNull(),
  value: text("value").notNull(),
  expiresAt: timestamp("expires_at").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
  updatedAt: timestamp("updated_at").defaultNow(),
});

export const profiles = pgTable("profiles", {
  userId: text("user_id")
    .primaryKey()
    .references(() => user.id, { onDelete: "cascade" }),
  displayName: text("display_name").notNull(),
  dailyGoalMinutes: integer("daily_goal_minutes").notNull().default(5),
  timezone: text("timezone").notNull().default("UTC"),
  onboardingCompletedAt: timestamp("onboarding_completed_at"),
  placementSkillId: uuid("placement_skill_id"),
});

export const worlds = pgTable("worlds", {
  id: uuid("id").primaryKey(),
  slug: text("slug").notNull().unique(),
  title: text("title").notNull(),
  sortOrder: integer("sort_order").notNull(),
});

export const skillNodes = pgTable(
  "skill_nodes",
  {
    id: uuid("id").primaryKey(),
    worldId: uuid("world_id")
      .notNull()
      .references(() => worlds.id),
    slug: text("slug").notNull(),
    title: text("title").notNull(),
    promise: text("promise").notNull(),
    prereqIds: uuid("prereq_ids").array().notNull().default([]),
    sortOrder: integer("sort_order").notNull(),
    pipAbility: text("pip_ability").notNull(),
    status: text("status").notNull().default("published"),
  },
  (table) => [unique("skill_world_slug").on(table.worldId, table.slug), index("skill_world_order_idx").on(table.worldId, table.sortOrder)],
);

export const lessons = pgTable(
  "lessons",
  {
    id: uuid("id").primaryKey(),
    skillNodeId: uuid("skill_node_id")
      .notNull()
      .references(() => skillNodes.id),
    title: text("title").notNull(),
    version: integer("version").notNull(),
    status: text("status").notNull().default("draft"),
    definition: jsonb("definition").notNull(),
  },
  (table) => [index("lesson_skill_status_idx").on(table.skillNodeId, table.status)],
);

export const contentPacks = pgTable("content_packs", {
  id: uuid("id").primaryKey(),
  version: text("version").notNull().unique(),
  sha256: text("sha256").notNull(),
  manifest: jsonb("manifest").notNull(),
  body: jsonb("body").notNull(),
  publishedAt: timestamp("published_at").notNull().defaultNow(),
});

export const lessonAttempts = pgTable("lesson_attempts", {
  id: uuid("id").primaryKey(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  lessonId: uuid("lesson_id").notNull(),
  startedAt: timestamp("started_at").notNull().defaultNow(),
  completedAt: timestamp("completed_at"),
});

export const itemResults = pgTable(
  "item_results",
  {
    id: uuid("id").primaryKey(),
    attemptId: uuid("attempt_id")
      .notNull()
      .references(() => lessonAttempts.id, { onDelete: "cascade" }),
    screenId: text("screen_id").notNull(),
    correct: boolean("correct").notNull(),
    latencyMs: integer("latency_ms").notNull(),
    errorCode: text("error_code"),
    hadMiss: boolean("had_miss").notNull().default(false),
    skillNodeId: uuid("skill_node_id").notNull(),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [index("item_results_attempt_idx").on(table.attemptId)],
);

export const skillMastery = pgTable(
  "skill_mastery",
  {
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
    skillNodeId: uuid("skill_node_id")
      .notNull()
      .references(() => skillNodes.id),
    score: numeric("score", { precision: 6, scale: 5 }).notNull().default("0"),
    attempts: integer("attempts").notNull().default(0),
    correctCount: integer("correct_count").notNull().default(0),
    recent: jsonb("recent").notNull().default([]),
    updatedAt: timestamp("updated_at").notNull().defaultNow(),
  },
  (table) => [primaryKey({ columns: [table.userId, table.skillNodeId] })],
);

export const reviewCards = pgTable(
  "review_cards",
  {
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
    skillNodeId: uuid("skill_node_id")
      .notNull()
      .references(() => skillNodes.id),
    dueAt: timestamp("due_at").notNull(),
    stability: numeric("stability").notNull(),
    difficulty: numeric("difficulty").notNull(),
    reps: integer("reps").notNull().default(0),
    lapses: integer("lapses").notNull().default(0),
    state: text("state").notNull(),
    fsrs: jsonb("fsrs").notNull(),
  },
  (table) => [
    primaryKey({ columns: [table.userId, table.skillNodeId] }),
    index("review_due_idx").on(table.userId, table.dueAt),
  ],
);

export const streaks = pgTable("streaks", {
  userId: text("user_id")
    .primaryKey()
    .references(() => user.id, { onDelete: "cascade" }),
  current: integer("current").notNull().default(0),
  longest: integer("longest").notNull().default(0),
  lastActiveDate: date("last_active_date"),
  freezes: integer("freezes").notNull().default(2),
});

export const xpEvents = pgTable(
  "xp_events",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: text("user_id")
      .notNull()
      .references(() => user.id, { onDelete: "cascade" }),
    amount: integer("amount").notNull(),
    reason: text("reason").notNull(),
    idempotencyKey: text("idempotency_key").notNull().unique(),
    createdAt: timestamp("created_at").notNull().defaultNow(),
  },
  (table) => [index("xp_user_created_idx").on(table.userId, table.createdAt)],
);

export const placementSessions = pgTable("placement_sessions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: text("user_id")
    .notNull()
    .references(() => user.id, { onDelete: "cascade" }),
  low: integer("low").notNull(),
  high: integer("high").notNull(),
  asked: integer("asked").notNull().default(0),
  recommendedSkillId: uuid("recommended_skill_id"),
  completedAt: timestamp("completed_at"),
});

export const placementAnswers = pgTable("placement_answers", {
  id: uuid("id").primaryKey().defaultRandom(),
  sessionId: uuid("session_id")
    .notNull()
    .references(() => placementSessions.id, { onDelete: "cascade" }),
  skillNodeId: uuid("skill_node_id").notNull(),
  correct: boolean("correct").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const waitlistEmails = pgTable("waitlist_emails", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: text("email").notNull().unique(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const auditLog = pgTable("audit_log", {
  id: uuid("id").primaryKey().defaultRandom(),
  actorId: text("actor_id").notNull(),
  action: text("action").notNull(),
  entity: text("entity").notNull(),
  entityId: text("entity_id").notNull(),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
