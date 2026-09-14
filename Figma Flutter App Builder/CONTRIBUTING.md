# Contributing

## Development Setup

1. Install Flutter SDK >= 3.19.0
2. Run `flutter pub get`
3. Run `flutter test` to verify everything passes

## Code Style

- Follow `analysis_options.yaml` (strict casts, prefer const, require trailing commas)
- Use meaningful names for nodes, pages, and components
- Keep files focused on a single responsibility
- Write tests for new functionality

## Architecture Principles

- **Clean separation**: UI, Application, Domain, Infrastructure layers
- **Decoupled models**: The internal `UiNode` model is not coupled to Figma
- **No fake functions**: Every function should have a real implementation or a clear interface with a documented mock/test path
- **Modular generators**: Code generation uses AST/IR, not string concatenation
- **Security**: API tokens are never persisted; all secrets stay server-side in generated backends

## Adding a New Widget Type

1. Add the type to `WidgetType` enum in `lib/domain/ui_node.dart`
2. Add mapping logic in `lib/infrastructure/mapping/widget_mapper.dart`
3. Add canvas rendering in `lib/ui/canvas.dart`
4. Add an icon in `lib/ui/layer_tree.dart`
5. Write tests in `test/infrastructure/widget_mapper_test.dart`

## Adding a New Figma Node Type

1. Add the type to `FigmaNodeType` enum in `lib/domain/figma/figma_node.dart`
2. Add conversion logic in `lib/infrastructure/figma/figma_parser.dart`
3. Add test fixtures and tests

## Adding a New Auth Provider

1. Add to `AuthProviderType` enum in `lib/domain/models.dart`
2. Implement the provider interface in the backend generator (Phase 7A)
3. Add toggle UI in the generate dialog

## Testing

- Unit tests: `test/` directory mirrors `lib/` structure
- Fixtures: `test/fixtures/` contains sample Figma JSON
- Run with `flutter test`
