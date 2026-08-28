import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/preferences.dart';

part 'pinned_provider.g.dart';

/// Conversations épinglées, gardées en tête de liste.
///
/// ## Stockage local
///
/// L'API n'expose aucun champ d'épinglage : `PATCH /conversations/{id}`
/// n'accepte que `name` et `description`, et la conversation n'en porte pas.
/// L'épinglage vit donc sur l'appareil.
///
/// Conséquence à connaître : ce qu'on épingle sur ce téléphone ne se retrouve
/// ni sur le web ni sur un autre appareil. Le jour où le backend l'exposera,
/// seul ce provider changera — les écrans lisent déjà un simple ensemble
/// d'identifiants.
@Riverpod(keepAlive: true)
class PinnedConversations extends _$PinnedConversations {
  @override
  Set<String> build() {
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final raw = await SharedPreferencesHelper.getValue(
      StorageKeys.pinnedConversations,
    );
    if (!ref.mounted || raw.isEmpty) return;
    state = raw.split(',').where((id) => id.isNotEmpty).toSet();
  }

  Future<void> toggle(String conversationId) async {
    final next = {...state};
    if (!next.remove(conversationId)) next.add(conversationId);
    state = next;
    await SharedPreferencesHelper.setValue(
      StorageKeys.pinnedConversations,
      next.join(','),
    );
  }

  bool isPinned(String conversationId) => state.contains(conversationId);
}
