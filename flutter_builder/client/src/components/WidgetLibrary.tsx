import React from "react";
import { useDraggable } from "@dnd-kit/core";
import { useBuilderStore } from "../lib/store";
import { WIDGET_CATEGORIES, WIDGET_DEFINITIONS } from "../lib/widgetDefs";
import * as LucideIcons from "lucide-react";
import type { FlutterWidgetType, DragPayload } from "../lib/types";

export function WidgetLibrary() {
  const { addWidgetToRoot, selectedNodeId, addWidget } = useBuilderStore();

  const handleAdd = (type: FlutterWidgetType) => {
    if (selectedNodeId) {
      addWidget(type, selectedNodeId);
    } else {
      addWidgetToRoot(type);
    }
  };

  return (
    <div className="h-full flex flex-col bg-zinc-900 border-r border-zinc-800">
      <div className="p-3 border-b border-zinc-800">
        <h2 className="text-xs font-semibold text-zinc-400 uppercase tracking-wider">Widget Library</h2>
        <p className="text-[10px] text-zinc-600 mt-0.5">Drag to canvas or click to add</p>
      </div>
      <div className="flex-1 overflow-y-auto p-2">
        {WIDGET_CATEGORIES.map((cat) => {
          const catIcon = (LucideIcons as any)[cat.icon === "layout" ? "LayoutGrid" : cat.icon === "eye" ? "Eye" : cat.icon === "input" ? "Input" : "Navigation"];
          return (
            <div key={cat.name} className="mb-4">
              <div className="flex items-center gap-1.5 px-2 mb-1.5">
                {catIcon && React.createElement(catIcon, { size: 12, className: "text-zinc-500" })}
                <span className="text-[10px] font-semibold text-zinc-500 uppercase tracking-wider">{cat.name}</span>
              </div>
              <div className="space-y-0.5">
                {cat.widgets.map((type) => (
                  <DraggableWidgetItem
                    key={type}
                    type={type}
                    onClick={() => handleAdd(type)}
                  />
                ))}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function DraggableWidgetItem({ type, onClick }: { type: FlutterWidgetType; onClick: () => void }) {
  const def = WIDGET_DEFINITIONS[type];
  const IconComp = (LucideIcons as any)[def.icon.charAt(0).toUpperCase() + def.icon.slice(1)] || LucideIcons.Square;

  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `palette-${type}`,
    data: { kind: "palette-widget", widgetType: type } as DragPayload,
  });

  return (
    <div
      ref={setNodeRef}
      {...attributes}
      {...listeners}
      onClick={onClick}
      className={`w-full flex items-center gap-2 px-2 py-1.5 rounded-md cursor-grab active:cursor-grabbing text-left transition-colors group ${
        isDragging ? "opacity-40" : "hover:bg-zinc-800"
      }`}
      title={def.description}
      data-testid={`widget-add-${type}`}
    >
      <div className="w-7 h-7 rounded-md bg-zinc-800 group-hover:bg-zinc-700 flex items-center justify-center transition-colors">
        <IconComp size={14} className="text-blue-400" />
      </div>
      <div className="flex-1 min-w-0">
        <div className="text-xs font-medium text-zinc-200 truncate">{def.label}</div>
        <div className="text-[10px] text-zinc-500 truncate">{def.description}</div>
      </div>
    </div>
  );
}
