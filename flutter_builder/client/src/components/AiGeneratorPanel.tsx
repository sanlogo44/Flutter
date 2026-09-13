import React, { useState } from "react";
import { useBuilderStore } from "../lib/store";
import { AI_TEMPLATES, generateFromPrompt } from "../lib/aiGenerator";
import * as LucideIcons from "lucide-react";

export function AiGeneratorPanel() {
  const { applyAIGeneratedTree, setActiveView } = useBuilderStore();
  const [prompt, setPrompt] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);

  const handleGenerate = () => {
    if (!prompt.trim()) return;
    setIsGenerating(true);
    setTimeout(() => {
      const result = generateFromPrompt(prompt);
      if (result) {
        applyAIGeneratedTree(result.tree, result.models, result.logic);
        setActiveView("design");
      }
      setIsGenerating(false);
    }, 800);
  };

  return (
    <div className="h-full flex flex-col bg-zinc-900">
      <div className="p-3 border-b border-zinc-800">
        <div className="flex items-center gap-2 mb-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-purple-500 to-blue-500 flex items-center justify-center">
            <LucideIcons.Sparkles size={16} className="text-white" />
          </div>
          <div>
            <h2 className="text-sm font-semibold text-zinc-100">AI App Generator</h2>
            <p className="text-[10px] text-zinc-500">Describe your app and let AI build it</p>
          </div>
        </div>
        <textarea
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder='e.g. "Erstelle eine Fitness-App mit Login, Dashboard und Trainingsplan"'
          rows={3}
          className="w-full bg-zinc-800 border border-zinc-700 rounded-lg px-3 py-2 text-xs text-zinc-200 focus:outline-none focus:border-purple-500 resize-none"
          data-testid="ai-prompt-input"
        />
        <button
          onClick={handleGenerate}
          disabled={!prompt.trim() || isGenerating}
          className="w-full mt-2 flex items-center justify-center gap-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 disabled:opacity-50 disabled:cursor-not-allowed text-white font-medium text-xs py-2 rounded-lg transition-all"
          data-testid="ai-generate-btn"
        >
          {isGenerating ? (
            <>
              <LucideIcons.Loader2 size={14} className="animate-spin" />
              Generating...
            </>
          ) : (
            <>
              <LucideIcons.Sparkles size={14} />
              Generate App
            </>
          )}
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-3">
        <h3 className="text-[10px] font-semibold text-zinc-500 uppercase tracking-wider mb-2">Quick Templates</h3>
        <div className="space-y-2">
          {AI_TEMPLATES.map((template) => (
            <button
              key={template.name}
              onClick={() => setPrompt(`Erstelle eine ${template.name}`)}
              className="w-full text-left p-2.5 rounded-lg bg-zinc-800/50 hover:bg-zinc-800 border border-zinc-800 transition-colors group"
            >
              <div className="flex items-center gap-2 mb-1">
                <LucideIcons.Zap size={12} className="text-purple-400" />
                <span className="text-xs font-medium text-zinc-200">{template.name}</span>
              </div>
              <p className="text-[10px] text-zinc-500">{template.description}</p>
              <div className="flex flex-wrap gap-1 mt-1.5">
                {template.keywords.slice(0, 3).map((kw) => (
                  <span key={kw} className="text-[9px] px-1.5 py-0.5 rounded bg-zinc-700 text-zinc-400">
                    {kw}
                  </span>
                ))}
              </div>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
