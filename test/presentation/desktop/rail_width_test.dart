import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/platform/window_glass.dart';
import 'package:supplies_chat_app/presentation/desktop/widgets/workspace_icon_rail.dart';

void main() {
  test('le rail est assez large pour contenir les boutons système macOS', () {
    // Sur macOS, les trois boutons de fenêtre flottent au-dessus de la première
    // colonne. Un rail plus étroit les laisserait déborder sur la navigation, où
    // ils capteraient le clic à la place des sections — un défaut invisible en
    // test de rendu, puisque ces boutons sont dessinés par le système.
    expect(
      WorkspaceIconRail.width,
      greaterThanOrEqualTo(WindowGlass.windowButtonsWidth),
    );
  });
}
