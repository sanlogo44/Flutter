import React from "react";
import { useBuilderStore } from "../lib/store";
import type { WidgetNode, FlutterWidgetType } from "../lib/types";
import { WIDGET_DEFINITIONS } from "../lib/widgetDefs";
import * as LucideIcons from "lucide-react";

export function WidgetTreePanel() {
  const { project, selectedNodeId, selectWidget, deleteWidget } = useBuilderStore();

  const renderNode = (node: WidgetNode, depth: number, isSlot: boolean = false, slotName?: string) => {
    const def = WIDGET_DEFINITIONS[node.type];
    const isSelected = selectedNodeId === node.id;
    const IconComp = (LucideIcons as any)[def.icon.charAt(0).toUpperCase() + def.icon.slice(1)] || LucideIcons.Square;

    return (
      <div key={node.id}>
        <div
          onClick={() => selectWidget(node.id)}
          className={`flex items-center gap-1.5 py-1 pr-2 rounded cursor-pointer transition-colors text-xs ${
            isSelected ? "bg-purple-600/20 text-purple-300" : "hover:bg-zinc-800 text-zinc-300"
          }`}
          style={{ paddingLeft: `${depth * 12 + 8}px` }}
          data-testid={`tree-node-${node.id}`}
        >
          <IconComp size={12} className="flex-shrink-0" />
          <span className="font-medium truncate flex-1">
            {isSlot && slotName ? `${slotName}: ` : ""}{def.label}
          </span>
          {node.type === "Text" && node.props.text && (
            <span className="text-[10px] text-zinc-500 truncate max-w-[80px]">"{node.props.text}"</span>
          )}
          {node.type === "ElevatedButton" && node.props.label && (
            <span className="text-[10px] text-zinc-500 truncate max-w-[80px]">"{node.props.label}"</span>
          )}
          {project.widgetTree.id !== node.id && (
            <button
              onClick={(e) => { e.stopPropagation(); deleteWidget(node.id); }}
              className="opacity-0 hover:opacity-100 text-zinc-500 hover:text-red-400 transition-opacity"
              title="Delete"
            >
              <LucideIcons.X size={12} />
            </button>
          )}
        </div>

        {/* Render slots */}
        {node.slots && Object.entries(node.slots).map(([slotName, slotNode]) => {
          if (!slotNode) {
            return (
              <div
                key={slotName}
                className="flex items-center gap-1.5 py-1 pr-2 rounded text-xs text-zinc-600 italic"
                style={{ paddingLeft: `${(depth + 1) * 12 + 8}px` }}
              >
                <span className="text-zinc-700">─</span>
                <span>{slotName}: empty</span>
              </div>
            );
          }
          return renderNode(slotNode, depth + 1, true, slotName);
        })}

        {/* Render children */}
        {node.children.map((child) => renderNode(child, depth + 1))}
      </div>
    );
  };

  return (
    <div className="h-full flex flex-col bg-zinc-900 border-r border-zinc-800">
      <div className="p-3 border-b border-zinc-800">
        <h2 className="text-xs font-semibold text-zinc-400 uppercase tracking-wider">Widget Tree</h2>
      </div>
      <div className="flex-1 overflow-y-auto py-1">
        {renderNode(project.widgetTree, 0)}
      </div>
    </div>
  );
}
