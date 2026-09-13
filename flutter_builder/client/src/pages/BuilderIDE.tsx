import React, { useState, useEffect } from "react";
import { DndContext, DragOverlay, DragStartEvent, DragEndEvent, PointerSensor, useSensor, useSensors } from "@dnd-kit/core";
import { useBuilderStore } from "../lib/store";
import { WidgetLibrary } from "../components/WidgetLibrary";
import { WidgetTreePanel } from "../components/WidgetTreePanel";
import { PropertiesPanel } from "../components/PropertiesPanel";
import { CodePreviewPanel } from "../components/CodePreviewPanel";
import { PhonePreview } from "../components/PhonePreview";
import { LogicBuilder } from "../components/LogicBuilder";
import { AiGeneratorPanel } from "../components/AiGeneratorPanel";
import { CanvasWidgetRenderer } from "../components/CanvasWidgetRenderer";
import { ProjectManager } from "../components/ProjectManager";
import { generateProjectFiles } from "../lib/codeGenerator";
import { apiRequest } from "../lib/queryClient";
import { parseDropId, type DragPayload } from "../lib/types";
import { WIDGET_DEFINITIONS } from "../lib/widgetDefs";
import * as LucideIcons from "lucide-react";

export function BuilderIDE() {
  const {
    project,
    selectedNodeId,
    activeView,
    setActiveView,
    device,
    setDevice,
    selectWidget,
    isProjectListOpen,
    setProjectListOpen,
    isSaving,
    setSaving,
    lastSaved,
    setLastSaved,
    insertWidget,
    moveWidget,
  } = useBuilderStore();

  const [showCodePanel, setShowCodePanel] = useState(true);
  const [showAiPanel, setShowAiPanel] = useState(false);
  const [draggedPayload, setDraggedPayload] = useState<DragPayload | null>(null);

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 6 } })
  );

  const handleSave = async () => {
    setSaving(true);
    try {
      if (project.id) {
        await apiRequest("PATCH", `/api/projects/${project.id}`, {
          name: project.name,
          packageName: project.packageName,
          description: project.description,
          widgetTreeJson: JSON.stringify(project.widgetTree),
          logicJson: JSON.stringify(project.logic),
          modelsJson: JSON.stringify(project.models),
        });
      } else {
        const res = await apiRequest("POST", "/api/projects", {
          name: project.name,
          packageName: project.packageName,
          description: project.description,
          widgetTreeJson: JSON.stringify(project.widgetTree),
          logicJson: JSON.stringify(project.logic),
          modelsJson: JSON.stringify(project.models),
        });
        const created = await res.json();
        useBuilderStore.getState().setProject({ ...project, id: created.id });
      }
      setLastSaved(new Date().toLocaleTimeString());
    } catch (e) {
      console.error(e);
    }
    setSaving(false);
  };

  // Keyboard shortcuts
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "s") {
        e.preventDefault();
        handleSave();
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, []);

  // ===== DnD Handlers =====

  const handleDragStart = (event: DragStartEvent) => {
    const data = event.active.data.current as DragPayload;
    setDraggedPayload(data);
  };

  const handleDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setDraggedPayload(null);

    if (!over) return;

    const activeData = active.data.current as DragPayload;
    const overId = over.id.toString();
    const target = parseDropId(overId);
    if (!target || !activeData) return;

    if (activeData.kind === "palette-widget") {
      insertWidget(
        activeData.widgetType,
        target.parentId,
        target.mode === "slot" ? target.slotName : undefined,
        target.index
      );
    }

    if (activeData.kind === "canvas-widget") {
      moveWidget(
        activeData.nodeId,
        target.parentId,
        target.mode === "slot" ? target.slotName : undefined,
        target.index
      );
    }
  };

  const files = generateProjectFiles(project);

  // Drag overlay content
  const renderDragOverlay = () => {
    if (!draggedPayload) return null;
    const widgetType = draggedPayload.kind === "palette-widget"
      ? draggedPayload.widgetType
      : draggedPayload.widgetType;
    const def = WIDGET_DEFINITIONS[widgetType];
    const IconComp = (LucideIcons as any)[def.icon.charAt(0).toUpperCase() + def.icon.slice(1)] || LucideIcons.Square;

    return (
      <div className="flex items-center gap-2 px-3 py-2 bg-zinc-800 border border-purple-500 rounded-lg shadow-2xl opacity-90">
        <div className="w-7 h-7 rounded-md bg-purple-600 flex items-center justify-center">
          <IconComp size={14} className="text-white" />
        </div>
        <span className="text-xs font-medium text-zinc-200">{def.label}</span>
      </div>
    );
  };

  return (
    <DndContext
      sensors={sensors}
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragCancel={() => setDraggedPayload(null)}
    >
      <div className="h-screen flex flex-col bg-zinc-950 text-zinc-100 overflow-hidden">
        {/* Top Bar */}
        <header className="h-12 flex-shrink-0 bg-zinc-900 border-b border-zinc-800 flex items-center justify-between px-3">
          <div className="flex items-center gap-3">
            {/* Logo */}
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M5 3l14 9-14 9V3z" />
                </svg>
              </div>
              <span className="text-sm font-bold tracking-tight">FlutterBuilder</span>
            </div>

            <div className="h-6 w-px bg-zinc-800" />

            {/* Project name */}
            <input
              type="text"
              value={project.name}
              onChange={(e) => useBuilderStore.getState().setProjectName(e.target.value)}
              className="bg-transparent text-sm text-zinc-300 font-medium focus:outline-none focus:bg-zinc-800 rounded px-2 py-1 w-48"
              data-testid="input-project-name"
            />

            {/* Package name */}
            <input
              type="text"
              value={project.packageName}
              onChange={(e) => useBuilderStore.getState().setPackageName(e.target.value)}
              className="bg-transparent text-[11px] text-zinc-500 font-mono focus:outline-none focus:bg-zinc-800 rounded px-2 py-1 w-48"
              data-testid="input-package-name"
            />
          </div>

          <div className="flex items-center gap-1">
            {/* View tabs */}
            <div className="flex items-center bg-zinc-800 rounded-lg p-0.5">
              <ViewTab active={activeView === "design"} onClick={() => setActiveView("design")} icon="MousePointer2" label="Design" />
              <ViewTab active={activeView === "preview"} onClick={() => setActiveView("preview")} icon="Smartphone" label="Preview" />
              <ViewTab active={activeView === "code"} onClick={() => setActiveView("code")} icon="Code2" label="Code" />
              <ViewTab active={activeView === "logic"} onClick={() => setActiveView("logic")} icon="Workflow" label="Logic" />
            </div>

            <div className="h-6 w-px bg-zinc-800 mx-1" />

            {/* AI toggle */}
            <button
              onClick={() => setShowAiPanel(!showAiPanel)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                showAiPanel ? "bg-purple-600 text-white" : "bg-zinc-800 text-zinc-400 hover:text-zinc-200"
              }`}
              data-testid="button-toggle-ai"
            >
              <LucideIcons.Sparkles size={14} />
              AI
            </button>

            {/* Code panel toggle */}
            <button
              onClick={() => setShowCodePanel(!showCodePanel)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                showCodePanel ? "bg-zinc-800 text-zinc-200" : "bg-zinc-800/50 text-zinc-500 hover:text-zinc-200"
              }`}
            >
              <LucideIcons.Code2 size={14} />
              Code
            </button>

            <div className="h-6 w-px bg-zinc-800 mx-1" />

            {/* Save */}
            <button
              onClick={handleSave}
              disabled={isSaving}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-purple-600 hover:bg-purple-500 disabled:opacity-50 text-white rounded-lg text-xs font-medium"
              data-testid="button-save"
            >
              {isSaving ? <LucideIcons.Loader2 size={14} className="animate-spin" /> : <LucideIcons.Save size={14} />}
              {isSaving ? "Saving..." : "Save"}
            </button>
            {lastSaved && <span className="text-[10px] text-zinc-500 ml-1">Saved {lastSaved}</span>}

            {/* Projects */}
            <button
              onClick={() => setProjectListOpen(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 rounded-lg text-xs font-medium"
              data-testid="button-projects"
            >
              <LucideIcons.FolderOpen size={14} />
              Projects
            </button>
          </div>
        </header>

        {/* Main content */}
        <div className="flex-1 flex overflow-hidden">
          {/* Left sidebar - Widget Library + Tree */}
          <div className="w-56 flex-shrink-0 flex flex-col border-r border-zinc-800">
            <div className="flex-1 min-h-0">
              <WidgetLibrary />
            </div>
            <div className="h-64 flex-shrink-0 border-t border-zinc-800">
              <WidgetTreePanel />
            </div>
          </div>

          {/* AI panel (optional overlay on left) */}
          {showAiPanel && (
            <div className="w-64 flex-shrink-0 border-r border-zinc-800">
              <AiGeneratorPanel />
            </div>
          )}

          {/* Center area */}
          <div className="flex-1 flex flex-col min-w-0">
            {/* Canvas / Preview / Code / Logic */}
            <div className="flex-1 min-h-0 overflow-hidden">
              {activeView === "design" && (
                <div
                  className="h-full overflow-auto bg-zinc-100 dark:bg-zinc-950 p-8 flex items-start justify-center"
                  onClick={() => selectWidget(null)}
                >
                  <div
                    className="bg-white rounded-lg shadow-2xl"
                    style={{
                      width: "375px",
                      minHeight: "667px",
                      overflow: "hidden",
                    }}
                    onClick={(e) => e.stopPropagation()}
                  >
                    <CanvasWidgetRenderer
                      node={project.widgetTree}
                      onSelect={selectWidget}
                    />
                  </div>
                </div>
              )}

              {activeView === "preview" && <PhonePreview />}

              {activeView === "code" && (
                <div className="h-full">
                  <CodePreviewPanel />
                </div>
              )}

              {activeView === "logic" && <LogicBuilder />}
            </div>

            {/* Bottom code panel */}
            {showCodePanel && activeView !== "code" && activeView !== "logic" && (
              <div className="h-64 flex-shrink-0 border-t border-zinc-800">
                <CodePreviewPanel />
              </div>
            )}
          </div>

          {/* Right sidebar - Properties */}
          <div className="w-64 flex-shrink-0">
            <PropertiesPanel />
          </div>
        </div>

        {/* Project Manager Modal */}
        {isProjectListOpen && <ProjectManager />}
      </div>

      {/* Drag Overlay */}
      <DragOverlay>{renderDragOverlay()}</DragOverlay>
    </DndContext>
  );
}

function ViewTab({ active, onClick, icon, label }: { active: boolean; onClick: () => void; icon: string; label: string }) {
  const IconComp = (LucideIcons as any)[icon] || LucideIcons.Square;
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium transition-colors ${
        active ? "bg-zinc-700 text-white" : "text-zinc-500 hover:text-zinc-300"
      }`}
      data-testid={`tab-${label.toLowerCase()}`}
    >
      <IconComp size={13} />
      {label}
    </button>
  );
}
