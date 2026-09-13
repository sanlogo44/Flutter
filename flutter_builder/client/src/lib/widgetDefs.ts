import type { WidgetDefinition, FlutterWidgetType, WidgetNode } from "./types";
import { generateId } from "./types";

export const WIDGET_DEFINITIONS: Record<FlutterWidgetType, WidgetDefinition> = {
  Scaffold: {
    type: "Scaffold",
    label: "Scaffold",
    icon: "smartphone",
    category: "layout",
    canHaveChildren: false,
    slots: ["appBar", "body", "drawer", "bottomNavigationBar"],
    defaultProps: {
      backgroundColor: "#FFFFFF",
    },
    props: [
      { key: "backgroundColor", label: "Background Color", type: "color", defaultValue: "#FFFFFF" },
    ],
    description: "Basic page structure with AppBar, body, drawer, and bottom nav",
  },
  AppBar: {
    type: "AppBar",
    label: "AppBar",
    icon: "minus",
    category: "navigation",
    canHaveChildren: false,
    slots: ["title", "actions"],
    defaultProps: {
      title: "My App",
      backgroundColor: "#6750A4",
      foregroundColor: "#FFFFFF",
      elevation: 4,
      centerTitle: true,
    },
    props: [
      { key: "title", label: "Title", type: "string", defaultValue: "My App" },
      { key: "backgroundColor", label: "Background Color", type: "color", defaultValue: "#6750A4" },
      { key: "foregroundColor", label: "Text Color", type: "color", defaultValue: "#FFFFFF" },
      { key: "elevation", label: "Elevation", type: "number", defaultValue: 4 },
      { key: "centerTitle", label: "Center Title", type: "boolean", defaultValue: true },
    ],
    description: "Top navigation bar with title and actions",
  },
  Container: {
    type: "Container",
    label: "Container",
    icon: "square",
    category: "layout",
    canHaveChildren: true,
    maxChildren: 1,
    defaultProps: {
      width: null,
      height: null,
      color: "#E0E0E0",
      padding: { top: 16, right: 16, bottom: 16, left: 16 },
      margin: { top: 0, right: 0, bottom: 0, left: 0 },
      alignment: "center",
      borderRadius: 8,
    },
    props: [
      { key: "width", label: "Width", type: "number", defaultValue: null },
      { key: "height", label: "Height", type: "number", defaultValue: null },
      { key: "color", label: "Color", type: "color", defaultValue: "#E0E0E0" },
      { key: "padding", label: "Padding", type: "padding", defaultValue: { top: 16, right: 16, bottom: 16, left: 16 } },
      { key: "margin", label: "Margin", type: "margin", defaultValue: { top: 0, right: 0, bottom: 0, left: 0 } },
      { key: "alignment", label: "Alignment", type: "alignment", defaultValue: "center" },
      { key: "borderRadius", label: "Border Radius", type: "number", defaultValue: 8 },
    ],
    description: "Box container with padding, margin, color, and alignment",
  },
  Column: {
    type: "Column",
    label: "Column",
    icon: "columns-3",
    category: "layout",
    canHaveChildren: true,
    defaultProps: {
      mainAxisAlignment: "start",
      crossAxisAlignment: "center",
      mainAxisSize: "max",
    },
    props: [
      { key: "mainAxisAlignment", label: "Main Axis Alignment", type: "select", defaultValue: "start", options: ["start", "center", "end", "spaceBetween", "spaceAround", "spaceEvenly"] },
      { key: "crossAxisAlignment", label: "Cross Axis Alignment", type: "select", defaultValue: "center", options: ["start", "center", "end", "stretch"] },
      { key: "mainAxisSize", label: "Main Axis Size", type: "select", defaultValue: "max", options: ["max", "min"] },
    ],
    description: "Vertical layout for stacking children",
  },
  Row: {
    type: "Row",
    label: "Row",
    icon: "rows-3",
    category: "layout",
    canHaveChildren: true,
    defaultProps: {
      mainAxisAlignment: "start",
      crossAxisAlignment: "center",
      mainAxisSize: "max",
    },
    props: [
      { key: "mainAxisAlignment", label: "Main Axis Alignment", type: "select", defaultValue: "start", options: ["start", "center", "end", "spaceBetween", "spaceAround", "spaceEvenly"] },
      { key: "crossAxisAlignment", label: "Cross Axis Alignment", type: "select", defaultValue: "center", options: ["start", "center", "end", "stretch"] },
      { key: "mainAxisSize", label: "Main Axis Size", type: "select", defaultValue: "max", options: ["max", "min"] },
    ],
    description: "Horizontal layout for arranging children",
  },
  Stack: {
    type: "Stack",
    label: "Stack",
    icon: "layers",
    category: "layout",
    canHaveChildren: true,
    defaultProps: {
      alignment: "topStart",
    },
    props: [
      { key: "alignment", label: "Alignment", type: "alignment", defaultValue: "topStart" },
    ],
    description: "Overlapping widgets layer",
  },
  Text: {
    type: "Text",
    label: "Text",
    icon: "type",
    category: "display",
    canHaveChildren: false,
    defaultProps: {
      text: "Text",
      fontSize: 16,
      fontWeight: "normal",
      color: "#000000",
      textAlign: "left",
      maxLines: null,
    },
    props: [
      { key: "text", label: "Text", type: "string", defaultValue: "Text" },
      { key: "fontSize", label: "Font Size", type: "number", defaultValue: 16 },
      { key: "fontWeight", label: "Font Weight", type: "select", defaultValue: "normal", options: ["normal", "bold", "w100", "w200", "w300", "w400", "w500", "w600", "w700", "w800", "w900"] },
      { key: "color", label: "Color", type: "color", defaultValue: "#000000" },
      { key: "textAlign", label: "Text Align", type: "select", defaultValue: "left", options: ["left", "center", "right", "justify"] },
      { key: "maxLines", label: "Max Lines", type: "number", defaultValue: null },
    ],
    description: "Display text with style options",
  },
  Image: {
    type: "Image",
    label: "Image",
    icon: "image",
    category: "display",
    canHaveChildren: false,
    defaultProps: {
      src: "https://picsum.photos/300/200",
      width: 200,
      height: 200,
      fit: "cover",
      borderRadius: 0,
    },
    props: [
      { key: "src", label: "Image URL", type: "string", defaultValue: "https://picsum.photos/300/200" },
      { key: "width", label: "Width", type: "number", defaultValue: 200 },
      { key: "height", label: "Height", type: "number", defaultValue: 200 },
      { key: "fit", label: "Fit", type: "select", defaultValue: "cover", options: ["cover", "contain", "fill", "fitWidth", "fitHeight", "none"] },
      { key: "borderRadius", label: "Border Radius", type: "number", defaultValue: 0 },
    ],
    description: "Network or asset image widget",
  },
  Icon: {
    type: "Icon",
    label: "Icon",
    icon: "star",
    category: "display",
    canHaveChildren: false,
    defaultProps: {
      iconName: "star",
      size: 24,
      color: "#000000",
    },
    props: [
      { key: "iconName", label: "Icon Name", type: "icon", defaultValue: "star" },
      { key: "size", label: "Size", type: "number", defaultValue: 24 },
      { key: "color", label: "Color", type: "color", defaultValue: "#000000" },
    ],
    description: "Material design icon",
  },
  ElevatedButton: {
    type: "ElevatedButton",
    label: "Button",
    icon: "hand",
    category: "input",
    canHaveChildren: false,
    slots: ["child"],
    defaultProps: {
      label: "Button",
      backgroundColor: "#6750A4",
      foregroundColor: "#FFFFFF",
      borderRadius: 8,
      onPressedAction: "none",
    },
    props: [
      { key: "label", label: "Label", type: "string", defaultValue: "Button" },
      { key: "backgroundColor", label: "Background Color", type: "color", defaultValue: "#6750A4" },
      { key: "foregroundColor", label: "Text Color", type: "color", defaultValue: "#FFFFFF" },
      { key: "borderRadius", label: "Border Radius", type: "number", defaultValue: 8 },
      { key: "onPressedAction", label: "On Pressed Action", type: "action", defaultValue: "none" },
    ],
    description: "Material elevated button with action",
  },
  TextField: {
    type: "TextField",
    label: "TextField",
    icon: "text-cursor",
    category: "input",
    canHaveChildren: false,
    defaultProps: {
      label: "Enter text",
      hintText: "Type here...",
      prefixIcon: "",
      obscureText: false,
      maxLines: 1,
      borderRadius: 8,
    },
    props: [
      { key: "label", label: "Label", type: "string", defaultValue: "Enter text" },
      { key: "hintText", label: "Hint Text", type: "string", defaultValue: "Type here..." },
      { key: "prefixIcon", label: "Prefix Icon", type: "icon", defaultValue: "" },
      { key: "obscureText", label: "Obscure Text", type: "boolean", defaultValue: false },
      { key: "maxLines", label: "Max Lines", type: "number", defaultValue: 1 },
      { key: "borderRadius", label: "Border Radius", type: "number", defaultValue: 8 },
    ],
    description: "Text input field with label and hint",
  },
  ListView: {
    type: "ListView",
    label: "ListView",
    icon: "list",
    category: "layout",
    canHaveChildren: true,
    defaultProps: {
      padding: { top: 8, right: 8, bottom: 8, left: 8 },
      scrollDirection: "vertical",
    },
    props: [
      { key: "padding", label: "Padding", type: "padding", defaultValue: { top: 8, right: 8, bottom: 8, left: 8 } },
      { key: "scrollDirection", label: "Scroll Direction", type: "select", defaultValue: "vertical", options: ["vertical", "horizontal"] },
    ],
    description: "Scrollable list of children",
  },
  Card: {
    type: "Card",
    label: "Card",
    icon: "credit-card",
    category: "layout",
    canHaveChildren: true,
    maxChildren: 1,
    defaultProps: {
      color: "#FFFFFF",
      elevation: 2,
      borderRadius: 12,
      margin: { top: 8, right: 8, bottom: 8, left: 8 },
    },
    props: [
      { key: "color", label: "Color", type: "color", defaultValue: "#FFFFFF" },
      { key: "elevation", label: "Elevation", type: "number", defaultValue: 2 },
      { key: "borderRadius", label: "Border Radius", type: "number", defaultValue: 12 },
      { key: "margin", label: "Margin", type: "margin", defaultValue: { top: 8, right: 8, bottom: 8, left: 8 } },
    ],
    description: "Material card container with elevation",
  },
  GridView: {
    type: "GridView",
    label: "GridView",
    icon: "grid-3x3",
    category: "layout",
    canHaveChildren: true,
    defaultProps: {
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.0,
    },
    props: [
      { key: "crossAxisCount", label: "Cross Axis Count", type: "number", defaultValue: 2 },
      { key: "crossAxisSpacing", label: "Cross Axis Spacing", type: "number", defaultValue: 8 },
      { key: "mainAxisSpacing", label: "Main Axis Spacing", type: "number", defaultValue: 8 },
      { key: "childAspectRatio", label: "Child Aspect Ratio", type: "number", defaultValue: 1.0 },
    ],
    description: "Scrollable grid layout",
  },
  Form: {
    type: "Form",
    label: "Form",
    icon: "clipboard-list",
    category: "input",
    canHaveChildren: true,
    defaultProps: {
      autovalidateMode: "disabled",
    },
    props: [
      { key: "autovalidateMode", label: "Auto Validate", type: "select", defaultValue: "disabled", options: ["disabled", "always", "onUserInteraction"] },
    ],
    description: "Form container for input validation",
  },
  NavigationBar: {
    type: "NavigationBar",
    label: "NavigationBar",
    icon: "navigation",
    category: "navigation",
    canHaveChildren: false,
    defaultProps: {
      destinations: "Home,Search,Profile",
      selectedIndex: 0,
      backgroundColor: "#F3EDF7",
    },
    props: [
      { key: "destinations", label: "Destinations (comma-separated)", type: "string", defaultValue: "Home,Search,Profile" },
      { key: "selectedIndex", label: "Selected Index", type: "number", defaultValue: 0 },
      { key: "backgroundColor", label: "Background Color", type: "color", defaultValue: "#F3EDF7" },
    ],
    description: "Bottom navigation bar with destinations",
  },
  Drawer: {
    type: "Drawer",
    label: "Drawer",
    icon: "panel-left",
    category: "navigation",
    canHaveChildren: true,
    maxChildren: 1,
    defaultProps: {
      backgroundColor: "#FFFFFF",
    },
    props: [
      { key: "backgroundColor", label: "Background Color", type: "color", defaultValue: "#FFFFFF" },
    ],
    description: "Side navigation drawer",
  },
};

export const WIDGET_CATEGORIES = [
  { name: "Layout", icon: "layout", widgets: ["Scaffold", "Container", "Column", "Row", "Stack", "ListView", "GridView", "Card", "Form", "Drawer"] as FlutterWidgetType[] },
  { name: "Display", icon: "eye", widgets: ["Text", "Image", "Icon"] as FlutterWidgetType[] },
  { name: "Input", icon: "input", widgets: ["ElevatedButton", "TextField"] as FlutterWidgetType[] },
  { name: "Navigation", icon: "navigation", widgets: ["AppBar", "NavigationBar"] as FlutterWidgetType[] },
];

export function createWidgetNode(type: FlutterWidgetType): WidgetNode {
  const def = WIDGET_DEFINITIONS[type];
  const node: WidgetNode = {
    id: generateId(),
    type,
    props: { ...def.defaultProps },
    children: [],
  };
  if (def.slots) {
    node.slots = {};
    for (const slot of def.slots) {
      node.slots[slot] = null;
    }
  }
  return node;
}

export function createDefaultProject(): { widgetTree: WidgetNode } {
  const scaffold = createWidgetNode("Scaffold");
  const appBar = createWidgetNode("AppBar");
  appBar.props.title = "My Flutter App";
  const body = createWidgetNode("Column");
  const text1 = createWidgetNode("Text");
  text1.props.text = "Welcome to My App";
  text1.props.fontSize = 24;
  text1.props.fontWeight = "bold";
  const button1 = createWidgetNode("ElevatedButton");
  button1.props.label = "Get Started";
  body.children = [text1, button1];
  scaffold.slots = { appBar, body, drawer: null, bottomNavigationBar: null };
  return { widgetTree: scaffold };
}
