import React from "react";
import { useBuilderStore } from "../lib/store";
import { CanvasWidgetRenderer } from "./CanvasWidgetRenderer";

export function PhonePreview() {
  const { project, device, setDevice } = useBuilderStore();

  const isIphone = device === "iphone";

  return (
    <div className="h-full flex flex-col items-center justify-center bg-zinc-950 p-4 overflow-auto">
      <div className="flex items-center gap-2 mb-4">
        <button
          onClick={() => setDevice("iphone")}
          className={`px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${
            isIphone ? "bg-zinc-800 text-white" : "text-zinc-500 hover:text-zinc-300"
          }`}
        >
          iPhone
        </button>
        <button
          onClick={() => setDevice("android")}
          className={`px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${
            !isIphone ? "bg-zinc-800 text-white" : "text-zinc-500 hover:text-zinc-300"
          }`}
        >
          Android
        </button>
      </div>

      <div
        className={isIphone ? "iphone-frame" : "android-frame"}
        style={{
          width: isIphone ? "320px" : "340px",
          height: isIphone ? "640px" : "680px",
          borderRadius: isIphone ? "44px" : "24px",
          border: isIphone ? "12px solid #1a1a1a" : "8px solid #1a1a1a",
          backgroundColor: "#000",
          padding: isIphone ? "12px 0 0 0" : "0",
          position: "relative",
          boxShadow: "0 20px 60px rgba(0,0,0,0.5)",
          overflow: "hidden",
        }}
      >
        {/* Notch (iPhone) */}
        {isIphone && (
          <div
            style={{
              position: "absolute",
              top: "0",
              left: "50%",
              transform: "translateX(-50%)",
              width: "120px",
              height: "24px",
              backgroundColor: "#1a1a1a",
              borderRadius: "0 0 16px 16px",
              zIndex: 10,
            }}
          />
        )}

        {/* Status bar */}
        <div
          style={{
            height: isIphone ? "36px" : "28px",
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: isIphone ? "0 24px 0 24px" : "0 16px",
            fontSize: "11px",
            fontWeight: 600,
            color: "#fff",
            backgroundColor: "#000",
            flexShrink: 0,
            marginTop: isIphone ? "0" : "8px",
          }}
        >
          <span>9:41</span>
          <div style={{ display: "flex", gap: "4px", alignItems: "center" }}>
            <span style={{ fontSize: "10px" }}>▮▮▮▮</span>
            <span style={{ fontSize: "10px" }}>📶</span>
            <span style={{ fontSize: "10px" }}>🔋</span>
          </div>
        </div>

        {/* App content */}
        <div
          style={{
            flex: 1,
            overflow: "auto",
            backgroundColor: "#FFFFFF",
            position: "relative",
          }}
        >
          <CanvasWidgetRenderer
            node={project.widgetTree}
            onSelect={() => {}}
            isPreview
          />
        </div>

        {/* Home indicator (iPhone) */}
        {isIphone && (
          <div
            style={{
              height: "8px",
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              backgroundColor: "#000",
            }}
          >
            <div
              style={{
                width: "100px",
                height: "4px",
                backgroundColor: "#333",
                borderRadius: "2px",
              }}
            />
          </div>
        )}
      </div>
    </div>
  );
}
