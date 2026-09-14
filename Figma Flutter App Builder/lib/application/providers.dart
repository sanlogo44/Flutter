import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_controller.dart';

/// Global Riverpod provider for the project controller.
///
/// The UI watches this provider and mutates the project through the controller.
/// After mutations, call `ref.notifyListeners()` or use `StateProvider` to
/// trigger UI rebuilds.
final projectControllerProvider = StateProvider<ProjectController>((ref) {
  return ProjectController();
});
