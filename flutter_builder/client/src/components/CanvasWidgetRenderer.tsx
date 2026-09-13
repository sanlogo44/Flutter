import React from "react";
import { useDraggable, useDroppable } from "@dnd-kit/core";
import type { WidgetNode, FlutterWidgetType, DragPayload } from "../lib/types";
import { useBuilderStore } from "../lib/store";
import { WIDGET_DEFINITIONS } from "../lib/widgetDefs";
import { encodeDropId, canAcceptChild, isDescendant, isSlotOccupied } from "../lib/types";

interface RenderProps {
  node: WidgetNode;
  onSelect: (id: string) => void;
  isPreview?: boolean;
}

function colorToCss(hex: string): string {
  return hex || "transparent";
}

function paddingToCss(padding: any): React.CSSProperties {
  if (!padding) return {};
  return {
    paddingTop: padding.top || 0,
    paddingRight: padding.right || 0,
    paddingBottom: padding.bottom || 0,
    paddingLeft: padding.left || 0,
  };
}

function marginToCss(margin: any): React.CSSProperties {
  if (!margin) return {};
  return {
    marginTop: margin.top || 0,
    marginRight: margin.right || 0,
    marginBottom: margin.bottom || 0,
    marginLeft: margin.left || 0,
  };
}

function alignmentToCss(align: string): React.CSSProperties {
  const map: Record<string, React.CSSProperties> = {
    center: { display: "flex", justifyContent: "center", alignItems: "center" },
    centerLeft: { display: "flex", justifyContent: "flex-start", alignItems: "center" },
    centerRight: { display: "flex", justifyContent: "flex-end", alignItems: "center" },
    topCenter: { display: "flex", justifyContent: "center", alignItems: "flex-start" },
    topLeft: { display: "flex", justifyContent: "flex-start", alignItems: "flex-start" },
    topRight: { display: "flex", justifyContent: "flex-end", alignItems: "flex-start" },
    bottomCenter: { display: "flex", justifyContent: "center", alignItems: "flex-end" },
    bottomLeft: { display: "flex", justifyContent: "flex-start", alignItems: "flex-end" },
    bottomRight: { display: "flex", justifyContent: "flex-end", alignItems: "flex-end" },
    topStart: { display: "flex", justifyContent: "flex-start", alignItems: "flex-start" },
    topEnd: { display: "flex", justifyContent: "flex-end", alignItems: "flex-start" },
    centerStart: { display: "flex", justifyContent: "flex-start", alignItems: "center" },
    centerEnd: { display: "flex", justifyContent: "flex-end", alignItems: "center" },
    bottomStart: { display: "flex", justifyContent: "flex-start", alignItems: "flex-end" },
    bottomEnd: { display: "flex", justifyContent: "flex-end", alignItems: "flex-end" },
  };
  return map[align] || map.center;
}

// ===== Drop Zone Component =====

function DropZone({ parentId, slotName, label, minHeight = "32px" }: { parentId: string; slotName?: string; label?: string; minHeight?: string }) {
  const dropId = encodeDropId(parentId, slotName ? "slot" : "children", slotName);
  const { isOver, setNodeRef } = useDroppable({ id: dropId });
  const { selectedNodeId } = useBuilderStore();

  return (
    <div
      ref={setNodeRef}
      style={{
        minHeight,
        minWidth: "100%",
        border: isOver
          ? "2px solid #6750A4"
          : "2px dashed rgba(103, 80, 164, 0.2)",
        borderRadius: "4px",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color: isOver ? "#6750A4" : "rgba(103, 80, 164, 0.4)",
        fontSize: "11px",
        padding: "4px 8px",
        transition: "all 0.15s",
        backgroundColor: isOver ? "rgba(103, 80, 164, 0.08)" : "transparent",
      }}
    >
      {isOver ? `Drop here → ${label || "children"}` : `+ ${label || "drop"}`}
    </div>
  );
}

// ===== Draggable wrapper for canvas widgets =====

function DraggableWrapper({ node, children, isPreview }: { node: WidgetNode; children: React.ReactNode; isPreview?: boolean }) {
  const { selectedNodeId, selectWidget, deleteWidget, duplicateWidget } = useBuilderStore();
  const selected = !isPreview && selectedNodeId === node.id;

  const { attributes, listeners, setNodeRef, isDragging } = useDraggable({
    id: `canvas-${node.id}`,
    data: { kind: "canvas-widget", nodeId: node.id, widgetType: node.type } as DragPayload,
    disabled: isPreview,
  });

  const handleClick = (e: React.MouseEvent) => {
    if (!isPreview) {
      e.stopPropagation();
      selectWidget(node.id);
    }
  };

  return (
    <div
      ref={setNodeRef}
      {...attributes}
      {...listeners}
      onClick={handleClick}
      style={{
        position: "relative",
        cursor: isPreview ? "default" : "grab",
        outline: selected ? "2px solid #6750A4" : "1px dashed transparent",
        outlineOffset: "2px",
        transition: "outline-color 0.15s, opacity 0.15s",
        borderRadius: "4px",
        opacity: isDragging ? 0.4 : 1,
      }}
      data-widget-type={node.type}
      data-widget-id={node.id}
    >
      {children}
      {selected && !isPreview && <WidgetToolbar nodeId={node.id} onDelete={deleteWidget} onDuplicate={duplicateWidget} />}
    </div>
  );
}

function WidgetToolbar({ nodeId, onDelete, onDuplicate }: { nodeId: string; onDelete: (id: string) => void; onDuplicate: (id: string) => void }) {
  return (
    <div style={{
      position: "absolute",
      top: "-28px",
      left: "0",
      display: "flex",
      gap: "2px",
      backgroundColor: "#6750A4",
      borderRadius: "4px",
      padding: "2px",
      zIndex: 100,
    }}>
      <button
        onClick={(e) => { e.stopPropagation(); onDuplicate(nodeId); }}
        style={{ background: "none", border: "none", color: "white", cursor: "pointer", padding: "2px 6px", fontSize: "11px", borderRadius: "2px" }}
        title="Duplicate"
      >⧉</button>
      <button
        onClick={(e) => { e.stopPropagation(); onDelete(nodeId); }}
        style={{ background: "none", border: "none", color: "white", cursor: "pointer", padding: "2px 6px", fontSize: "11px", borderRadius: "2px" }}
        title="Delete"
      >🗑</button>
    </div>
  );
}

// ===== Main Canvas Widget Renderer =====

export function CanvasWidgetRenderer({ node, onSelect, isPreview }: RenderProps) {
  const props = node.props;

  const renderChildrenWithDropZone = (containerType: string) => {
    const def = WIDGET_DEFINITIONS[containerType as FlutterWidgetType];
    const isMultiChild = def && def.canHaveChildren && (!def.maxChildren || def.maxChildren > 1);
    return (
      <>
        {node.children.map((child) => (
          <CanvasWidgetRenderer key={child.id} node={child} onSelect={onSelect} isPreview={isPreview} />
        ))}
        {isMultiChild && !isPreview && (
          <DropZone parentId={node.id} label={`${containerType}`} minHeight="24px" />
        )}
      </>
    );
  };

  const renderChildren = () => {
    return node.children.map((child) => (
      <CanvasWidgetRenderer key={child.id} node={child} onSelect={onSelect} isPreview={isPreview} />
    ));
  };

  const renderSlot = (slotName: string) => {
    const slot = node.slots?.[slotName];
    if (!slot) {
      if (isPreview) return null;
      return <DropZone parentId={node.id} slotName={slotName} label={slotName} />;
    }
    return <CanvasWidgetRenderer node={slot} onSelect={onSelect} isPreview={isPreview} />;
  };

  switch (node.type) {
    case "Scaffold": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{ display: "flex", flexDirection: "column", minHeight: "100%", backgroundColor: colorToCss(props.backgroundColor) }}>
            {node.slots?.appBar ? (
              <div style={{ flexShrink: 0 }}>{renderSlot("appBar")}</div>
            ) : !isPreview && (
              <div style={{ flexShrink: 0, padding: "4px" }}><DropZone parentId={node.id} slotName="appBar" label="appBar slot" minHeight="24px" /></div>
            )}
            <div style={{ flex: 1, overflow: "auto" }}>
              {renderSlot("body")}
            </div>
            {node.slots?.drawer ? renderSlot("drawer") : !isPreview && (
              <DropZone parentId={node.id} slotName="drawer" label="drawer slot" minHeight="24px" />
            )}
            {node.slots?.bottomNavigationBar ? (
              <div style={{ flexShrink: 0 }}>{renderSlot("bottomNavigationBar")}</div>
            ) : !isPreview && (
              <div style={{ flexShrink: 0, padding: "4px" }}><DropZone parentId={node.id} slotName="bottomNavigationBar" label="navBar slot" minHeight="24px" /></div>
            )}
          </div>
        </DraggableWrapper>
      );
    }

    case "AppBar": {
      const bg = colorToCss(props.backgroundColor);
      const fg = colorToCss(props.foregroundColor);
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            backgroundColor: bg,
            color: fg,
            padding: "12px 16px",
            display: "flex",
            alignItems: "center",
            justifyContent: props.centerTitle ? "center" : "flex-start",
            boxShadow: `0px ${props.elevation || 0}px ${((props.elevation || 0) * 2)}px rgba(0,0,0,0.15)`,
            position: "relative",
            minHeight: "56px",
          }}>
            {node.slots?.title ? (
              <div>{renderSlot("title")}</div>
            ) : !isPreview ? (
              <DropZone parentId={node.id} slotName="title" label="title" minHeight="20px" />
            ) : (
              <span style={{ fontSize: "18px", fontWeight: props.centerTitle ? 600 : 500 }}>{props.title}</span>
            )}
            {node.slots?.actions ? (
              <div style={{ position: "absolute", right: "8px", display: "flex", gap: "4px" }}>
                {renderSlot("actions")}
              </div>
            ) : !isPreview && (
              <div style={{ position: "absolute", right: "8px", display: "flex", gap: "4px" }}>
                <DropZone parentId={node.id} slotName="actions" label="actions" minHeight="20px" />
              </div>
            )}
          </div>
        </DraggableWrapper>
      );
    }

    case "Container": {
      const def = WIDGET_DEFINITIONS["Container"];
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            ...paddingToCss(props.padding),
            ...marginToCss(props.margin),
            ...alignmentToCss(props.alignment || "center"),
            backgroundColor: props.color ? colorToCss(props.color) : undefined,
            width: props.width ? `${props.width}px` : undefined,
            height: props.height ? `${props.height}px` : undefined,
            borderRadius: `${props.borderRadius || 0}px`,
            minHeight: props.height ? undefined : "32px",
            minWidth: props.width ? undefined : "100%",
            boxSizing: "border-box",
          }}>
            {node.children.length > 0 ? renderChildren() : (!isPreview && <DropZone parentId={node.id} label="Container child" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "Column": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "flex",
            flexDirection: "column",
            justifyContent: mapMainAxis(props.mainAxisAlignment),
            alignItems: mapCrossAxis(props.crossAxisAlignment),
            gap: "8px",
            minHeight: "32px",
            minWidth: "100%",
            padding: "8px",
          }}>
            {node.children.length > 0 ? renderChildrenWithDropZone("Column") : (!isPreview && <DropZone parentId={node.id} label="Column" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "Row": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "flex",
            flexDirection: "row",
            justifyContent: mapMainAxis(props.mainAxisAlignment),
            alignItems: mapCrossAxis(props.crossAxisAlignment),
            gap: "8px",
            minHeight: "32px",
            minWidth: "100%",
            padding: "8px",
          }}>
            {node.children.length > 0 ? renderChildrenWithDropZone("Row") : (!isPreview && <DropZone parentId={node.id} label="Row" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "Stack": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{ position: "relative", minHeight: "64px", minWidth: "100%" }}>
            {node.children.map((child, i) => (
              <div key={child.id} style={{ position: i === 0 ? "relative" : "absolute", top: 0, left: 0, right: 0 }}>
                <CanvasWidgetRenderer node={child} onSelect={onSelect} isPreview={isPreview} />
              </div>
            ))}
            {node.children.length === 0 && !isPreview && <DropZone parentId={node.id} label="Stack" minHeight="64px" />}
            {node.children.length > 0 && !isPreview && <DropZone parentId={node.id} label="Stack" minHeight="24px" />}
          </div>
        </DraggableWrapper>
      );
    }

    case "Text": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            fontSize: `${props.fontSize || 16}px`,
            fontWeight: props.fontWeight === "bold" ? "bold" : props.fontWeight?.startsWith("w") ? parseInt(props.fontWeight.slice(1)) : "normal",
            color: colorToCss(props.color || "#000000"),
            textAlign: props.textAlign || "left",
            padding: "4px 8px",
            display: "inline-block",
          }}>
            {props.text || "Text"}
          </div>
        </DraggableWrapper>
      );
    }

    case "Image": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{ display: "inline-block", borderRadius: `${props.borderRadius || 0}px`, overflow: "hidden" }}>
            <img
              src={props.src}
              alt=""
              style={{
                width: props.width ? `${props.width}px` : "100%",
                height: props.height ? `${props.height}px` : "auto",
                objectFit: mapFit(props.fit),
                display: "block",
                borderRadius: `${props.borderRadius || 0}px`,
              }}
              onError={(e) => { (e.target as HTMLImageElement).style.display = "none"; }}
            />
          </div>
        </DraggableWrapper>
      );
    }

    case "Icon": {
      const iconMap: Record<string, string> = {
        star: "★", home: "🏠", search: "🔍", person: "👤", settings: "⚙", email: "✉", lock: "🔒", cloud: "☁", heart: "♥", favorite: "♥",
        add: "+", remove: "−", delete: "🗑", edit: "✎", save: "💾", close: "✕", menu: "☰", arrow_back: "←", arrow_forward: "→",
        check: "✓", refresh: "↻", shopping_cart: "🛒", notifications: "🔔", calendar: "📅", phone: "📞", location: "📍",
      };
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "inline-flex",
            alignItems: "center",
            justifyContent: "center",
            fontSize: `${props.size || 24}px`,
            color: colorToCss(props.color || "#000000"),
            padding: "4px",
          }}>
            {iconMap[props.iconName] || "★"}
          </div>
        </DraggableWrapper>
      );
    }

    case "ElevatedButton": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{ display: "inline-block" }}>
            {node.slots?.child ? (
              <button
                style={{
                  backgroundColor: colorToCss(props.backgroundColor || "#6750A4"),
                  color: colorToCss(props.foregroundColor || "#FFFFFF"),
                  border: "none",
                  borderRadius: `${props.borderRadius || 8}px`,
                  padding: "10px 24px",
                  fontSize: "14px",
                  fontWeight: 500,
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(0,0,0,0.2)",
                }}
                type="button"
              >
                {renderSlot("child")}
              </button>
            ) : (
              <button
                style={{
                  backgroundColor: colorToCss(props.backgroundColor || "#6750A4"),
                  color: colorToCss(props.foregroundColor || "#FFFFFF"),
                  border: "none",
                  borderRadius: `${props.borderRadius || 8}px`,
                  padding: "10px 24px",
                  fontSize: "14px",
                  fontWeight: 500,
                  cursor: "pointer",
                  boxShadow: "0 2px 4px rgba(0,0,0,0.2)",
                }}
                type="button"
              >
                {props.label || "Button"}
              </button>
            )}
          </div>
        </DraggableWrapper>
      );
    }

    case "TextField": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{ display: "block" }}>
            <div style={{ marginBottom: "4px", fontSize: "12px", color: "#666" }}>{props.label}</div>
            <input
              type={props.obscureText ? "password" : "text"}
              placeholder={props.hintText}
              style={{
                width: "100%",
                padding: "10px 12px",
                border: "1px solid #ccc",
                borderRadius: `${props.borderRadius || 8}px`,
                fontSize: "14px",
                outline: "none",
              }}
              readOnly
            />
          </div>
        </DraggableWrapper>
      );
    }

    case "ListView": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "flex",
            flexDirection: "column",
            gap: "8px",
            ...paddingToCss(props.padding),
            minHeight: "64px",
            minWidth: "100%",
          }}>
            {node.children.length > 0 ? renderChildrenWithDropZone("ListView") : (!isPreview && <DropZone parentId={node.id} label="ListView" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "Card": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            backgroundColor: colorToCss(props.color || "#FFFFFF"),
            borderRadius: `${props.borderRadius || 12}px`,
            boxShadow: `0 ${props.elevation || 2}px ${(props.elevation || 2) * 3}px rgba(0,0,0,0.12)`,
            ...marginToCss(props.margin),
            overflow: "hidden",
            minHeight: "32px",
          }}>
            {node.children.length > 0 ? renderChildren() : (!isPreview && <DropZone parentId={node.id} label="Card child" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "GridView": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "grid",
            gridTemplateColumns: `repeat(${props.crossAxisCount || 2}, 1fr)`,
            gap: `${props.crossAxisSpacing || 8}px ${props.mainAxisSpacing || 8}px`,
            padding: "8px",
            minHeight: "64px",
            minWidth: "100%",
          }}>
            {node.children.length > 0 ? renderChildrenWithDropZone("GridView") : (!isPreview && <DropZone parentId={node.id} label="GridView" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "Form": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "flex",
            flexDirection: "column",
            gap: "12px",
            padding: "16px",
            minHeight: "64px",
            minWidth: "100%",
          }}>
            {node.children.length > 0 ? renderChildrenWithDropZone("Form") : (!isPreview && <DropZone parentId={node.id} label="Form" />)}
          </div>
        </DraggableWrapper>
      );
    }

    case "NavigationBar": {
      const destinations = (props.destinations || "").split(",").map((d: string) => d.trim()).filter(Boolean);
      const icons = ["🏠", "🔍", "❤", "👤", "⚙", "📅"];
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            display: "flex",
            justifyContent: "space-around",
            backgroundColor: colorToCss(props.backgroundColor || "#F3EDF7"),
            padding: "8px 0",
            borderTop: "1px solid rgba(0,0,0,0.1)",
          }}>
            {destinations.map((d: string, i: number) => (
              <div key={i} style={{
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: "2px",
                opacity: i === (props.selectedIndex || 0) ? 1 : 0.5,
              }}>
                <span style={{ fontSize: "20px" }}>{icons[i] || "●"}</span>
                <span style={{ fontSize: "10px" }}>{d}</span>
              </div>
            ))}
          </div>
        </DraggableWrapper>
      );
    }

    case "Drawer": {
      return (
        <DraggableWrapper node={node} isPreview={isPreview}>
          <div style={{
            backgroundColor: colorToCss(props.backgroundColor || "#FFFFFF"),
            width: "280px",
            minHeight: "100%",
            padding: "16px",
          }}>
            {node.children.length > 0 ? renderChildren() : (!isPreview && <DropZone parentId={node.id} label="Drawer child" />)}
          </div>
        </DraggableWrapper>
      );
    }

    default:
      return <div>Unknown: {node.type}</div>;
  }
}

function mapMainAxis(align: string): React.CSSProperties["justifyContent"] {
  const map: Record<string, React.CSSProperties["justifyContent"]> = {
    start: "flex-start",
    center: "center",
    end: "flex-end",
    spaceBetween: "space-between",
    spaceAround: "space-around",
    spaceEvenly: "space-evenly",
  };
  return map[align] || "flex-start";
}

function mapCrossAxis(align: string): React.CSSProperties["alignItems"] {
  const map: Record<string, React.CSSProperties["alignItems"]> = {
    start: "flex-start",
    center: "center",
    end: "flex-end",
    stretch: "stretch",
  };
  return map[align] || "center";
}

function mapFit(fit: string): React.CSSProperties["objectFit"] {
  const map: Record<string, React.CSSProperties["objectFit"]> = {
    cover: "cover",
    contain: "contain",
    fill: "fill",
    fitWidth: "cover",
    fitHeight: "cover",
    none: "none",
  };
  return map[fit] || "cover";
}
