CREATE TABLE "account" (
	"id" text PRIMARY KEY NOT NULL,
	"account_id" text NOT NULL,
	"provider_id" text NOT NULL,
	"user_id" text NOT NULL,
	"access_token" text,
	"refresh_token" text,
	"id_token" text,
	"access_token_expires_at" timestamp,
	"refresh_token_expires_at" timestamp,
	"scope" text,
	"password" text,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "audit_log" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"actor_id" text NOT NULL,
	"action" text NOT NULL,
	"entity" text NOT NULL,
	"entity_id" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "content_packs" (
	"id" uuid PRIMARY KEY NOT NULL,
	"version" text NOT NULL,
	"sha256" text NOT NULL,
	"manifest" jsonb NOT NULL,
	"body" jsonb NOT NULL,
	"published_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "content_packs_version_unique" UNIQUE("version")
);
--> statement-breakpoint
CREATE TABLE "item_results" (
	"id" uuid PRIMARY KEY NOT NULL,
	"attempt_id" uuid NOT NULL,
	"screen_id" text NOT NULL,
	"correct" boolean NOT NULL,
	"latency_ms" integer NOT NULL,
	"error_code" text,
	"had_miss" boolean DEFAULT false NOT NULL,
	"skill_node_id" uuid NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "lesson_attempts" (
	"id" uuid PRIMARY KEY NOT NULL,
	"user_id" text NOT NULL,
	"lesson_id" uuid NOT NULL,
	"started_at" timestamp DEFAULT now() NOT NULL,
	"completed_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "lessons" (
	"id" uuid PRIMARY KEY NOT NULL,
	"skill_node_id" uuid NOT NULL,
	"title" text NOT NULL,
	"version" integer NOT NULL,
	"status" text DEFAULT 'draft' NOT NULL,
	"definition" jsonb NOT NULL,
	CONSTRAINT "lesson_skill_version" UNIQUE("skill_node_id","version")
);
--> statement-breakpoint
CREATE TABLE "placement_answers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"session_id" uuid NOT NULL,
	"skill_node_id" uuid NOT NULL,
	"correct" boolean NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "placement_sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" text NOT NULL,
	"low" integer NOT NULL,
	"high" integer NOT NULL,
	"asked" integer DEFAULT 0 NOT NULL,
	"recommended_skill_id" uuid,
	"completed_at" timestamp
);
--> statement-breakpoint
CREATE TABLE "profiles" (
	"user_id" text PRIMARY KEY NOT NULL,
	"display_name" text NOT NULL,
	"daily_goal_minutes" integer DEFAULT 5 NOT NULL,
	"timezone" text DEFAULT 'UTC' NOT NULL,
	"onboarding_completed_at" timestamp,
	"placement_skill_id" uuid
);
--> statement-breakpoint
CREATE TABLE "review_cards" (
	"user_id" text NOT NULL,
	"skill_node_id" uuid NOT NULL,
	"due_at" timestamp NOT NULL,
	"stability" numeric NOT NULL,
	"difficulty" numeric NOT NULL,
	"reps" integer DEFAULT 0 NOT NULL,
	"lapses" integer DEFAULT 0 NOT NULL,
	"state" text NOT NULL,
	"fsrs" jsonb NOT NULL,
	CONSTRAINT "review_cards_user_id_skill_node_id_pk" PRIMARY KEY("user_id","skill_node_id")
);
--> statement-breakpoint
CREATE TABLE "session" (
	"id" text PRIMARY KEY NOT NULL,
	"expires_at" timestamp NOT NULL,
	"token" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	"ip_address" text,
	"user_agent" text,
	"user_id" text NOT NULL,
	CONSTRAINT "session_token_unique" UNIQUE("token")
);
--> statement-breakpoint
CREATE TABLE "skill_mastery" (
	"user_id" text NOT NULL,
	"skill_node_id" uuid NOT NULL,
	"score" numeric(6, 5) DEFAULT '0' NOT NULL,
	"attempts" integer DEFAULT 0 NOT NULL,
	"correct_count" integer DEFAULT 0 NOT NULL,
	"recent" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "skill_mastery_user_id_skill_node_id_pk" PRIMARY KEY("user_id","skill_node_id")
);
--> statement-breakpoint
CREATE TABLE "skill_nodes" (
	"id" uuid PRIMARY KEY NOT NULL,
	"world_id" uuid NOT NULL,
	"slug" text NOT NULL,
	"title" text NOT NULL,
	"promise" text NOT NULL,
	"prereq_ids" uuid[] DEFAULT '{}' NOT NULL,
	"sort_order" integer NOT NULL,
	"pip_ability" text NOT NULL,
	"status" text DEFAULT 'published' NOT NULL,
	CONSTRAINT "skill_world_slug" UNIQUE("world_id","slug")
);
--> statement-breakpoint
CREATE TABLE "streaks" (
	"user_id" text PRIMARY KEY NOT NULL,
	"current" integer DEFAULT 0 NOT NULL,
	"longest" integer DEFAULT 0 NOT NULL,
	"last_active_date" date,
	"freezes" integer DEFAULT 2 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user" (
	"id" text PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"email" text NOT NULL,
	"email_verified" boolean DEFAULT false NOT NULL,
	"image" text,
	"role" text DEFAULT 'learner' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "user_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "verification" (
	"id" text PRIMARY KEY NOT NULL,
	"identifier" text NOT NULL,
	"value" text NOT NULL,
	"expires_at" timestamp NOT NULL,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "waitlist_emails" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "waitlist_emails_email_unique" UNIQUE("email")
);
--> statement-breakpoint
CREATE TABLE "worlds" (
	"id" uuid PRIMARY KEY NOT NULL,
	"slug" text NOT NULL,
	"title" text NOT NULL,
	"sort_order" integer NOT NULL,
	CONSTRAINT "worlds_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "xp_events" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" text NOT NULL,
	"amount" integer NOT NULL,
	"reason" text NOT NULL,
	"idempotency_key" text NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "xp_events_idempotency_key_unique" UNIQUE("idempotency_key")
);
--> statement-breakpoint
ALTER TABLE "account" ADD CONSTRAINT "account_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "item_results" ADD CONSTRAINT "item_results_attempt_id_lesson_attempts_id_fk" FOREIGN KEY ("attempt_id") REFERENCES "public"."lesson_attempts"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lesson_attempts" ADD CONSTRAINT "lesson_attempts_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lessons" ADD CONSTRAINT "lessons_skill_node_id_skill_nodes_id_fk" FOREIGN KEY ("skill_node_id") REFERENCES "public"."skill_nodes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "placement_answers" ADD CONSTRAINT "placement_answers_session_id_placement_sessions_id_fk" FOREIGN KEY ("session_id") REFERENCES "public"."placement_sessions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "placement_sessions" ADD CONSTRAINT "placement_sessions_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "profiles" ADD CONSTRAINT "profiles_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "review_cards" ADD CONSTRAINT "review_cards_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "review_cards" ADD CONSTRAINT "review_cards_skill_node_id_skill_nodes_id_fk" FOREIGN KEY ("skill_node_id") REFERENCES "public"."skill_nodes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "session" ADD CONSTRAINT "session_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "skill_mastery" ADD CONSTRAINT "skill_mastery_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "skill_mastery" ADD CONSTRAINT "skill_mastery_skill_node_id_skill_nodes_id_fk" FOREIGN KEY ("skill_node_id") REFERENCES "public"."skill_nodes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "skill_nodes" ADD CONSTRAINT "skill_nodes_world_id_worlds_id_fk" FOREIGN KEY ("world_id") REFERENCES "public"."worlds"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "streaks" ADD CONSTRAINT "streaks_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "xp_events" ADD CONSTRAINT "xp_events_user_id_user_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."user"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "account_user_id_idx" ON "account" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "item_results_attempt_idx" ON "item_results" USING btree ("attempt_id");--> statement-breakpoint
CREATE INDEX "lesson_skill_status_idx" ON "lessons" USING btree ("skill_node_id","status");--> statement-breakpoint
CREATE INDEX "review_due_idx" ON "review_cards" USING btree ("user_id","due_at");--> statement-breakpoint
CREATE INDEX "session_user_id_idx" ON "session" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "skill_world_order_idx" ON "skill_nodes" USING btree ("world_id","sort_order");--> statement-breakpoint
CREATE INDEX "xp_user_created_idx" ON "xp_events" USING btree ("user_id","created_at");