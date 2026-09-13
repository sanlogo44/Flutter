import { create } from "zustand";
import type { WidgetNode, FlutterWidgetType, BuilderProject, LogicAction, DataModel, DropTarget } from "./types";
import { findNodeById, findParentById, deepClone, generateId, canAcceptChild, isDescendant } from "./types";
import { createWidgetNode, createDefaultProject, WIDGET_DEFINITIONS } from "./widgetDefs";

interface BuilderStore {
  // Project state
  project: BuilderProject;
  selectedNodeId: string | null;
  activeView: "design" | "code" | "preview" | "logic";
  device: "iphone" | "android";
  activeCodeFile: string;
  isSaving: boolean;
  lastSaved: string | null;
  isProjectListOpen: boolean;

  // Actions
  setProject: (project: BuilderProject) => void;
  newProject: () => void;
  selectWidget: (id: string | null) => void;
  addWidget: (type: FlutterWidgetType, parentId?: string | null, slotName?: string) => void;
  addWidgetToRoot: (type: FlutterWidgetType) => void;
  deleteWidget: (id: string) => void;
  duplicateWidget: (id: string) => void;
  updateWidgetProps: (id: string, props: Record<string, any>) => void;
  insertWidget: (type: FlutterWidgetType, targetParentId: string, slotName?: string, index?: number) => boolean;
  moveWidget: (id: string, targetParentId: string, targetSlot?: string, index?: number) => boolean;
  setActiveView: (view: "design" | "code" | "preview" | "logic") => void;
  setDevice: (device: "iphone" | "android") => void;
  setActiveCodeFile: (file: string) => void;
  setProjectName: (name: string) => void;
  setPackageName: (packageName: string) => void;
  setDescription: (description: string) => void;
  setSaving: (saving: boolean) => void;
  setLastSaved: (time: string) => void;
  setProjectListOpen: (open: boolean) => void;
  // Logic
  addLogicAction: (action: Omit<LogicAction, "id">) => void;
  updateLogicAction: (id: string, config: Record<string, any>) => void;
  deleteLogicAction: (id: string) => void;
  // Models
  addModel: (model: Omit<DataModel, "id">) => void;
  updateModel: (id: string, model: Partial<DataModel>) => void;
  deleteModel: (id: string) => void;
  // AI
  applyAIGeneratedTree: (tree: WidgetNode, models?: DataModel[], logic?: LogicAction[]) => void;
}

function regenerateIds(node: WidgetNode): WidgetNode {
  const newNode = { ...node, id: generateId() };
  if (node.children) {
    newNode.children = node.children.map(regenerateIds);
  }
  if (node.slots) {
    newNode.slots = {};
    for (const [key, value] of Object.entries(node.slots)) {
      newNode.slots[key] = value ? regenerateIds(value) : null;
    }
  }
  return newNode;
}

export const useBuilderStore = create<BuilderStore>((set, get) => ({
  project: {
    id: null,
    name: "My Flutter App",
    packageName: "com.example.myapp",
    description: "A new Flutter project",
    widgetTree: createDefaultProject().widgetTree,
    logic: [],
    models: [],
  },
  selectedNodeId: null,
  activeView: "design",
  device: "iphone",
  activeCodeFile: "lib/main.dart",
  isSaving: false,
  lastSaved: null,
  isProjectListOpen: false,

  setProject: (project) => set({ project, selectedNodeId: null }),

  newProject: () => {
    const { widgetTree } = createDefaultProject();
    set({
      project: {
        id: null,
        name: "New Flutter App",
        packageName: "com.example.myapp",
        description: "",
        widgetTree,
        logic: [],
        models: [],
      },
      selectedNodeId: null,
    });
  },

  selectWidget: (id) => set({ selectedNodeId: id }),

  addWidget: (type, parentId, slotName) => {
    const state = get();
    const newWidget = createWidgetNode(type);
    const tree = deepClone(state.project.widgetTree);

    if (!parentId) {
      // Add to root body slot if root is Scaffold
      if (tree.type === "Scaffold" && tree.slots?.body) {
        const body = tree.slots.body;
        if (body.children !== undefined) {
          body.children.push(newWidget);
        }
      } else if (tree.children !== undefined) {
        tree.children.push(newWidget);
      }
    } else {
      const parent = findNodeById(tree, parentId);
      if (!parent) return;

      if (slotName && parent.slots) {
        // Add to a named slot
        const def = WIDGET_DEFINITIONS[parent.type];
        if (def.slots?.includes(slotName)) {
          // If slot expects single child (like appBar), replace
          if (slotName === "actions" || slotName === "child") {
            // For list-type slots, we'd need to handle arrays - for now, set
            parent.slots[slotName] = newWidget;
          } else {
            parent.slots[slotName] = newWidget;
          }
        }
      } else {
        // Add to children array
        if (parent.children !== undefined) {
          parent.children.push(newWidget);
        }
      }
    }

    set({
      project: { ...state.project, widgetTree: tree },
      selectedNodeId: newWidget.id,
    });
  },

  addWidgetToRoot: (type) => {
    get().addWidget(type, null);
  },

  deleteWidget: (id) => {
    const state = get();
    const tree = deepClone(state.project.widgetTree);

    // Don't allow deleting the root
    if (tree.id === id) return;

    const parentInfo = findParentById(tree, id);
    if (!parentInfo) return;

    if (parentInfo.isSlot && parentInfo.slotName) {
      parentInfo.parent.slots![parentInfo.slotName] = null;
    } else {
      parentInfo.parent.children = parentInfo.parent.children.filter((c: WidgetNode) => c.id !== id);
    }

    set({
      project: { ...state.project, widgetTree: tree },
      selectedNodeId: null,
    });
  },

  duplicateWidget: (id) => {
    const state = get();
    const tree = deepClone(state.project.widgetTree);

    const node = findNodeById(tree, id);
    if (!node || tree.id === id) return;

    const parentInfo = findParentById(tree, id);
    if (!parentInfo) return;

    const clonedNode = regenerateIds(deepClone(node));

    if (parentInfo.isSlot && parentInfo.slotName) {
      // For single-child slots, we can't duplicate - add as sibling if possible
      // For now, add as child of the original node if it accepts children
      if (node.children !== undefined) {
        node.children.push(clonedNode);
      }
    } else {
      const idx = parentInfo.parent.children.findIndex((c: WidgetNode) => c.id === id);
      parentInfo.parent.children.splice(idx + 1, 0, clonedNode);
    }

    set({
      project: { ...state.project, widgetTree: tree },
      selectedNodeId: clonedNode.id,
    });
  },

  updateWidgetProps: (id, props) => {
    const state = get();
    const tree = deepClone(state.project.widgetTree);
    const node = findNodeById(tree, id);
    if (!node) return;
    node.props = { ...node.props, ...props };
    set({ project: { ...state.project, widgetTree: tree } });
  },

  moveWidget: (id, targetParentId, targetSlot, index) => {
    const state = get();
    const tree = deepClone(state.project.widgetTree);

    // Can't move root
    if (tree.id === id) return false;

    const node = findNodeById(tree, id);
    if (!node) return false;

    const newParent = findNodeById(tree, targetParentId);
    if (!newParent) return false;

    // Prevent moving into itself or a descendant
    if (isDescendant(node, id, targetParentId)) return false;

    // Validate: can the target parent accept this widget type in this slot?
    if (!canAcceptChild(newParent.type, node.type, targetSlot)) return false;

    // For single-child containers, check if already occupied
    const def = WIDGET_DEFINITIONS[newParent.type];
    if (!targetSlot && def.maxChildren === 1 && newParent.children.length > 0) return false;
    // For slots, check if already occupied
    if (targetSlot && newParent.slots && newParent.slots[targetSlot]) return false;

    // Remove from current parent
    const oldParentInfo = findParentById(tree, id);
    if (oldParentInfo) {
      if (oldParentInfo.isSlot && oldParentInfo.slotName) {
        oldParentInfo.parent.slots![oldParentInfo.slotName] = null;
      } else {
        oldParentInfo.parent.children = oldParentInfo.parent.children.filter((c: WidgetNode) => c.id !== id);
      }
    }

    // Re-find newParent (tree may have changed after removal)
    const newParentAfterRemoval = findNodeById(tree, targetParentId);
    if (!newParentAfterRemoval) return false;

    // Add to new parent
    if (targetSlot && newParentAfterRemoval.slots) {
      newParentAfterRemoval.slots[targetSlot] = node;
    } else if (newParentAfterRemoval.children !== undefined) {
      if (index !== undefined && index >= 0 && index <= newParentAfterRemoval.children.length) {
        newParentAfterRemoval.children.splice(index, 0, node);
      } else {
        newParentAfterRemoval.children.push(node);
      }
    }

    set({ project: { ...state.project, widgetTree: tree }, selectedNodeId: id });
    return true;
  },

  insertWidget: (type: FlutterWidgetType, targetParentId: string, slotName?: string, index?: number) => {
    const state = get();
    const newWidget = createWidgetNode(type);
    const tree = deepClone(state.project.widgetTree);

    const parent = findNodeById(tree, targetParentId);
    if (!parent) return false;

    // Validate: can the target parent accept this widget type in this slot?
    if (!canAcceptChild(parent.type, type, slotName)) return false;

    // For single-child containers, check if already occupied
    const def = WIDGET_DEFINITIONS[parent.type];
    if (!slotName && def.maxChildren === 1 && parent.children.length > 0) return false;
    // For slots, check if already occupied
    if (slotName && parent.slots && parent.slots[slotName]) return false;

    if (slotName && parent.slots) {
      parent.slots[slotName] = newWidget;
    } else if (parent.children !== undefined) {
      if (index !== undefined && index >= 0 && index <= parent.children.length) {
        parent.children.splice(index, 0, newWidget);
      } else {
        parent.children.push(newWidget);
      }
    }

    set({
      project: { ...state.project, widgetTree: tree },
      selectedNodeId: newWidget.id,
    });
    return true;
  },

  setActiveView: (view) => set({ activeView: view }),
  setDevice: (device) => set({ device }),
  setActiveCodeFile: (file) => set({ activeCodeFile: file }),
  setProjectName: (name) => set((state) => ({ project: { ...state.project, name } })),
  setPackageName: (packageName) => set((state) => ({ project: { ...state.project, packageName } })),
  setDescription: (description) => set((state) => ({ project: { ...state.project, description } })),
  setSaving: (isSaving) => set({ isSaving }),
  setLastSaved: (lastSaved) => set({ lastSaved }),
  setProjectListOpen: (isProjectListOpen) => set({ isProjectListOpen }),

  addLogicAction: (action) => set((state) => ({
    project: {
      ...state.project,
      logic: [...state.project.logic, { ...action, id: generateId() }],
    },
  })),

  updateLogicAction: (id, config) => set((state) => ({
    project: {
      ...state.project,
      logic: state.project.logic.map(l => l.id === id ? { ...l, config: { ...l.config, ...config } } : l),
    },
  })),

  deleteLogicAction: (id) => set((state) => ({
    project: {
      ...state.project,
      logic: state.project.logic.filter(l => l.id !== id),
    },
  })),

  addModel: (model) => set((state) => ({
    project: {
      ...state.project,
      models: [...state.project.models, { ...model, id: generateId() }],
    },
  })),

  updateModel: (id, model) => set((state) => ({
    project: {
      ...state.project,
      models: state.project.models.map(m => m.id === id ? { ...m, ...model } : m),
    },
  })),

  deleteModel: (id) => set((state) => ({
    project: {
      ...state.project,
      models: state.project.models.filter(m => m.id !== id),
    },
  })),

  applyAIGeneratedTree: (tree, models, logic) => set((state) => ({
    project: {
      ...state.project,
      widgetTree: tree,
      models: models || state.project.models,
      logic: logic || state.project.logic,
    },
    selectedNodeId: null,
  })),
}));
