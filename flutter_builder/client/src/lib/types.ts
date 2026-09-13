// ===== Flutter Widget AST Types =====

export type FlutterWidgetType =
  | "Scaffold"
  | "AppBar"
  | "Container"
  | "Column"
  | "Row"
  | "Stack"
  | "Text"
  | "Image"
  | "Icon"
  | "ElevatedButton"
  | "TextField"
  | "ListView"
  | "Card"
  | "GridView"
  | "Form"
  | "NavigationBar"
  | "Drawer";

export interface WidgetProp {
  key: string;
  label: string;
  type: "string" | "number" | "color" | "boolean" | "select" | "icon" | "padding" | "margin" | "alignment" | "action";
  defaultValue: any;
  options?: string[];
  description?: string;
}

export interface WidgetDefinition {
  type: FlutterWidgetType;
  label: string;
  icon: string;
  category: "layout" | "display" | "input" | "navigation";
  canHaveChildren: boolean;
  maxChildren?: number;
  slots?: string[]; // named slots like "appBar", "body", "drawer"
  defaultProps: Record<string, any>;
  props: WidgetProp[];
  description: string;
}

export interface WidgetNode {
  id: string;
  type: FlutterWidgetType;
  props: Record<string, any>;
  children: WidgetNode[];
  // For Scaffold: named slots
  slots?: Record<string, WidgetNode | null>;
}

export interface DataModel {
  id: string;
  name: string;
  fields: DataModelField[];
}

export interface DataModelField {
  name: string;
  type: "String" | "int" | "double" | "bool" | "List" | "DateTime";
}

export interface LogicAction {
  id: string;
  triggerWidgetId: string;
  triggerType: "onPressed" | "onChanged" | "onTap" | "onSubmit";
  actionType: "navigate" | "apiCall" | "setVariable" | "showAlert" | "firebaseAuth" | "firestoreRead" | "firestoreWrite";
  config: Record<string, any>;
}

export interface BuilderProject {
  id: number | null;
  name: string;
  packageName: string;
  description: string;
  widgetTree: WidgetNode;
  logic: LogicAction[];
  models: DataModel[];
}

export interface GeneratedFile {
  path: string;
  content: string;
  language: string;
}

// ===== Utility functions for widget tree =====

let nodeCounter = 0;
export function generateId(): string {
  nodeCounter++;
  return `node_${Date.now()}_${nodeCounter}_${Math.random().toString(36).slice(2, 8)}`;
}

export function findNodeById(node: WidgetNode, id: string): WidgetNode | null {
  if (node.id === id) return node;
  // Check slots
  if (node.slots) {
    for (const slotName of Object.keys(node.slots)) {
      const slot = node.slots[slotName];
      if (slot) {
        const found = findNodeById(slot, id);
        if (found) return found;
      }
    }
  }
  // Check children
  for (const child of node.children) {
    const found = findNodeById(child, id);
    if (found) return found;
  }
  return null;
}

export function findParentById(node: WidgetNode, id: string, parent: WidgetNode | null = null): { parent: WidgetNode; isSlot: boolean; slotName?: string } | null {
  // Check if any child matches
  for (const child of node.children) {
    if (child.id === id) return { parent: node, isSlot: false };
    const found = findParentById(child, id, node);
    if (found) return found;
  }
  // Check slots
  if (node.slots) {
    for (const slotName of Object.keys(node.slots)) {
      const slot = node.slots[slotName];
      if (slot && slot.id === id) return { parent: node, isSlot: true, slotName };
      if (slot) {
        const found = findParentById(slot, id, node);
        if (found) return found;
      }
    }
  }
  return null;
}

export function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}

export function countWidgets(node: WidgetNode): number {
  let count = 1;
  for (const child of node.children) count += countWidgets(child);
  if (node.slots) {
    for (const slot of Object.values(node.slots)) {
      if (slot) count += countWidgets(slot);
    }
  }
  return count;
}

// ===== Drag & Drop Helpers =====

export type DragPayload =
  | { kind: "palette-widget"; widgetType: FlutterWidgetType }
  | { kind: "canvas-widget"; nodeId: string; widgetType: FlutterWidgetType };

export interface DropTarget {
  mode: "children" | "slot";
  parentId: string;
  slotName?: string;
  index?: number;
}

/** Encode a drop target into a unique droppable ID */
export function encodeDropId(parentId: string, mode: "children" | "slot", slotOrIndex?: string | number): string {
  if (mode === "slot") return `drop:slot:${parentId}:${slotOrIndex}`;
  if (slotOrIndex !== undefined) return `drop:children:${parentId}:${slotOrIndex}`;
  return `drop:children:${parentId}`;
}

/** Parse a droppable ID back into a DropTarget */
export function parseDropId(id: string): DropTarget | null {
  const parts = id.split(":");
  if (parts[0] !== "drop") return null;
  const mode = parts[1] as "children" | "slot";
  const parentId = parts[2];
  if (mode === "slot") {
    return { mode, parentId, slotName: parts[3] };
  }
  // children mode — may have an index
  if (parts[3] !== undefined) {
    const index = parseInt(parts[3], 10);
    return { mode, parentId, index: isNaN(index) ? undefined : index };
  }
  return { mode, parentId };
}

/** Check if a node is a descendant of another node (or itself) */
export function isDescendant(root: WidgetNode, nodeId: string, possibleDescendantId: string): boolean {
  if (root.id === possibleDescendantId) return true;
  if (root.id === nodeId) return false; // can't be descendant of itself
  if (root.children) {
    for (const child of root.children) {
      if (isDescendant(child, nodeId, possibleDescendantId)) return true;
    }
  }
  if (root.slots) {
    for (const slot of Object.values(root.slots)) {
      if (slot && isDescendant(slot, nodeId, possibleDescendantId)) return true;
    }
  }
  return false;
}

/** Widgets that can only go into specific Scaffold slots */
const SLOTTED_WIDGETS: Record<string, string> = {
  AppBar: "appBar",
  Drawer: "drawer",
  NavigationBar: "bottomNavigationBar",
};

/** Check if a widget type is valid for a given parent type and slot */
export function canAcceptChild(
  parentType: FlutterWidgetType,
  childType: FlutterWidgetType,
  slotName?: string
): boolean {
  // Scaffold has specific slot rules
  if (parentType === "Scaffold") {
    if (slotName === "appBar") return childType === "AppBar";
    if (slotName === "drawer") return childType === "Drawer";
    if (slotName === "bottomNavigationBar") return childType === "NavigationBar";
    if (slotName === "body") {
 // Body can accept any content widget except AppBar, Drawer, NavigationBar
      return childType !== "AppBar" && childType !== "Drawer" && childType !== "NavigationBar" && childType !== "Scaffold";
    }
    return false;
  }

  // Slotted widgets that are restricted to Scaffold slots
  if (SLOTTED_WIDGETS[childType] && !slotName) {
    return false; // AppBar, Drawer, NavigationBar can't go into regular children
  }

  // AppBar slots
  if (parentType === "AppBar") {
    if (slotName === "title") return childType === "Text" || childType === "Container" || childType === "Row" || childType === "Column";
    if (slotName === "actions") return childType === "Icon" || childType === "ElevatedButton" || childType === "Text";
    return false;
  }

  // ElevatedButton has a child slot
  if (parentType === "ElevatedButton") {
    if (slotName === "child") return childType === "Text" || childType === "Icon" || childType === "Row" || childType === "Column";
    return false;
  }

  // Multi-child containers
  const multiChildContainers: FlutterWidgetType[] = ["Column", "Row", "Stack", "ListView", "GridView", "Form"];
  if (multiChildContainers.includes(parentType)) {
    return childType !== "Scaffold" && childType !== "AppBar" && childType !== "Drawer" && childType !== "NavigationBar";
  }

  // Single-child containers
  if (parentType === "Container" || parentType === "Card" || parentType === "Drawer") {
    return childType !== "Scaffold" && childType !== "AppBar" && childType !== "Drawer" && childType !== "NavigationBar";
  }

  return false;
}

/** Get valid drop slots for a widget type (for highlighting) */
export function getValidSlotsForWidget(widgetType: FlutterWidgetType): string[] {
  const slots: string[] = [];
  if (widgetType === "AppBar") slots.push("appBar");
  if (widgetType === "Drawer") slots.push("drawer");
  if (widgetType === "NavigationBar") slots.push("bottomNavigationBar");
  return slots;
}

/** Check if a parent already has content in a slot or is at max children */
export function isSlotOccupied(parent: WidgetNode, slotName: string): boolean {
  return !!(parent.slots && parent.slots[slotName]);
}

/** Check if a single-child container already has a child */
export function isSingleChildOccupied(parent: WidgetNode): boolean {
  return parent.children.length > 0;
}

/** Get the widget types that can be dropped on a given parent */
export function getAcceptableWidgetTypes(parentType: FlutterWidgetType, slotName?: string): FlutterWidgetType[] {
  const allTypes: FlutterWidgetType[] = [
    "Scaffold", "AppBar", "Container", "Column", "Row", "Stack",
    "Text", "Image", "Icon", "ElevatedButton", "TextField",
    "ListView", "Card", "GridView", "Form", "NavigationBar", "Drawer"
  ];
  return allTypes.filter(t => canAcceptChild(parentType, t, slotName));
}
