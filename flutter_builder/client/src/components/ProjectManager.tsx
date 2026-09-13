import React, { useState, useEffect } from "react";
import { useBuilderStore } from "../lib/store";
import { apiRequest } from "../lib/queryClient";
import type { Project } from "@shared/schema";
import * as LucideIcons from "lucide-react";

export function ProjectManager() {
  const { project, setProject, newProject, setProjectListOpen } = useBuilderStore();
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [newName, setNewName] = useState("");
  const [newPackage, setNewPackage] = useState("com.example.myapp");

  const loadProjects = async () => {
    try {
      const res = await apiRequest("GET", "/api/projects");
      const data = await res.json();
      setProjects(data);
    } catch (e) {
      // ignore
    }
    setLoading(false);
  };

  useEffect(() => {
    loadProjects();
  }, []);

  const handleCreate = async () => {
    if (!newName.trim()) return;
    const { widgetTree } = { widgetTree: JSON.stringify({ type: "Scaffold", props: {}, children: [], slots: {} }) };
    try {
      const res = await apiRequest("POST", "/api/projects", {
        name: newName,
        packageName: newPackage,
        description: "",
        widgetTreeJson: widgetTree,
        logicJson: "[]",
        modelsJson: "[]",
      });
      const created = await res.json();
      setProjects([...projects, created]);
      setShowCreate(false);
      setNewName("");
    } catch (e) {
      // ignore
    }
  };

  const handleOpen = async (p: Project) => {
    try {
      const tree = JSON.parse(p.widgetTreeJson || "{}");
      const logic = JSON.parse(p.logicJson || "[]");
      const models = JSON.parse(p.modelsJson || "[]");
      setProject({
        id: p.id,
        name: p.name,
        packageName: p.packageName,
        description: p.description || "",
        widgetTree: tree,
        logic,
        models,
      });
      setProjectListOpen(false);
    } catch (e) {
      // ignore
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await apiRequest("DELETE", `/api/projects/${id}`);
      setProjects(projects.filter(p => p.id !== id));
    } catch (e) {
      // ignore
    }
  };

  const handleDuplicate = async (id: number) => {
    try {
      const res = await apiRequest("POST", `/api/projects/${id}/duplicate`);
      const created = await res.json();
      setProjects([...projects, created]);
    } catch (e) {
      // ignore
    }
  };

  const handleSave = async () => {
    if (!project.id) {
      // Create new
      setShowCreate(true);
      setNewName(project.name);
      return;
    }
    try {
      await apiRequest("PATCH", `/api/projects/${project.id}`, {
        name: project.name,
        packageName: project.packageName,
        description: project.description,
        widgetTreeJson: JSON.stringify(project.widgetTree),
        logicJson: JSON.stringify(project.logic),
        modelsJson: JSON.stringify(project.models),
      });
    } catch (e) {
      // ignore
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4" onClick={() => setProjectListOpen(false)}>
      <div className="bg-zinc-900 border border-zinc-800 rounded-2xl w-full max-w-2xl max-h-[80vh] overflow-hidden flex flex-col" onClick={(e) => e.stopPropagation()}>
        <div className="p-4 border-b border-zinc-800 flex items-center justify-between">
          <h2 className="text-base font-semibold text-zinc-100">Projects</h2>
          <div className="flex items-center gap-2">
            <button
              onClick={() => { newProject(); setProjectListOpen(false); }}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-200 rounded-lg text-xs font-medium"
            >
              <LucideIcons.Plus size={14} />
              Blank Project
            </button>
            <button
              onClick={() => setShowCreate(!showCreate)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-medium"
            >
              <LucideIcons.Save size={14} />
              Save Current
            </button>
            <button onClick={() => setProjectListOpen(false)} className="text-zinc-500 hover:text-zinc-300">
              <LucideIcons.X size={18} />
            </button>
          </div>
        </div>

        {showCreate && (
          <div className="p-4 border-b border-zinc-800 bg-zinc-800/30">
            <div className="space-y-2">
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="Project name"
                className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-zinc-200 focus:outline-none focus:border-purple-500"
              />
              <input
                type="text"
                value={newPackage}
                onChange={(e) => setNewPackage(e.target.value)}
                placeholder="com.example.myapp"
                className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-sm text-zinc-200 focus:outline-none focus:border-purple-500"
              />
              <button
                onClick={async () => {
                  if (!newName.trim()) return;
                  try {
                    const res = await apiRequest("POST", "/api/projects", {
                      name: newName,
                      packageName: newPackage,
                      description: "",
                      widgetTreeJson: JSON.stringify(project.widgetTree),
                      logicJson: JSON.stringify(project.logic),
                      modelsJson: JSON.stringify(project.models),
                    });
                    const created = await res.json();
                    setProjects([...projects, created]);
                    setProject({ ...project, id: created.id, name: newName, packageName: newPackage });
                    setShowCreate(false);
                    setProjectListOpen(false);
                  } catch (e) {}
                }}
                className="w-full bg-purple-600 hover:bg-purple-500 text-white rounded-lg py-2 text-sm font-medium"
              >
                Save Project
              </button>
            </div>
          </div>
        )}

        <div className="flex-1 overflow-y-auto p-4">
          {loading ? (
            <div className="text-center text-zinc-500 py-8 text-sm">Loading...</div>
          ) : projects.length === 0 ? (
            <div className="text-center text-zinc-500 py-12">
              <LucideIcons.FolderOpen size={32} className="mx-auto mb-3 opacity-40" />
              <p className="text-sm">No saved projects yet</p>
              <p className="text-xs mt-1">Create a new project or save your current work</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {projects.map((p) => (
                <div key={p.id} className="bg-zinc-800/50 border border-zinc-800 rounded-xl p-4 hover:border-zinc-700 transition-colors group">
                  <div className="flex items-start justify-between mb-2">
                    <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center">
                      <LucideIcons.Smartphone size={18} className="text-white" />
                    </div>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      <button
                        onClick={() => handleDuplicate(p.id)}
                        className="p-1 text-zinc-500 hover:text-zinc-300"
                        title="Duplicate"
                      >
                        <LucideIcons.Copy size={14} />
                      </button>
                      <button
                        onClick={() => handleDelete(p.id)}
                        className="p-1 text-zinc-500 hover:text-red-400"
                        title="Delete"
                      >
                        <LucideIcons.Trash2 size={14} />
                      </button>
                    </div>
                  </div>
                  <h3 className="text-sm font-semibold text-zinc-200">{p.name}</h3>
                  <p className="text-[10px] text-zinc-500 font-mono mt-0.5">{p.packageName}</p>
                  {p.description && <p className="text-[11px] text-zinc-400 mt-1 line-clamp-2">{p.description}</p>}
                  <button
                    onClick={() => handleOpen(p)}
                    className="w-full mt-3 py-1.5 bg-zinc-700 hover:bg-zinc-600 text-zinc-200 rounded-lg text-xs font-medium"
                  >
                    Open
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
