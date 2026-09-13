import React from "react";
import { useBuilderStore } from "../lib/store";
import { WIDGET_DEFINITIONS } from "../lib/widgetDefs";
import type { WidgetProp, FlutterWidgetType } from "../lib/types";
import * as LucideIcons from "lucide-react";

export function PropertiesPanel() {
  const { project, selectedNodeId, updateWidgetProps } = useBuilderStore();

  const selectedNode = selectedNodeId ? findNode(project.widgetTree, selectedNodeId) : null;

  if (!selectedNode) {
    return (
      <div className="h-full flex flex-col bg-zinc-900 border-l border-zinc-800">
        <div className="p-3 border-b border-zinc-800">
          <h2 className="text-xs font-semibold text-zinc-400 uppercase tracking-wider">Properties</h2>
        </div>
        <div className="flex-1 flex items-center justify-center p-4">
          <div className="text-center text-zinc-500">
            <LucideIcons.MousePointerClick size={32} className="mx-auto mb-2 opacity-40" />
            <p className="text-xs">Select a widget to edit its properties</p>
          </div>
        </div>
      </div>
    );
  }

  const def = WIDGET_DEFINITIONS[selectedNode.type as FlutterWidgetType];
  const IconComp = (LucideIcons as any)[def.icon.charAt(0).toUpperCase() + def.icon.slice(1)] || LucideIcons.Square;

  return (
    <div className="h-full flex flex-col bg-zinc-900 border-l border-zinc-800">
      <div className="p-3 border-b border-zinc-800">
        <div className="flex items-center gap-2">
          <IconComp size={14} className="text-blue-400" />
          <h2 className="text-xs font-semibold text-zinc-200">{def.label}</h2>
        </div>
        <p className="text-[10px] text-zinc-500 mt-1">{def.description}</p>
      </div>
      <div className="flex-1 overflow-y-auto p-3 space-y-3">
        {def.props.map((prop: WidgetProp) => (
          <PropertyField
            key={prop.key}
            prop={prop}
            value={selectedNode.props[prop.key]}
            onChange={(value) => updateWidgetProps(selectedNode.id, { [prop.key]: value })}
          />
        ))}
      </div>
    </div>
  );
}

function findNode(node: any, id: string): any {
  if (node.id === id) return node;
  if (node.slots) {
    for (const slot of Object.values(node.slots)) {
      if (slot) {
        const found = findNode(slot, id);
        if (found) return found;
      }
    }
  }
  if (node.children) {
    for (const child of node.children) {
      const found = findNode(child, id);
      if (found) return found;
    }
  }
  return null;
}

function PropertyField({ prop, value, onChange }: { prop: WidgetProp; value: any; onChange: (value: any) => void }) {
  const label = (
    <label className="text-[11px] font-medium text-zinc-400 mb-1 block">{prop.label}</label>
  );

  switch (prop.type) {
    case "string":
      return (
        <div>
          {label}
          <input
            type="text"
            value={value || ""}
            onChange={(e) => onChange(e.target.value)}
            className="w-full bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            data-testid={`prop-${prop.key}`}
          />
        </div>
      );

    case "number":
      return (
        <div>
          {label}
          <input
            type="number"
            value={value ?? ""}
            onChange={(e) => onChange(e.target.value === "" ? null : parseFloat(e.target.value))}
            className="w-full bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            data-testid={`prop-${prop.key}`}
          />
        </div>
      );

    case "color":
      return (
        <div>
          {label}
          <div className="flex gap-2">
            <input
              type="color"
              value={value || "#000000"}
              onChange={(e) => onChange(e.target.value)}
              className="w-8 h-8 rounded-md border border-zinc-700 cursor-pointer bg-zinc-800"
              data-testid={`prop-${prop.key}`}
            />
            <input
              type="text"
              value={value || ""}
              onChange={(e) => onChange(e.target.value)}
              className="flex-1 bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500 font-mono"
            />
          </div>
        </div>
      );

    case "boolean":
      return (
        <div className="flex items-center justify-between">
          <label className="text-[11px] font-medium text-zinc-400">{prop.label}</label>
          <button
            onClick={() => onChange(!value)}
            className={`relative w-9 h-5 rounded-full transition-colors ${value ? "bg-purple-600" : "bg-zinc-700"}`}
            data-testid={`prop-${prop.key}`}
          >
            <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-transform ${value ? "translate-x-4" : ""}`} />
          </button>
        </div>
      );

    case "select":
      return (
        <div>
          {label}
          <select
            value={value || ""}
            onChange={(e) => onChange(e.target.value)}
            className="w-full bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            data-testid={`prop-${prop.key}`}
          >
            {prop.options?.map((opt) => (
              <option key={opt} value={opt}>{opt}</option>
            ))}
          </select>
        </div>
      );

    case "icon":
      return (
        <div>
          {label}
          <input
            type="text"
            value={value || ""}
            onChange={(e) => onChange(e.target.value)}
            placeholder="e.g. star, home, settings"
            className="w-full bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            data-testid={`prop-${prop.key}`}
          />
        </div>
      );

    case "padding":
    case "margin": {
      const v = value || { top: 0, right: 0, bottom: 0, left: 0 };
      return (
        <div>
          {label}
          <div className="grid grid-cols-4 gap-1">
            {(["top", "right", "bottom", "left"] as const).map((side) => (
              <div key={side}>
                <span className="text-[9px] text-zinc-500 block text-center">{side[0].toUpperCase()}</span>
                <input
                  type="number"
                  value={v[side] ?? 0}
                  onChange={(e) => onChange({ ...v, [side]: parseInt(e.target.value) || 0 })}
                  className="w-full bg-zinc-800 border border-zinc-700 rounded px-1 py-1 text-[11px] text-zinc-200 text-center focus:outline-none focus:border-purple-500"
                  data-testid={`prop-${prop.key}-${side}`}
                />
              </div>
            ))}
          </div>
        </div>
      );
    }

    case "alignment":
      return (
        <div>
          {label}
          <select
            value={value || "center"}
            onChange={(e) => onChange(e.target.value)}
            className="w-full bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            data-testid={`prop-${prop.key}`}
          >
            {["center", "centerLeft", "centerRight", "topCenter", "topLeft", "topRight", "bottomCenter", "bottomLeft", "bottomRight", "topStart", "topEnd", "centerStart", "centerEnd", "bottomStart", "bottomEnd"].map((opt) => (
              <option key={opt} value={opt}>{opt}</option>
            ))}
          </select>
        </div>
      );

    case "action":
      return (
        <div>
          {label}
          <select
            value={value || "none"}
            onChange={(e) => onChange(e.target.value)}
            className="w-full bg-zinc-800 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            data-testid={`prop-${prop.key}`}
          >
            <option value="none">None</option>
            <option value="navigate">Navigate to Page</option>
            <option value="showAlert">Show Alert</option>
            <option value="setVariable">Set Variable</option>
            <option value="apiCall">API Call</option>
            <option value="firebaseAuth">Firebase Auth</option>
            <option value="firestoreRead">Firestore Read</option>
            <option value="firestoreWrite">Firestore Write</option>
          </select>
        </div>
      );

    default:
      return null;
  }
}
