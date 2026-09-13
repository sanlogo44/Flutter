import { users, projects } from '@shared/schema';
import type { User, InsertUser, Project, InsertProject } from '@shared/schema';
import { drizzle } from "drizzle-orm/better-sqlite3";
import Database from "better-sqlite3";
import { eq } from "drizzle-orm";

const sqlite = new Database("data.db");
sqlite.pragma("journal_mode = WAL");

export const db = drizzle(sqlite);

export interface IStorage {
  getUser(id: number): Promise<User | undefined>;
  getUserByUsername(username: string): Promise<User | undefined>;
  createUser(user: InsertUser): Promise<User>;
  // Projects
  getProjects(): Promise<Project[]>;
  getProject(id: number): Promise<Project | undefined>;
  createProject(project: InsertProject): Promise<Project>;
  updateProject(id: number, project: Partial<InsertProject>): Promise<Project | undefined>;
  deleteProject(id: number): Promise<void>;
  duplicateProject(id: number): Promise<Project | undefined>;
}

export class DatabaseStorage implements IStorage {
  async getUser(id: number): Promise<User | undefined> {
    return db.select().from(users).where(eq(users.id, id)).get();
  }

  async getUserByUsername(username: string): Promise<User | undefined> {
    return db.select().from(users).where(eq(users.username, username)).get();
  }

  async createUser(insertUser: InsertUser): Promise<User> {
    return db.insert(users).values(insertUser).returning().get();
  }

  async getProjects(): Promise<Project[]> {
    return db.select().from(projects).all();
  }

  async getProject(id: number): Promise<Project | undefined> {
    return db.select().from(projects).where(eq(projects.id, id)).get();
  }

  async createProject(project: InsertProject): Promise<Project> {
    return db.insert(projects).values(project).returning().get();
  }

  async updateProject(id: number, project: Partial<InsertProject>): Promise<Project | undefined> {
    db.update(projects).set({ ...project, updatedAt: new Date().toISOString() }).where(eq(projects.id, id)).run();
    return db.select().from(projects).where(eq(projects.id, id)).get();
  }

  async deleteProject(id: number): Promise<void> {
    db.delete(projects).where(eq(projects.id, id)).run();
  }

  async duplicateProject(id: number): Promise<Project | undefined> {
    const original = await this.getProject(id);
    if (!original) return undefined;
    const copy: InsertProject = {
      name: `${original.name} (Copy)`,
      packageName: original.packageName,
      description: original.description,
      widgetTreeJson: original.widgetTreeJson,
      logicJson: original.logicJson,
      modelsJson: original.modelsJson,
    };
    return this.createProject(copy);
  }
}

export const storage = new DatabaseStorage();
