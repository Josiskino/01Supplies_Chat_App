import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supplies_chat_app/config/theme/theme.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/pinned_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/core/providers/realtime/realtime_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/presentation/pages/conversations/conversations_screen.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';

final entries = [
  ('Aline Kponton', 'Bonjour, ma commande est-elle en route ?'),
  ('Service Livraison Nord', 'Le colis vient d’être récupéré.'),
  ('Restaurant Le Baobab', 'La commande sera prête dans 10 minutes.'),
  ('Nadia Sowah', 'Merci pour votre aide !'),
  ('Boutique Adidogomé', 'Je vous confirme le point de retrait.'),
  ('Komi Dossou', 'Le client a bien reçu son colis.'),
  ('Fatou Diarra', 'Puis-je modifier mon adresse de livraison ?'),
  ('Épicerie Bè-Kpota', 'Nous avons préparé les articles.'),
  ('Yao Mensah', 'Parfait, merci pour le suivi.'),
  ('Sylvie Amegan', 'Je serai disponible à partir de 14 h.'),
].indexed.map((row) => ConversationListEntry(
  conversationId: 'sample-${row.$1}',
  title: row.$2.$1,
  preview: row.$2.$2,
  date: DateTime.now().subtract(Duration(minutes: 5 + row.$1 * 38)),
  isSupport: row.$1.isEven,
  ticketId: row.$1.isEven ? 'ticket-${row.$1}' : null,
)).toList();

class CaptureQueue extends SupportQueue {
  @override
  Future<List<ConversationListEntry>> build() async => entries;
}

class CapturePins extends PinnedConversations {
  @override
  Set<String> build() => {'sample-0', 'sample-1', 'sample-2'};
}

class CaptureThread extends Thread {
  CaptureThread(this.scene);
  final int scene;

  @override
  Future<ThreadState> build(String conversationId) async {
    const agent = UserEntity(id: 'agent', email: '', firstName: 'Kodjo', lastName: 'A.', role: null);
    const client = UserEntity(id: 'client', email: '', firstName: 'Aline', lastName: 'Kponton', role: null);
    final lines = switch (scene) {
      2 => ['Bonjour, ma commande est-elle en route ?', 'Bonjour Aline ! Votre livreur a récupéré la commande.', 'Super, merci ! Vous avez une estimation ?', 'Il devrait arriver dans environ dix minutes.', 'Parfait, je vous attends.'],
      3 => ['Le colis vient d’être récupéré.', 'Merci ! Vous pouvez me confirmer le point de livraison ?', 'Je vous envoie un vocal avec les indications.', 'Bien reçu, merci !'],
      _ => ['Bonjour, puis-je modifier mon adresse de livraison ?', 'Bien sûr. À quel endroit souhaitez-vous être livrée ?', 'Près de la pharmacie, à Bè.', 'C’est noté, je transmets au livreur.'],
    };
    return ThreadMessages([
      for (final (index, line) in lines.indexed)
        MessageEntity(id: 'message-$index', conversationId: conversationId,
          senderId: index.isOdd ? agent.id : client.id,
          sender: index.isOdd ? agent : client,
          content: line, type: MessageType.text, delivery: MessageDelivery.read,
          sentAt: DateTime.now().subtract(Duration(minutes: lines.length - index))),
    ]);
  }

  @override
  Future<void> markRead() async {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final scene = ValueNotifier(1);
  Timer.periodic(const Duration(seconds: 9), (timer) {
    scene.value = timer.tick + 1;
    if (scene.value == 4) timer.cancel();
  });
  runApp(ValueListenableBuilder<int>(
    valueListenable: scene,
    builder: (_, value, _) => captureApp(value),
  ));
}

Widget captureApp(int scene) {
  const id = 'sample-0';
  return ProviderScope(
    key: ValueKey(scene),
    overrides: [
      currentUserIdProvider.overrideWithValue('agent'),
      supportQueueProvider.overrideWith(CaptureQueue.new),
      pinnedConversationsProvider.overrideWith(CapturePins.new),
      threadProvider(id).overrideWith(() => CaptureThread(scene)),
      typingUsersProvider(id).overrideWith((ref) => Stream.value(scene == 2 ? {'client': 'Aline'} : {})),
      conversationPresenceProvider(id).overrideWith((ref) => Stream.value({'client': <String, dynamic>{}})),
    ],
    child: Builder(builder: (context) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TAppTheme.lightThemeData(context),
      darkTheme: TAppTheme.darkThemeData(context),
      themeMode: scene == 4 ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: scene == 1 ? const ConversationsScreen() : const ConversationDetailScreen(conversationId: id, contactName: 'Aline Kponton'),
    )),
  );
}
