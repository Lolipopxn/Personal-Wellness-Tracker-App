-- Personal Wellness Tracker Database Schema

-- Create ENUMs
CREATE TYPE "gender" AS ENUM (
  'male',
  'female',
  'other'
);

CREATE TYPE "meal_type" AS ENUM (
  'breakfast',
  'lunch',
  'dinner',
  'snack'
);

CREATE TYPE "theme" AS ENUM (
  'light',
  'dark',
  'system'
);

CREATE TYPE "weight_unit" AS ENUM (
  'kg',
  'lbs'
);

CREATE TYPE "height_unit" AS ENUM (
  'cm',
  'ft_in'
);

CREATE TYPE "temperature_unit" AS ENUM (
  'celsius',
  'fahrenheit'
);

-- Create Tables
CREATE TABLE "users" (
  "uid" varchar PRIMARY KEY,
  "email" varchar NOT NULL,
  "password_hash" varchar NOT NULL,
  "username" varchar,
  "age" integer,
  "gender" gender,
  "weight" double precision,
  "height" double precision,
  "profile_completed" boolean DEFAULT false,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now()),
  "health_problems" text[],
  "saved_days_count" integer DEFAULT 0,
  "day_streak" integer DEFAULT 0,
  "last_updated" timestamp DEFAULT (now())
);

CREATE TABLE "user_goals" (
  "id" varchar PRIMARY KEY,
  "user_id" varchar NOT NULL,
  "goal_weight" double precision,
  "goal_exercise_frequency_week" integer,
  "goal_exercise_minutes" integer,
  "goal_water_intake" integer,
  "goal_calorie_intake" integer,
  "goal_sleep_hours" double precision,
  "activity_level" varchar,
  "goal_timeframe" varchar,
  "is_active" boolean DEFAULT true,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "food_logs" (
  "id" varchar PRIMARY KEY,
  "user_id" varchar NOT NULL,
  "date" date NOT NULL,
  "total_calories" integer DEFAULT 0,
  "meal_count" integer DEFAULT 0
);

CREATE TABLE "meals" (
  "id" varchar PRIMARY KEY,
  "food_log_id" varchar NOT NULL,
  "user_id" varchar NOT NULL,
  "food_name" varchar,
  "meal_type" meal_type,
  "description" text,
  "calories" integer DEFAULT 0,
  "protein" double precision,
  "carbs" double precision,
  "fat" double precision,
  "fiber" double precision,
  "sugar" double precision,
  "has_nutrition_data" boolean DEFAULT false,
  "image_url" varchar,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "daily_tasks" (
  "id" varchar PRIMARY KEY,
  "user_id" varchar NOT NULL,
  "date" date NOT NULL
);

CREATE TABLE "tasks" (
  "id" varchar PRIMARY KEY,
  "daily_task_id" varchar NOT NULL,
  "task_type" varchar,
  "value_text" text,
  "value_number" double precision,
  "completed" boolean DEFAULT false,
  "task_quality" varchar,
  "started_at" timestamp,
  "ended_at" timestamp,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "achievements" (
  "id" varchar PRIMARY KEY,
  "user_id" varchar NOT NULL,
  "type" varchar,
  "name" varchar,
  "description" text,
  "target" integer,
  "current" integer,
  "achieved" boolean DEFAULT false,
  "achieved_at" timestamp,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "user_preferences" (
  "id" varchar PRIMARY KEY,
  "user_id" varchar NOT NULL,
  "theme" theme DEFAULT 'system',
  "notifications_enabled" boolean DEFAULT true,
  "reminder_times" text,
  "created_at" timestamp DEFAULT (now()),
  "updated_at" timestamp DEFAULT (now())
);

CREATE TABLE "app_statistics" (
  "id" varchar PRIMARY KEY,
  "total_users" integer DEFAULT 0,
  "total_meals_logged" integer DEFAULT 0,
  "total_days_tracked" integer DEFAULT 0,
  "api_calls_this_month" integer DEFAULT 0,
  "last_updated" timestamp DEFAULT (now())
);

-- Create Indexes
CREATE UNIQUE INDEX ON "users" ("email");
CREATE UNIQUE INDEX ON "users" ("uid");
CREATE INDEX ON "user_goals" ("user_id");
CREATE UNIQUE INDEX ON "food_logs" ("user_id", "date");
CREATE INDEX ON "food_logs" ("date");
CREATE INDEX ON "meals" ("food_log_id");
CREATE INDEX ON "meals" ("user_id");
CREATE INDEX ON "meals" ("meal_type");
CREATE INDEX ON "meals" ("created_at");
CREATE UNIQUE INDEX ON "daily_tasks" ("user_id", "date");
CREATE INDEX ON "daily_tasks" ("user_id");
CREATE INDEX ON "daily_tasks" ("date");
CREATE INDEX ON "tasks" ("daily_task_id");
CREATE INDEX ON "tasks" ("task_type");
CREATE INDEX ON "achievements" ("user_id");
CREATE INDEX ON "achievements" ("type");
CREATE INDEX ON "achievements" ("achieved");
CREATE INDEX ON "meals" ("has_nutrition_data");
CREATE UNIQUE INDEX ON "user_preferences" ("user_id");

-- Add Foreign Keys
ALTER TABLE "user_goals" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("uid");
ALTER TABLE "food_logs" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("uid");
ALTER TABLE "meals" ADD FOREIGN KEY ("food_log_id") REFERENCES "food_logs" ("id");
ALTER TABLE "meals" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("uid");
ALTER TABLE "daily_tasks" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("uid");
ALTER TABLE "tasks" ADD FOREIGN KEY ("daily_task_id") REFERENCES "daily_tasks" ("id");
ALTER TABLE "achievements" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("uid");
ALTER TABLE "user_preferences" ADD FOREIGN KEY ("user_id") REFERENCES "users" ("uid");

-- Insert sample data
INSERT INTO "app_statistics" ("id", "total_users", "total_meals_logged", "total_days_tracked", "api_calls_this_month") 
VALUES ('1', 0, 0, 0, 0);
