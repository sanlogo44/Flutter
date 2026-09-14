/// Undo/redo stack for project mutations.
///
/// Maintains a bounded history of serialized project snapshots. The controller
/// applies mutations, and each mutation pushes a snapshot onto the undo stack.
library;

import '../../domain/project_model.dart';
import '../infrastructure/persistence/project_serializer.dart';

class UndoRedoStack {
  UndoRedoStack({this.maxHistory = 50, ProjectSerializer? serializer})
      : _serializer = serializer ?? ProjectSerializer();

  final int maxHistory;
  final ProjectSerializer _serializer;

  final List<ProjectModel> _undoStack = [];
  final List<ProjectModel> _redoStack = [];

  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Push the current state before a mutation is applied.
  void pushState(ProjectModel state) {
    _undoStack.add(_serializer.clone(state));
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    // Clear redo stack when a new action is performed.
    _redoStack.clear();
  }

  /// Undo: return the previous state, pushing current onto redo stack.
  ProjectModel? undo(ProjectModel currentState) {
    if (!canUndo) return null;
    _redoStack.add(_serializer.clone(currentState));
    return _undoStack.removeLast();
  }

  /// Redo: return the next state, pushing current onto undo stack.
  ProjectModel? redo(ProjectModel currentState) {
    if (!canRedo) return null;
    _undoStack.add(_serializer.clone(currentState));
    return _redoStack.removeLast();
  }

  /// Reset the stack with an initial state.
  void reset(ProjectModel initialState) {
    _undoStack.clear();
    _redoStack.clear();
    _undoStack.add(_serializer.clone(initialState));
  }

  /// Clear all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
