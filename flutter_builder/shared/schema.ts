import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";
import { createInsertSchema } from "drizzle-zod";
import type * as z from "zod/mini";

export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
});

export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
});

export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;

// ---- Flutter Builder Projects ----

export const projects = sqliteTable("projects", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  name: text("name").notNull(),
  packageName: text("package_name").notNull().default("com.example.myapp"),
  description: text("description"),
  widgetTreeJson: text("widget_tree_json").notNull().default("{}"),
  logicJson: text("logic_json").notNull().default("[]"),
  modelsJson: text("models_json").notNull().default("[]"),
  createdAt: text("created_at").notNull().default(new Date().toISOString()),
  updatedAt: text("updated_at").notNull().default(new Date().toISOString()),
});

export const insertProjectSchema = createInsertSchema(projects).pick({
  name: true,
  packageName: true,
  description: true,
  widgetTreeJson: true,
  logicJson: true,
  modelsJson: true,
});

export type InsertProject = z.infer<typeof insertProjectSchema>;
export type Project = typeof projects.$inferSelect;
