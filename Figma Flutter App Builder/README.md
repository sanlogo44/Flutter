# Figma → Flutter App Builder

A visual builder that imports Figma designs and generates fully editable, compilable Flutter applications.

## Overview

The Figma Flutter App Builder is a desktop application (Flutter/Dart) that lets you:

1. Import a Figma file via URL or file ID using the official Figma REST API
2. Parse the Figma document tree into an internal UI model
3. Visually edit the widget tree in a canvas-based editor
4. Type elements as Flutter components (Button, TextField, Card, etc.)
5. Define state, variables, API calls, and logic via a node-based editor
6. Generate clean, modular, compilable Dart code
7. Export a complete Flutter project (ZIP or folder)
8. Optionally generate a backend with authentication

## Quick Start

### Prerequisites

- Flutter SDK >= 3.19.0
- Dart SDK >= 3.3.0

### Installation

```bash
flutter pub get
```

### Run the Builder

```bash
flutter run -d macos  # or windows / linux
```

### Run Tests

```bash
flutter test
```

## Architecture

The project follows a Clean Architecture with clear separation between UI, Domain, and Infrastructure layers. See [ARCHITECTURE.md](ARCHITECTURE.md) for full details.

### Layers

| Layer | Responsibility |
|---|---|
| **UI / Editor** | Toolbar, Layer Tree, Canvas, Inspector, Logic Editor, Code Preview |
| **Application** | ProjectController, Undo/Redo, Component Registry, Logic Controller |
| **Domain / Core** | UiNode, ProjectModel, WidgetModel, LogicGraph, DesignSystem |
| **Infrastructure** | Figma API Client, Parser, Widget Mapper, Code Generator, Serializer, Validator, Exporter |

### Data Flow

```
Figma File → Figma API → Parsed Nodes → Internal UI Model
    → Widget Tree → Editable Canvas → Logic/State/Data
    → Code Generator → Dart Files → Flutter Project
```

## Key Components

### Figma Import

- **FigmaLinkParser**: Extracts file IDs from Figma URLs (`/design/`, `/file/`, `/proto/`)
- **FigmaApiClient**: HTTP client for the Figma REST API with proper error handling (auth, rate limit, not found, server errors)
- **FigmaParser**: Converts Figma JSON into the internal `UiNode` tree with intelligent mapping (auto-layout → Row/Column, fills → colors, effects → shadows)

### Internal UI Model

The `UiNode` class is the central data structure. It is decoupled from Figma so other design sources can be added later. It captures:

- Widget type, layout (direction, padding, spacing, alignment, sizing)
- Style (fill, border, radius, shadow, opacity, gradient)
- Text data (font, size, weight, color, alignment)
- Widget configuration (typed Flutter widgets with actions)
- Children (recursive tree)

### Code Generation

The code generator uses a two-stage approach:

1. **WidgetMapper**: Converts `UiNode` → `WidgetModel` (Flutter widget IR)
2. **DartGenerator**: Renders `WidgetModel` → formatted Dart source code

The `ProjectGenerator` orchestrates the generation of a complete Flutter project structure including `main.dart`, pages, models, services, state, theme, and router.

### Editor

The editor shell is a three-panel layout:

- **Left**: Layer Tree (pages + node hierarchy)
- **Center**: Canvas (live visual preview of the widget tree)
- **Right**: Inspector (properties: layout, style, typography, widget type, actions)
- **Bottom**: Logic Editor / Code Preview (switchable)

### Undo/Redo

All mutations go through `ProjectController`, which maintains a bounded history stack of serialized project snapshots.

## Project Structure

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
│   │   ├── models.dart
│   │   └── figma/
│   │       └── figma_node.dart
│   ├── application/
│   │   ├── project_controller.dart
│   │   └── undo_redo.dart
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
│   ├── fixtures/
│   │   └── figma_login_sample.json
│   ├── application/
│   ├── infrastructure/
│   └── domain/
├── pubspec.yaml
├── analysis_options.yaml
├── ARCHITECTURE.md
└── README.md
```

## Figma API Setup

1. Get a Figma Personal Access Token from Settings > Account > Personal access tokens
2. In the builder, click "Import Figma" in the toolbar
3. Paste your Figma file URL and access token
4. The token is used in-memory only and never persisted

## Dependencies

| Package | Purpose | Why Selected |
|---|---|---|
| `flutter_riverpod` | State management | Type-safe, testable, declarative |
| `http` | Figma API calls | Standard, well-maintained |
| `uuid` | Node ID generation | Reliable unique IDs |
| `archive` | ZIP export | Pure-Dart ZIP encoding |
| `path` | File path handling | Cross-platform paths |
| `fl_chart` | Chart preview | Popular Flutter charting library |
| `json_annotation` | JSON serialization | Type-safe serialization |

## Testing

```bash
flutter test
```

Test coverage includes:

- **FigmaLinkParser**: URL parsing, file ID extraction
- **FigmaParser**: JSON → UiNode conversion, auto-layout detection, color/style mapping
- **WidgetMapper**: UiNode → WidgetModel mapping for all widget types
- **DartGenerator**: Widget code rendering
- **ProjectSerializer**: Round-trip JSON serialization
- **ProjectValidator**: Validation rules
- **UndoRedoStack**: History management
- **ProjectGenerator**: Full project generation

## Development Phases

- **Phase 1 – Foundation** ✅: Project structure, domain models, editor shell, serialization, tests
- **Phase 2 – Figma Import** ✅: API client, parser, node mapping
- **Phase 3 – Visual Editor** ✅: Canvas, layer tree, inspector
- **Phase 4 – Components**: Widget typing, component system, design system (partial)
- **Phase 5 – Logic**: Node editor (scaffold), events, actions, conditions
- **Phase 6 – Data**: REST API, models, data binding, charts
- **Phase 7 – Code Generation** ✅: IR, AST, Dart generator, project generator
- **Phase 7A – Backend & Auth**: Backend generator, DB schema, auth providers (planned)
- **Phase 8 – Preview**: Live preview (partial – canvas preview works)
- **Phase 9 – Export** ✅: ZIP, folder export
- **Phase 10 – Quality**: Tests ✅, error handling ✅, documentation ✅

## License

This project is generated as a builder tool for Flutter development.
