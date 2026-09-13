import React, { useState, useEffect, useRef } from "react";
import { useBuilderStore } from "../lib/store";
import { generateProjectFiles } from "../lib/codeGenerator";
import * as LucideIcons from "lucide-react";

export function CodePreviewPanel() {
  const { project } = useBuilderStore();
  const files = generateProjectFiles(project);
  const [activeFile, setActiveFile] = useState(files[0]?.path || "");
  const [copied, setCopied] = useState(false);
  const codeRef = useRef<HTMLPreElement>(null);

  const currentFile = files.find((f) => f.path === activeFile) || files[0];

  useEffect(() => {
    if (!files.find((f) => f.path === activeFile)) {
      setActiveFile(files[0]?.path || "");
    }
  }, [files, activeFile]);

  const handleCopy = () => {
    if (currentFile) {
      navigator.clipboard.writeText(currentFile.content);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const handleDownload = () => {
    if (currentFile) {
      const blob = new Blob([currentFile.content], { type: "text/plain" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = currentFile.path.split("/").pop() || "code.dart";
      a.click();
      URL.revokeObjectURL(url);
    }
  };

  return (
    <div className="h-full flex flex-col bg-zinc-950">
      <div className="flex items-center justify-between px-3 py-1.5 border-b border-zinc-800 bg-zinc-900">
        <div className="flex items-center gap-1 overflow-x-auto">
          {files.map((file) => (
            <button
              key={file.path}
              onClick={() => setActiveFile(file.path)}
              className={`px-3 py-1 rounded-md text-[11px] font-medium whitespace-nowrap transition-colors ${
                activeFile === file.path
                  ? "bg-zinc-800 text-purple-300"
                  : "text-zinc-500 hover:text-zinc-300 hover:bg-zinc-800/50"
              }`}
            >
              {file.path.split("/").pop()}
            </button>
          ))}
        </div>
        <div className="flex items-center gap-1">
          <button
            onClick={handleCopy}
            className="flex items-center gap-1 px-2 py-1 rounded text-[11px] text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800 transition-colors"
            title="Copy code"
            data-testid="button-copy-code"
          >
            {copied ? <LucideIcons.Check size={12} className="text-green-400" /> : <LucideIcons.Copy size={12} />}
            {copied ? "Copied!" : "Copy"}
          </button>
          <button
            onClick={handleDownload}
            className="flex items-center gap-1 px-2 py-1 rounded text-[11px] text-zinc-400 hover:text-zinc-200 hover:bg-zinc-800 transition-colors"
            title="Download file"
          >
            <LucideIcons.Download size={12} />
            Export
          </button>
        </div>
      </div>
      <div className="flex-1 overflow-auto">
        <div className="flex">
          {/* Line numbers */}
          <div className="flex-shrink-0 py-3 px-2 text-right text-[11px] text-zinc-600 font-mono select-none bg-zinc-950 border-r border-zinc-800">
            {currentFile?.content.split("\n").map((_, i) => (
              <div key={i} className="leading-5">{i + 1}</div>
            ))}
          </div>
          {/* Code */}
          <pre ref={codeRef} className="flex-1 py-3 px-3 text-[12px] leading-5 font-mono overflow-x-auto" data-testid="code-content">
            <code dangerouslySetInnerHTML={{ __html: highlightDart(currentFile?.content || "") }} />
          </pre>
        </div>
      </div>
      {/* File path */}
      <div className="px-3 py-1 border-t border-zinc-800 bg-zinc-900 text-[10px] text-zinc-500 font-mono">
        {currentFile?.path}
      </div>
    </div>
  );
}

// Simple Dart syntax highlighter
function highlightDart(code: string): string {
  let html = code
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");

  // Strings (single and double quotes)
  html = html.replace(/("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')/g, '<span style="color:#98c379">$1</span>');

  // Comments
  html = html.replace(/(\/\/.*$)/gm, '<span style="color:#7f848e">$1</span>');
  html = html.replace(/(\/\*[\s\S]*?\*\/)/g, '<span style="color:#7f848e">$1</span>');

  // Keywords
  const keywords = ["class", "extends", "implements", "with", "return", "if", "else", "for", "while", "do", "switch", "case", "break", "continue", "void", "var", "final", "const", "late", "static", "import", "export", "library", "part", "new", "this", "super", "true", "false", "null", "try", "catch", "finally", "throw", "rethrow", "in", "is", "as", "async", "await", "yield", "required", "factory", "operator", "get", "set", "enum", "typedef", "abstract", "interface", "mixin", "on", "when", "default"];
  for (const kw of keywords) {
    html = html.replace(new RegExp(`\\b${kw}\\b`, "g"), `<span style="color:#c678dd">${kw}</span>`);
  }

  // Types (Capitalized words)
  html = html.replace(/\b([A-Z][a-zA-Z0-9]*)\b/g, '<span style="color:#e5c07b">$1</span>');

  // Numbers
  html = html.replace(/\b(\d+\.?\d*)\b/g, '<span style="color:#d19a66">$1</span>');

  // Function calls
  html = html.replace(/\b([a-z][a-zA-Z0-9]*)\s*\(/g, '<span style="color:#61afef">$1</span>(');

  return html;
}
