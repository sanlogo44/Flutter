import type { Express } from "express";
import type { Server } from "node:http";
import { storage } from "./storage";
import { insertProjectSchema } from "@shared/schema";

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  // ---- Projects ----
  app.get("/api/projects", async (_req, res) => {
    const projects = await storage.getProjects();
    res.json(projects);
  });

  app.get("/api/projects/:id", async (req, res) => {
    const id = parseInt(req.params.id);
    const project = await storage.getProject(id);
    if (!project) return res.status(404).json({ error: "Project not found" });
    res.json(project);
  });

  app.post("/api/projects", async (req, res) => {
    const parsed = insertProjectSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: parsed.error.message });
    }
    const project = await storage.createProject(parsed.data);
    res.json(project);
  });

  app.patch("/api/projects/:id", async (req, res) => {
    const id = parseInt(req.params.id);
    const project = await storage.updateProject(id, req.body);
    if (!project) return res.status(404).json({ error: "Project not found" });
    res.json(project);
  });

  app.delete("/api/projects/:id", async (req, res) => {
    const id = parseInt(req.params.id);
    await storage.deleteProject(id);
    res.json({ success: true });
  });

  app.post("/api/projects/:id/duplicate", async (req, res) => {
    const id = parseInt(req.params.id);
    const project = await storage.duplicateProject(id);
    if (!project) return res.status(404).json({ error: "Project not found" });
    res.json(project);
  });

  // ---- Figma Import Proxy ----
  // Fetches a Figma file via the Figma REST API to avoid CORS issues
  app.post("/api/figma/import", async (req, res) => {
    try {
      const { fileUrl, apiToken, nodeId } = req.body as {
        fileUrl?: string;
        apiToken?: string;
        nodeId?: string;
      };

      if (!fileUrl || !apiToken) {
        return res.status(400).json({ error: "Missing fileUrl or apiToken" });
      }

      // Extract file key from URL
      // Supports: https://www.figma.com/file/XXXXX/Name, https://www.figma.com/design/XXXXX/Name
      let fileKey: string | null = null;
      const figmaUrlMatch = fileUrl.match(/figma\.com\/(?:file|design)\/([a-zA-Z0-9]+)/);
      if (figmaUrlMatch) {
        fileKey = figmaUrlMatch[1];
      } else if (/^[a-zA-Z0-9]+$/.test(fileUrl)) {
        // Raw file key
        fileKey = fileUrl;
      }

      if (!fileKey) {
        return res.status(400).json({ error: "Could not extract Figma file key from URL" });
      }

      // Fetch from Figma API
      const figmaApiUrl = nodeId
        ? `https://api.figma.com/v1/files/${fileKey}/nodes?ids=${nodeId}`
        : `https://api.figma.com/v1/files/${fileKey}`;

      const response = await fetch(figmaApiUrl, {
        headers: {
          "X-Figma-Token": apiToken,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        return res.status(response.status).json({
          error: `Figma API error: ${response.status} ${response.statusText}`,
          details: errorText.substring(0, 500),
        });
      }

      const data = await response.json();

      // Also fetch images for image-filled nodes
      const imageResponse = await fetch(
        `https://api.figma.com/v1/images/${fileKey}?format=png&scale=2`,
        { headers: { "X-Figma-Token": apiToken } }
      ).catch(() => null);

      let imageMap: Record<string, string> = {};
      if (imageResponse && imageResponse.ok) {
        const imageData = await imageResponse.json();
        imageMap = imageData.images || {};
      }

      res.json({ document: data, imageMap });
    } catch (err: any) {
      res.status(500).json({ error: err.message || "Failed to fetch Figma file" });
    }
  });

  return httpServer;
}
