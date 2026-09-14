# Architecture – Figma → Flutter App Builder

## Überblick

Der **Figma → Flutter App Builder** ist eine Desktop-Anwendung (Flutter/Dart), die Figma-Designs importiert, in ein internes UI-Modell transformiert, visuell editierbar macht und daraus eine vollständige, kompilierbare Flutter-Anwendung generiert. Optional kann ein vollständiges Backend (Node.js/TypeScript/Prisma/PostgreSQL) inklusive Authentifizierung generiert werden.

Die Architektur folgt einer **Clean Architecture** mit klarer Trennung zwischen UI, Domain und Infrastructure.

---

## Schichten

### 1. UI / Editor Layer
- **Toolbar**: globale Aktionen (Import, Generate, Export, Command Palette)
- **Layer Tree**: Hierarchie der UiNodes, Auswahl, Umbenennung, Drag & Drop
- **Canvas**: visuelle Vorschau des Widget Trees (Editor-Preview, nicht generiertes Flutter)
- **Inspector**: Properties des ausgewählten Nodes (Layout, Style, Typography, Widget-Type, Actions)
- **Logic Editor**: node-basierter Editor für Events, Actions, Conditions
- **Code Preview**: Syntax-highlighted Dart-Code des generierten Projekts

### 2. Application Layer
- **ProjectController**: zentraler State des geöffneten Projekts, Undo/Redo, Mutations
- **ComponentRegistry**: registrierte wiederverwendbare Komponenten
- **StateController**: App/Page/Component State, Variablen
- **LogicController**: LogicGraph, Event/Action-Verarbeitung
- **DataController**: API-Konfigurationen, Modelle, Data Binding

### 3. Domain / Core Layer
- **UiNode**: Knoten im internen UI-Tree (id, name, type, layout, style, text, children, widgetConfig)
- **ProjectModel**: gesamtes Projekt (metadata, uiTree, components, styles, variables, state, logicGraph, apiConfigs, navigation, generatorSettings)
- **FigmaModel**: Repräsentation der Figma-API-Antwort (DOCUMENT, CANVAS, FRAME, ...)
- **WidgetModel**: Flutter-Widget-Repräsentation (intermediate representation)
- **LogicGraph**: Graph aus Events, Actions, Conditions, Variablen
- **AstModel**: Dart-AST-Knoten (Klassen, Methoden, Expressions, Statements)
- **CodeModel**: Datei- und Projektstruktur für die Codegenerierung

### 4. Infrastructure Layer
- **FigmaApiClient**: HTTP-Client für Figma REST API (OAuth/PAT)
- **FigmaParser**: wandelt Figma JSON → UiNode-Tree
- **WidgetMapper**: wandelt UiNode → WidgetModel (intelligentes Mapping)
- **CodeGenerator**: wandelt ProjectModel → Dart AST → formatierte .dart-Dateien
- **ProjectSerializer**: Save/Load als JSON
- **ProjectExporter**: ZIP-Export, Folder-Export
- **Validator**: prüft Projekt vor Export (fehlende Assets, ungültige Nodes, etc.)
- **BackendGenerator** (geplant): generiert Node.js/TypeScript-Backend aus Projektmodell
- **PluginSystem** (geplant): Schnittstellen für Custom Widgets, Nodes, Actions, Generators

---

## Technologie-Stack

### Frontend / Desktop-App
| Bereich | Wahl | Begründung |
|---|---|---|
| Framework | Flutter (Desktop) | plattformübergreifend, native Performance |
| Sprache | Dart | primäre Sprache für Flutter |
| State Management | Riverpod | typsicher, testbar, deklarativer Scope |
| Routing (Editor) | intern (kein go_router nötig, eigene Shell) | Editor ist Single-View mit Panels |
| HTTP | `http` / `dio` | Figma API, generierte API-Clients |
| JSON | `json_annotation` + `json_serializable` | typisierte Serialisierung |
| Code-Generation | `source_gen` | Code-Generator nutzt AST-Modell |
| Testing | `flutter_test`, `mocktail` | Unit/Widget/Golden Tests |
| Charts (Preview) | `fl_chart` | Diagramm-Vorschau im Editor |

### Backend (generiert, geplant)
| Bereich | Wahl |
|---|---|
| Server | Node.js + TypeScript |
| API | REST/JSON, OpenAPI |
| Datenbank | PostgreSQL |
| ORM | Prisma |
| Cache/Rate-Limiting | Redis (optional) |
| Auth | modulares Provider-System |

---

## Datenfluss

```
Figma File → FigmaApiClient → FigmaJson
    → FigmaParser → UiNode-Tree (internes Modell)
    → WidgetMapper → WidgetModel-Tree
    → Editor (Canvas/Inspector/LayerTree)
    → [User edits → ProjectModel mutiert]
    → CodeGenerator → Dart AST → .dart-Dateien
    → ProjectExporter → ZIP/Folder
    → flutter pub get / analyze / test
```

---

## Modularität & Erweiterbarkeit

- **FigmaProvider-Interface**: weitere Designquellen (Sketch, Adobe XD) später möglich
- **WidgetMapping-Registry**: neue Figma→Flutter-Mappings registrierbar
- **AuthProvider-Interface**: Plugin-System für weitere OAuth-Provider
- **CodeGenerator-Interface**: alternative Code-Generatoren (z.B. für andere Frameworks)
- **Node/Action-Registry**: neue Logic-Nodes und Actions registrierbar

---

## Projektstruktur (Builder selbst)

```
figma_flutter_builder/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── theme.dart
│   ├── domain/
│   │   ├── ui_node.dart
│   │   ├── project_model.dart
│   │   ├── widget_model.dart
│   │   ├── logic_graph.dart
│   │   ├── state_model.dart
│   │   ├── component.dart
│   │   ├── design_system.dart
│   │   ├── api_config.dart
│   │   ├── navigation.dart
│   │   └── figma/
│   │       ├── figma_node.dart
│   │       └── figma_types.dart
│   ├── application/
│   │   ├── project_controller.dart
│   │   ├── undo_redo.dart
│   │   ├── component_registry.dart
│   │   └── logic_controller.dart
│   ├── infrastructure/
│   │   ├── figma/
│   │   │   ├── figma_api_client.dart
│   │   │   ├── figma_link_parser.dart
│   │   │   └── figma_parser.dart
│   │   ├── mapping/
│   │   │   └── widget_mapper.dart
│   │   ├── codegen/
│   │   │   ├── ast/
│   │   │   ├── dart_generator.dart
│   │   │   └── project_generator.dart
│   │   ├── persistence/
│   │   │   ├── project_serializer.dart
│   │   │   └── project_exporter.dart
│   │   └── validation/
│   │       └── project_validator.dart
│   └── ui/
│       ├── editor_shell.dart
│       ├── toolbar.dart
│       ├── layer_tree.dart
│       ├── canvas.dart
│       ├── inspector.dart
│       ├── logic_editor.dart
│       ├── code_preview.dart
│       └── command_palette.dart
├── test/
│   ├── domain/...
│   ├── infrastructure/...
│   ├── application/...
│   └── fixtures/
├── pubspec.yaml
├── analysis_options.yaml
├── ARCHITECTURE.md
├── README.md
└── CONTRIBUTING.md
```

---

## Entwicklungsphasen

- **Phase 1 – Foundation** ✅ (dieser Meilenstein): Projektstruktur, Domain-Modelle, Editor-Shell, Serialisierung, erste Tests
- **Phase 2 – Figma Import**: API-Client, Parser, Node-Mapping
- **Phase 3 – Visual Editor**: Canvas, Layer Tree, Inspector, Drag & Drop
- **Phase 4 – Components**: Widget-Typisierung, Component-System, Design-System
- **Phase 5 – Logic**: Node-Editor, Events, Actions, Conditions, State
- **Phase 6 – Data**: REST-API, Models, Data Binding, Charts
- **Phase 7 – Code Generation**: IR, AST, Dart-Generator, Project-Generator
- **Phase 7A – Backend & Auth**: Backend-Generator, DB-Schema, Auth-Provider, OpenAPI, Flutter-API-Client
- **Phase 8 – Preview**: Live-Preview, Hot-Reload
- **Phase 9 – Export**: ZIP, Folder, Flutter-Validierung
- **Phase 10 – Quality**: Tests, Error-Handling, Performance, Doku
