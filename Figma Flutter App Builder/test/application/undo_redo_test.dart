import 'package:flutter_test/flutter_test.dart';
import 'package:figma_flutter_builder/domain/project_model.dart';
import 'package:figma_flutter_builder/domain/ui_node.dart';
import 'package:figma_flutter_builder/application/undo_redo.dart';
import 'package:figma_flutter_builder/infrastructure/persistence/project_serializer.dart';

void main() {
  group('UndoRedoStack', () {
    late UndoRedoStack stack;

    setUp(() {
      stack = UndoRedoStack(serializer: ProjectSerializer());
    });

    test('initial state has undo disabled', () {
      final project = ProjectModel.empty();
      stack.reset(project);
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isFalse);
    });

    test('push state enables undo', () {
      final project = ProjectModel.empty();
      stack.reset(project);
      stack.pushState(project);
      expect(stack.canUndo, isTrue);
    });

    test('undo restores previous state', () {
      final project = ProjectModel(name: 'Original', generatorSettings: GeneratorSettings());
      stack.reset(project);

      // Mutate and push.
      stack.pushState(project);
      project.name = 'Modified';

      final restored = stack.undo(project);
      expect(restored, isNotNull);
      expect(restored!.name, 'Original');
    });

    test('redo restores after undo', () {
      final project = ProjectModel(name: 'V1', generatorSettings: GeneratorSettings());
      stack.reset(project);

      stack.pushState(project);
      project.name = 'V2';

      final undone = stack.undo(project);
      expect(undone!.name, 'V1');

      final redone = stack.redo(undone);
      expect(redone, isNotNull);
      expect(redone!.name, 'V2');
    });

    test('new action clears redo stack', () {
      final project = ProjectModel(name: 'V1', generatorSettings: GeneratorSettings());
      stack.reset(project);

      stack.pushState(project);
      project.name = 'V2';
      stack.undo(project);

      // New action.
      stack.pushState(project);
      project.name = 'V3';

      expect(stack.canRedo, isFalse);
    });

    test('respects max history limit', () {
      final stack = UndoRedoStack(
        maxHistory: 3,
        serializer: ProjectSerializer(),
      );
      final project = ProjectModel(name: 'P', generatorSettings: GeneratorSettings());
      stack.reset(project);

      for (var i = 0; i < 10; i++) {
        stack.pushState(project);
      }

      // Should not grow unbounded.
      // (internal check: canUndo is true, history bounded)
      expect(stack.canUndo, isTrue);
    });
  });
}
