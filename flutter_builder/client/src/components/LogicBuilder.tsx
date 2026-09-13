import React, { useState } from "react";
import { useBuilderStore } from "../lib/store";
import type { DataModel, DataModelField } from "../lib/types";
import * as LucideIcons from "lucide-react";

export function LogicBuilder() {
  const { project, addLogicAction, deleteLogicAction, addModel, deleteModel } = useBuilderStore();
  const [newModelName, setNewModelName] = useState("");
  const [newFieldName, setNewFieldName] = useState("");
  const [newFieldType, setNewFieldType] = useState<DataModelField["type"]>("String");

  return (
    <div className="h-full flex bg-zinc-950">
      {/* Left: Actions */}
      <div className="w-1/2 border-r border-zinc-800 flex flex-col">
        <div className="p-3 border-b border-zinc-800">
          <h3 className="text-xs font-semibold text-zinc-300 flex items-center gap-2">
            <LucideIcons.Zap size={14} className="text-purple-400" />
            Button Actions
          </h3>
        </div>
        <div className="flex-1 overflow-y-auto p-3 space-y-2">
          {project.logic.length === 0 && (
            <div className="text-center text-zinc-500 py-8">
              <LucideIcons.MousePointerClick size={24} className="mx-auto mb-2 opacity-40" />
              <p className="text-xs">No actions defined yet</p>
              <p className="text-[10px] mt-1">Select a button widget and assign an action in Properties</p>
            </div>
          )}
          {project.logic.map((action) => (
            <div key={action.id} className="bg-zinc-900 border border-zinc-800 rounded-lg p-3">
              <div className="flex items-center justify-between mb-2">
                <span className="text-[10px] px-2 py-0.5 rounded bg-purple-600/20 text-purple-300 font-medium">
                  {action.actionType}
                </span>
                <button
                  onClick={() => deleteLogicAction(action.id)}
                  className="text-zinc-500 hover:text-red-400"
                >
                  <LucideIcons.X size={14} />
                </button>
              </div>
              <div className="space-y-1">
                {Object.entries(action.config).map(([k, v]) => (
                  <div key={k} className="flex justify-between text-[11px]">
                    <span className="text-zinc-500">{k}:</span>
                    <span className="text-zinc-300 font-mono">{String(v).slice(0, 40)}</span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Right: Data Models */}
      <div className="w-1/2 flex flex-col">
        <div className="p-3 border-b border-zinc-800">
          <h3 className="text-xs font-semibold text-zinc-300 flex items-center gap-2">
            <LucideIcons.Database size={14} className="text-blue-400" />
            Data Models
          </h3>
        </div>
        <div className="p-3 border-b border-zinc-800">
          <div className="flex gap-2">
            <input
              type="text"
              value={newModelName}
              onChange={(e) => setNewModelName(e.target.value)}
              placeholder="Model name (e.g. User)"
              className="flex-1 bg-zinc-900 border border-zinc-700 rounded-md px-2 py-1.5 text-xs text-zinc-200 focus:outline-none focus:border-purple-500"
            />
            <button
              onClick={() => {
                if (newModelName.trim()) {
                  addModel({ name: newModelName, fields: [] });
                  setNewModelName("");
                }
              }}
              className="px-3 py-1.5 bg-purple-600 hover:bg-purple-500 text-white rounded-md text-xs font-medium"
            >
              Add
            </button>
          </div>
        </div>
        <div className="flex-1 overflow-y-auto p-3 space-y-3">
          {project.models.length === 0 && (
            <div className="text-center text-zinc-500 py-8">
              <LucideIcons.Database size={24} className="mx-auto mb-2 opacity-40" />
              <p className="text-xs">No models defined yet</p>
            </div>
          )}
          {project.models.map((model) => (
            <ModelEditor key={model.id} model={model} onDelete={() => deleteModel(model.id)} />
          ))}
        </div>
      </div>
    </div>
  );
}

function ModelEditor({ model, onDelete }: { model: DataModel; onDelete: () => void }) {
  const { updateModel } = useBuilderStore();
  const [newFieldName, setNewFieldName] = useState("");
  const [newFieldType, setNewFieldType] = useState<DataModelField["type"]>("String");

  return (
    <div className="bg-zinc-900 border border-zinc-800 rounded-lg p-3">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs font-semibold text-zinc-200 font-mono">{model.name}</span>
        <button onClick={onDelete} className="text-zinc-500 hover:text-red-400">
          <LucideIcons.Trash2 size={12} />
        </button>
      </div>
      <div className="space-y-1 mb-2">
        {model.fields.map((field, i) => (
          <div key={i} className="flex items-center gap-2 text-[11px]">
            <span className="text-zinc-400 font-mono flex-1">{field.name}</span>
            <span className="text-purple-400 font-mono">{field.type}</span>
            <button
              onClick={() => updateModel(model.id, { fields: model.fields.filter((_, idx) => idx !== i) })}
              className="text-zinc-600 hover:text-red-400"
            >
              <LucideIcons.X size={10} />
            </button>
          </div>
        ))}
        {model.fields.length === 0 && (
          <p className="text-[10px] text-zinc-600 italic">No fields</p>
        )}
      </div>
      <div className="flex gap-1">
        <input
          type="text"
          value={newFieldName}
          onChange={(e) => setNewFieldName(e.target.value)}
          placeholder="field name"
          className="flex-1 bg-zinc-800 border border-zinc-700 rounded px-2 py-1 text-[11px] text-zinc-200 focus:outline-none focus:border-purple-500"
        />
        <select
          value={newFieldType}
          onChange={(e) => setNewFieldType(e.target.value as DataModelField["type"])}
          className="bg-zinc-800 border border-zinc-700 rounded px-1 py-1 text-[11px] text-zinc-200"
        >
          {["String", "int", "double", "bool", "List", "DateTime"].map((t) => (
            <option key={t} value={t}>{t}</option>
          ))}
        </select>
        <button
          onClick={() => {
            if (newFieldName.trim()) {
              updateModel(model.id, { fields: [...model.fields, { name: newFieldName, type: newFieldType }] });
              setNewFieldName("");
            }
          }}
          className="px-2 py-1 bg-zinc-700 hover:bg-zinc-600 text-zinc-200 rounded text-[11px]"
        >
          +
        </button>
      </div>
    </div>
  );
}
