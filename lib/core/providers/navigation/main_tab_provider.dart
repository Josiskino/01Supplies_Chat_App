import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_tab_provider.g.dart';

/// Onglet actif de la coquille principale.
///
/// Extrait dans son propre fichier — sur l'app cliente, l'équivalent est défini
/// au milieu du provider de panier, ce qui le rend introuvable. Il vit ici parce
/// que plusieurs écrans doivent pouvoir changer d'onglet à distance (une
/// notification de message ouvre l'onglet Conversations, par exemple).
///
/// `keepAlive` : l'onglet actif doit survivre à la navigation vers un écran hors
/// coquille. En auto-dispose, revenir des réglages ramènerait sur le premier
/// onglet au lieu de celui qu'on avait quitté.
@Riverpod(keepAlive: true)
class MainTabNotifier extends _$MainTabNotifier {
  @override
  int build() => 0;

  void select(int index) {
    if (index == state) return;
    state = index;
  }
}
