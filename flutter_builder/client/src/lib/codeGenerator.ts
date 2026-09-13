import type { WidgetNode, GeneratedFile, BuilderProject, DataModel, LogicAction } from "./types";
import type { FlutterWidgetType } from "./types";
import { WIDGET_DEFINITIONS } from "./widgetDefs";

// ===== Dart Code Generator =====

function colorToDart(hex: string): string {
  if (!hex || hex === "transparent") return "Colors.transparent";
  if (hex.startsWith("#")) {
    const hexValue = hex.replace("#", "");
    if (hexValue.length === 6) {
      const r = parseInt(hexValue.slice(0, 2), 16);
      const g = parseInt(hexValue.slice(2, 4), 16);
      const b = parseInt(hexValue.slice(4, 6), 16);
      const a = 255;
      return `Color(0x${a.toString(16).padStart(2, "0")}${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")})`;
    }
    if (hexValue.length === 8) {
      return `Color(0x${hexValue.toUpperCase()})`;
    }
  }
  // Named colors
  const namedColors: Record<string, string> = {
    red: "Colors.red",
    blue: "Colors.blue",
    green: "Colors.green",
    white: "Colors.white",
    black: "Colors.black",
    grey: "Colors.grey",
    yellow: "Colors.yellow",
    orange: "Colors.orange",
    purple: "Colors.purple",
    pink: "Colors.pink",
    teal: "Colors.teal",
    cyan: "Colors.cyan",
    indigo: "Colors.indigo",
  };
  return namedColors[hex.toLowerCase()] || "Colors.black";
}

function fontWeightToDart(weight: string): string {
  const map: Record<string, string> = {
    normal: "FontWeight.normal",
    bold: "FontWeight.bold",
    w100: "FontWeight.w100",
    w200: "FontWeight.w200",
    w300: "FontWeight.w300",
    w400: "FontWeight.w400",
    w500: "FontWeight.w500",
    w600: "FontWeight.w600",
    w700: "FontWeight.w700",
    w800: "FontWeight.w800",
    w900: "FontWeight.w900",
  };
  return map[weight] || "FontWeight.normal";
}

function textAlignToDart(align: string): string {
  const map: Record<string, string> = {
    left: "TextAlign.left",
    center: "TextAlign.center",
    right: "TextAlign.right",
    justify: "TextAlign.justify",
  };
  return map[align] || "TextAlign.left";
}

function alignmentToDart(align: string): string {
  const map: Record<string, string> = {
    center: "Alignment.center",
    centerLeft: "Alignment.centerLeft",
    centerRight: "Alignment.centerRight",
    topCenter: "Alignment.topCenter",
    topLeft: "Alignment.topLeft",
    topRight: "Alignment.topRight",
    bottomCenter: "Alignment.bottomCenter",
    bottomLeft: "Alignment.bottomLeft",
    bottomRight: "Alignment.bottomRight",
    topStart: "AlignmentDirectional.topStart",
    topEnd: "AlignmentDirectional.topEnd",
    centerStart: "AlignmentDirectional.centerStart",
    centerEnd: "AlignmentDirectional.centerEnd",
    bottomStart: "AlignmentDirectional.bottomStart",
    bottomEnd: "AlignmentDirectional.bottomEnd",
  };
  return map[align] || "Alignment.center";
}

function mainAxisAlignmentToDart(align: string): string {
  const map: Record<string, string> = {
    start: "MainAxisAlignment.start",
    center: "MainAxisAlignment.center",
    end: "MainAxisAlignment.end",
    spaceBetween: "MainAxisAlignment.spaceBetween",
    spaceAround: "MainAxisAlignment.spaceAround",
    spaceEvenly: "MainAxisAlignment.spaceEvenly",
  };
  return map[align] || "MainAxisAlignment.start";
}

function crossAxisAlignmentToDart(align: string): string {
  const map: Record<string, string> = {
    start: "CrossAxisAlignment.start",
    center: "CrossAxisAlignment.center",
    end: "CrossAxisAlignment.end",
    stretch: "CrossAxisAlignment.stretch",
  };
  return map[align] || "CrossAxisAlignment.center";
}

function paddingToDart(padding: any): string {
  if (!padding) return "EdgeInsets.zero";
  const { top, right, bottom, left } = padding;
  if (top === right && top === bottom && top === left) {
    return `const EdgeInsets.all(${top})`;
  }
  return `const EdgeInsets.fromLTRB(${left || 0}, ${top || 0}, ${right || 0}, ${bottom || 0})`;
}

function marginToDart(margin: any): string {
  return paddingToDart(margin);
}

function fitToDart(fit: string): string {
  const map: Record<string, string> = {
    cover: "BoxFit.cover",
    contain: "BoxFit.contain",
    fill: "BoxFit.fill",
    fitWidth: "BoxFit.fitWidth",
    fitHeight: "BoxFit.fitHeight",
    none: "BoxFit.none",
  };
  return map[fit] || "BoxFit.cover";
}

function autovalidateModeToDart(mode: string): string {
  const map: Record<string, string> = {
    disabled: "AutovalidateMode.disabled",
    always: "AutovalidateMode.always",
    onUserInteraction: "AutovalidateMode.onUserInteraction",
  };
  return map[mode] || "AutovalidateMode.disabled";
}

function dartStringEscape(str: string): string {
  return str.replace(/\\/g, "\\\\").replace(/'/g, "\\'").replace(/\n/g, "\\n");
}

function getActionForWidget(node: WidgetNode, logic: LogicAction[]): string {
  const actions = logic.filter(l => l.triggerWidgetId === node.id);
  if (actions.length === 0) return "() {}";

  const action = actions[0];
  switch (action.actionType) {
    case "navigate":
      return `() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ${action.config.targetPage || "HomePage"}(),
          ),
        );
      }`;
    case "showAlert":
      return `() {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('${dartStringEscape(action.config.title || "Info")}'),
            content: Text('${dartStringEscape(action.config.message || "")}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }`;
    case "setVariable":
      return `() {
        setState(() {
          ${action.config.varName || "variable"} = ${action.config.value || "value"};
        });
      }`;
    case "apiCall":
      return `() async {
        final response = await http.post(
          Uri.parse('${action.config.url || "https://api.example.com/endpoint"}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            ${action.config.body || ""}
          }),
        );
        if (response.statusCode == 200) {
          // Handle success
        }
      }`;
    case "firebaseAuth":
      return `() async {
        try {
          await FirebaseAuth.instance.${action.config.method || "signInWithEmailAndPassword"}(
            email: '${action.config.email || ""}',
            password: '${action.config.password || ""}',
          );
        } catch (e) {
          // Handle error
        }
      }`;
    case "firestoreRead":
      return `() async {
        final snapshot = await FirebaseFirestore.instance
            .collection('${action.config.collection || "users"}')
            .get();
        // Process documents
      }`;
    case "firestoreWrite":
      return `() async {
        await FirebaseFirestore.instance
            .collection('${action.config.collection || "users"}')
            .add({
              ${action.config.data || ""}
            });
      }`;
    default:
      return "() {}";
  }
}

export function generateWidgetCode(node: WidgetNode, indent: number, logic: LogicAction[] = []): string {
  const pad = "  ".repeat(indent);
  const childPad = "  ".repeat(indent + 1);
  const props = node.props;

  switch (node.type) {
    case "Scaffold": {
      const bgColor = props.backgroundColor ? `backgroundColor: ${colorToDart(props.backgroundColor)},\n${childPad}` : "";
      const appBar = node.slots?.appBar ? `${childPad}appBar: ${generateWidgetCode(node.slots.appBar, indent + 1, logic)},\n` : "";
      const body = node.slots?.body ? `${childPad}body: ${generateWidgetCode(node.slots.body, indent + 1, logic)},\n` : "";
      const drawer = node.slots?.drawer ? `${childPad}drawer: ${generateWidgetCode(node.slots.drawer, indent + 1, logic)},\n` : "";
      const bottomNav = node.slots?.bottomNavigationBar ? `${childPad}bottomNavigationBar: ${generateWidgetCode(node.slots.bottomNavigationBar, indent + 1, logic)},\n` : "";
      return `${pad}Scaffold(\n${childPad}${bgColor}${appBar}${body}${drawer}${bottomNav}${pad})`;
    }

    case "AppBar": {
      const title = props.title ? `${childPad}title: Text('${dartStringEscape(props.title)}'),\n` : "";
      const bgColor = props.backgroundColor ? `${childPad}backgroundColor: ${colorToDart(props.backgroundColor)},\n` : "";
      const fgColor = props.foregroundColor ? `${childPad}foregroundColor: ${colorToDart(props.foregroundColor)},\n` : "";
      const elevation = props.elevation !== undefined ? `${childPad}elevation: ${props.elevation},\n` : "";
      const centerTitle = `${childPad}centerTitle: ${props.centerTitle},\n`;
      const actions = node.slots?.actions ? `${childPad}actions: [\n${generateWidgetCode(node.slots.actions, indent + 2, logic)},\n${childPad}],\n` : "";
      return `${pad}AppBar(\n${title}${bgColor}${fgColor}${elevation}${centerTitle}${actions}${pad})`;
    }

    case "Container": {
      const width = props.width ? `${childPad}width: ${props.width},\n` : "";
      const height = props.height ? `${childPad}height: ${props.height},\n` : "";
      const color = props.color ? `${childPad}color: ${colorToDart(props.color)},\n` : "";
      const padding = props.padding ? `${childPad}padding: ${paddingToDart(props.padding)},\n` : "";
      const margin = props.margin ? `${childPad}margin: ${marginToDart(props.margin)},\n` : "";
      const alignment = props.alignment ? `${childPad}alignment: ${alignmentToDart(props.alignment)},\n` : "";
      const child = node.children[0] ? `${childPad}child: ${generateWidgetCode(node.children[0], indent + 1, logic)},\n` : "";
      let code = `${pad}Container(\n${width}${height}${color}${padding}${margin}${alignment}${child}`;
      // Add borderRadius via ClipRRect if needed
      if (props.borderRadius && props.borderRadius > 0 && node.children[0]) {
        const innerChild = generateWidgetCode(node.children[0], indent + 2, logic);
        code = `${pad}ClipRRect(\n${childPad}borderRadius: BorderRadius.circular(${props.borderRadius}),\n${childPad}child: Container(\n${"  ".repeat(indent + 2)}${width}${height}${color}${padding}${margin}${alignment}child: ${innerChild},\n${childPad}),\n${pad})`;
      }
      return code;
    }

    case "Column": {
      const mainAlign = props.mainAxisAlignment ? `${childPad}mainAxisAlignment: ${mainAxisAlignmentToDart(props.mainAxisAlignment)},\n` : "";
      const crossAlign = props.crossAxisAlignment ? `${childPad}crossAxisAlignment: ${crossAxisAlignmentToDart(props.crossAxisAlignment)},\n` : "";
      const mainSize = props.mainAxisSize ? `${childPad}mainAxisSize: MainAxisSize.${props.mainAxisSize === "max" ? "max" : "min"},\n` : "";
      const children = node.children.length > 0
        ? `${childPad}children: [\n${node.children.map(c => generateWidgetCode(c, indent + 2, logic)).join(",\n")},\n${childPad}],\n`
        : "";
      return `${pad}Column(\n${mainAlign}${crossAlign}${mainSize}${children}${pad})`;
    }

    case "Row": {
      const mainAlign = props.mainAxisAlignment ? `${childPad}mainAxisAlignment: ${mainAxisAlignmentToDart(props.mainAxisAlignment)},\n` : "";
      const crossAlign = props.crossAxisAlignment ? `${childPad}crossAxisAlignment: ${crossAxisAlignmentToDart(props.crossAxisAlignment)},\n` : "";
      const mainSize = props.mainAxisSize ? `${childPad}mainAxisSize: MainAxisSize.${props.mainAxisSize === "max" ? "max" : "min"},\n` : "";
      const children = node.children.length > 0
        ? `${childPad}children: [\n${node.children.map(c => generateWidgetCode(c, indent + 2, logic)).join(",\n")},\n${childPad}],\n`
        : "";
      return `${pad}Row(\n${mainAlign}${crossAlign}${mainSize}${children}${pad})`;
    }

    case "Stack": {
      const alignment = props.alignment ? `${childPad}alignment: ${alignmentToDart(props.alignment)},\n` : "";
      const children = node.children.length > 0
        ? `${childPad}children: [\n${node.children.map(c => generateWidgetCode(c, indent + 2, logic)).join(",\n")},\n${childPad}],\n`
        : "";
      return `${pad}Stack(\n${alignment}${children}${pad})`;
    }

    case "Text": {
      const text = props.text || "";
      const styleParts: string[] = [];
      if (props.fontSize) styleParts.push(`fontSize: ${props.fontSize}`);
      if (props.fontWeight && props.fontWeight !== "normal") styleParts.push(`fontWeight: ${fontWeightToDart(props.fontWeight)}`);
      if (props.color) styleParts.push(`color: ${colorToDart(props.color)}`);
      const style = styleParts.length > 0 ? `${childPad}style: TextStyle(\n${"  ".repeat(indent + 2)}${styleParts.join(",\n" + "  ".repeat(indent + 2))},\n${childPad}),\n` : "";
      const textAlign = props.textAlign && props.textAlign !== "left" ? `${childPad}textAlign: ${textAlignToDart(props.textAlign)},\n` : "";
      const maxLines = props.maxLines ? `${childPad}maxLines: ${props.maxLines},\n` : "";
      return `${pad}Text(\n${childPad}'${dartStringEscape(text)}',\n${style}${textAlign}${maxLines}${pad})`;
    }

    case "Image": {
      const src = props.src || "";
      const width = props.width ? `${childPad}width: ${props.width},\n` : "";
      const height = props.height ? `${childPad}height: ${props.height},\n` : "";
      const fit = props.fit ? `${childPad}fit: ${fitToDart(props.fit)},\n` : "";
      let code = `${pad}Image.network(\n${childPad}'${src}',\n${width}${height}${fit}${pad})`;
      if (props.borderRadius && props.borderRadius > 0) {
        code = `${pad}ClipRRect(\n${childPad}borderRadius: BorderRadius.circular(${props.borderRadius}),\n${childPad}child: Image.network(\n${"  ".repeat(indent + 2)}'${src}',\n${width}${height}${fit}${"  ".repeat(indent + 2)}),\n${pad})`;
      }
      return code;
    }

    case "Icon": {
      const iconName = props.iconName || "star";
      const size = props.size ? `${childPad}size: ${props.size},\n` : "";
      const color = props.color ? `${childPad}color: ${colorToDart(props.color)},\n` : "";
      return `${pad}Icon(\n${childPad}Icons.${iconName},\n${size}${color}${pad})`;
    }

    case "ElevatedButton": {
      const label = props.label || "Button";
      const bgColor = props.backgroundColor ? `${childPad}style: ElevatedButton.styleFrom(\n${"  ".repeat(indent + 2)}backgroundColor: ${colorToDart(props.backgroundColor)},\n${"  ".repeat(indent + 2)}foregroundColor: ${colorToDart(props.foregroundColor || "#FFFFFF")},\n${"  ".repeat(indent + 2)}shape: RoundedRectangleBorder(\n${"  ".repeat(indent + 3)}borderRadius: BorderRadius.circular(${props.borderRadius || 8}),\n${"  ".repeat(indent + 2)}),\n${childPad}),\n` : "";
      const onPressed = `${childPad}onPressed: ${getActionForWidget(node, logic)},\n`;
      return `${pad}ElevatedButton(\n${onPressed}${bgColor}${childPad}child: Text('${dartStringEscape(label)}'),\n${pad})`;
    }

    case "TextField": {
      const decorationParts: string[] = [];
      if (props.label) decorationParts.push(`labelText: '${dartStringEscape(props.label)}'`);
      if (props.hintText) decorationParts.push(`hintText: '${dartStringEscape(props.hintText)}'`);
      if (props.prefixIcon) decorationParts.push(`prefixIcon: const Icon(Icons.${props.prefixIcon})`);
      const borderRadius = props.borderRadius || 8;
      if (decorationParts.length > 0) {
        const dec = `${childPad}decoration: InputDecoration(\n${"  ".repeat(indent + 2)}${decorationParts.join(",\n" + "  ".repeat(indent + 2))},\n${"  ".repeat(indent + 2)}border: OutlineInputBorder(\n${"  ".repeat(indent + 3)}borderRadius: BorderRadius.circular(${borderRadius}),\n${"  ".repeat(indent + 2)}),\n${childPad}),\n`;
        const obscure = props.obscureText ? `${childPad}obscureText: true,\n` : "";
        const maxLines = props.maxLines && props.maxLines > 1 ? `${childPad}maxLines: ${props.maxLines},\n` : "";
        return `${pad}TextField(\n${dec}${obscure}${maxLines}${pad})`;
      }
      return `${pad}TextField(),`;
    }

    case "ListView": {
      const padding = props.padding ? `${childPad}padding: ${paddingToDart(props.padding)},\n` : "";
      const children = node.children.length > 0
        ? `${childPad}children: [\n${node.children.map(c => generateWidgetCode(c, indent + 2, logic)).join(",\n")},\n${childPad}],\n`
        : "";
      return `${pad}ListView(\n${padding}${children}${pad})`;
    }

    case "Card": {
      const color = props.color ? `${childPad}color: ${colorToDart(props.color)},\n` : "";
      const elevation = props.elevation !== undefined ? `${childPad}elevation: ${props.elevation},\n` : "";
      const shape = props.borderRadius ? `${childPad}shape: RoundedRectangleBorder(\n${"  ".repeat(indent + 2)}borderRadius: BorderRadius.circular(${props.borderRadius}),\n${childPad}),\n` : "";
      const margin = props.margin ? `${childPad}margin: ${marginToDart(props.margin)},\n` : "";
      const child = node.children[0] ? `${childPad}child: ${generateWidgetCode(node.children[0], indent + 1, logic)},\n` : "";
      return `${pad}Card(\n${color}${elevation}${shape}${margin}${child}${pad})`;
    }

    case "GridView": {
      const crossAxis = `${childPad}gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(\n${"  ".repeat(indent + 2)}crossAxisCount: ${props.crossAxisCount || 2},\n${"  ".repeat(indent + 2)}crossAxisSpacing: ${props.crossAxisSpacing || 8},\n${"  ".repeat(indent + 2)}mainAxisSpacing: ${props.mainAxisSpacing || 8},\n${"  ".repeat(indent + 2)}childAspectRatio: ${props.childAspectRatio || 1.0},\n${childPad}),\n`;
      const children = node.children.length > 0
        ? `${childPad}children: [\n${node.children.map(c => generateWidgetCode(c, indent + 2, logic)).join(",\n")},\n${childPad}],\n`
        : "";
      return `${pad}GridView(\n${crossAxis}${children}${pad})`;
    }

    case "Form": {
      const autoValidate = props.autovalidateMode ? `${childPad}autovalidateMode: ${autovalidateModeToDart(props.autovalidateMode)},\n` : "";
      const child = node.children.length > 0 ? `${childPad}child: ${generateWidgetCode(node.children[0], indent + 1, logic)},\n` : "";
      return `${pad}Form(\n${autoValidate}${child}${pad})`;
    }

    case "NavigationBar": {
      const destinations = (props.destinations || "").split(",").map((d: string) => d.trim()).filter(Boolean);
      const destCode = destinations.map((d: string, i: number) => {
        const isSelected = i === (props.selectedIndex || 0);
        return `${"  ".repeat(indent + 2)}NavigationDestination(
${"  ".repeat(indent + 3)}icon: const Icon(Icons.${i === 0 ? "home" : i === 1 ? "search" : "person"}),
${"  ".repeat(indent + 3)}label: '${dartStringEscape(d)}',
${"  ".repeat(indent + 3)}selected: ${isSelected},
${"  ".repeat(indent + 2)}),`;
      }).join("\n");
      const bgColor = props.backgroundColor ? `${childPad}backgroundColor: ${colorToDart(props.backgroundColor)},\n` : "";
      return `${pad}NavigationBar(\n${bgColor}${childPad}destinations: [
${destCode}
${childPad}],
${childPad}onDestinationSelected: (index) {},
${pad})`;
    }

    case "Drawer": {
      const bgColor = props.backgroundColor ? `${childPad}backgroundColor: ${colorToDart(props.backgroundColor)},\n` : "";
      const child = node.children[0] ? `${childPad}child: ${generateWidgetCode(node.children[0], indent + 1, logic)},\n` : "";
      return `${pad}Drawer(\n${bgColor}${child}${pad})`;
    }

    default:
      return `${pad}// Unknown widget: ${node.type}`;
  }
}

export function generatePageDart(pageName: string, widgetTree: WidgetNode, logic: LogicAction[] = []): string {
  const className = pageName.replace(/[^a-zA-Z0-9]/g, "") + "Page";
  const body = generateWidgetCode(widgetTree, 2, logic);
  return `import 'package:flutter/material.dart';

class ${className} extends StatefulWidget {
  const ${className}({super.key});

  @override
  State<${className}> createState() => _${className}State();
}

class _${className}State extends State<${className}> {
  @override
  Widget build(BuildContext context) {
    return ${body};
  }
}
`;
}

export function generateMainDart(project: BuilderProject): string {
  const appName = project.name.replace(/[^a-zA-Z0-9]/g, "");
  return `import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const ${appName}App());
}

class ${appName}App extends StatelessWidget {
  const ${appName}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${project.name}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
`;
}

export function generateModelsDart(models: DataModel[]): string {
  if (models.length === 0) {
    return `// No data models defined yet.
// Add models in the Logic Builder to generate Dart data classes.
`;
  }

  const classes = models.map(m => {
    const fields = m.fields.map(f => `  final ${f.type} ${f.name};`).join("\n");
    const constructor = `  const ${m.name}({${m.fields.map(f => `required this.${f.name}`).join(", ")}});`;
    const fromJson = `  factory ${m.name}.fromJson(Map<String, dynamic> json) => ${m.name}(${m.fields.map(f => `${f.name}: json['${f.name}']`).join(", ")});`;
    const toJson = `  Map<String, dynamic> toJson() => {${m.fields.map(f => `'${f.name}': ${f.name}`).join(", ")}};`;
    return `class ${m.name} {
${fields}

${constructor}

${fromJson}

${toJson}
}`;
  }).join("\n\n");

  return `// Generated data models
// Do not edit manually — regenerate from the Flutter Builder.

${classes}
`;
}

export function generateServicesDart(project: BuilderProject): string {
  const hasApi = project.logic.some(l => l.actionType === "apiCall");
  const hasFirebase = project.logic.some(l => l.actionType.startsWith("firebase"));

  let imports = `import 'dart:convert';\n`;
  if (hasApi) imports += `import 'package:http/http.dart' as http;\n`;
  if (hasFirebase) {
    imports += `import 'package:firebase_auth/firebase_auth.dart';\nimport 'package:cloud_firestore/cloud_firestore.dart';\n`;
  }

  let services = "";

  if (hasApi) {
    services += `
class ApiService {
  static const String baseUrl = 'https://api.example.com';

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(Uri.parse('\$baseUrl/\$endpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load data');
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('\$baseUrl/\$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to post data');
  }
}
`;
  }

  if (hasFirebase) {
    services += `
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    await _firestore.collection(collection).add(data);
  }

  Future<QuerySnapshot> getDocuments(String collection) async {
    return await _firestore.collection(collection).get();
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _firestore.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _firestore.collection(collection).doc(docId).delete();
  }
}
`;
  }

  if (services === "") {
    services = `// No services needed for this project.
// Add API calls or Firebase actions in the Logic Builder to generate service classes.
`;
  }

  return `${imports}\n${services}`;
}

export function generateProjectFiles(project: BuilderProject): GeneratedFile[] {
  const files: GeneratedFile[] = [];

  files.push({
    path: "lib/main.dart",
    content: generateMainDart(project),
    language: "dart",
  });

  files.push({
    path: "lib/pages/home_page.dart",
    content: generatePageDart("Home", project.widgetTree, project.logic),
    language: "dart",
  });

  files.push({
    path: "lib/models/app_models.dart",
    content: generateModelsDart(project.models),
    language: "dart",
  });

  files.push({
    path: "lib/services/api_service.dart",
    content: generateServicesDart(project),
    language: "dart",
  });

  files.push({
    path: "pubspec.yaml",
    content: generatePubspecYaml(project),
    language: "yaml",
  });

  return files;
}

export function generatePubspecYaml(project: BuilderProject): string {
  const hasApi = project.logic.some(l => l.actionType === "apiCall");
  const hasFirebase = project.logic.some(l => l.actionType.startsWith("firebase"));

  let deps = `  flutter:\n    sdk: flutter\n  cupertino_icons: ^1.0.6`;
  if (hasApi) deps += `\n  http: ^1.2.0`;
  if (hasFirebase) deps += `\n  firebase_core: ^3.0.0\n  firebase_auth: ^5.0.0\n  cloud_firestore: ^5.0.0`;

  return `name: ${project.packageName}
description: ${project.description || "A Flutter app generated with Flutter Builder"}
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
${deps}

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
`;
}
