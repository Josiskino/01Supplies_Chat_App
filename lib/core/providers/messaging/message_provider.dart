import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/messaging/message_datasource_contract.dart';
import '../../../data/datasources/remote/message_remote_datasource.dart';
import '../../../data/repository/message_repository_impl.dart';
import '../../../domain/entity/messaging/message_entity.dart';
import '../../../domain/repository/messaging/message_repository.dart';
import '../../../domain/usecases/messaging/message_usecases.dart';
import '../../abstract/failure.dart';
import '../auth/auth_provider.dart';
import '../realtime/realtime_provider.dart';
import '../request/api_provider.dart';

part 'message_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@riverpod
MessageDataSourceContract messageDataSource(Ref ref) =>
    MessageRemoteDataSource(ref.watch(apiClientProvider));

@riverpod
MessageRepository messageRepository(Ref ref) =>
    MessageRepositoryImpl(ref.watch(messageDataSourceProvider));

// ── Use cases ───────────────────────────────────────────────────────────────

@riverpod
FetchMessagesUseCase fetchMessagesUseCase(Ref ref) =>
    FetchMessagesUseCase(ref.watch(messageRepositoryProvider));

@riverpod
SendMessageUseCase sendMessageUseCase(Ref ref) =>
    SendMessageUseCase(ref.watch(messageRepositoryProvider));

@riverpod
MarkReadUseCase markReadUseCase(Ref ref) =>
    MarkReadUseCase(ref.watch(messageRepositoryProvider));

// ── Notifier ────────────────────────────────────────────────────────────────

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond alors « Not a participant in this conversation ». Ce n'est pas une
/// panne mais l'état normal d'un ticket qui attend dans la file, et l'écran doit
/// proposer de s'en saisir plutôt que d'afficher une erreur.
@riverpod
class Thread extends _$Thread {
  @override
  Future<List<MessageEntity>> build(String conversationId) async {
    final result = await ref
        .read(fetchMessagesUseCaseProvider)
        .call(FetchMessagesParams(conversationId: conversationId));

    final messages = result.match((failure) {
      // Distingué des autres échecs pour que l'écran sache quoi proposer.
      if (failure is ForbiddenFailure) throw const NotAParticipant();
      throw Exception(failure.message);
    }, (value) => value);

    // L'abonnement vient **après** le chargement, et seulement s'il a réussi.
    //
    // Souscrire d'abord faisait boucler l'écran sur un dossier non pris en
    // charge : le canal privé refuse la signature à qui n'est pas participant,
    // le plugin retente, et chaque tentative relançait la construction du
    // provider — le fil restait en chargement pour toujours, sans jamais
    // afficher le motif du refus.
    final events = ref.read(messageEventsProvider);
    unawaited(events.watchConversation(conversationId));
    ref.onDispose(() => unawaited(events.unwatchConversation(conversationId)));

    // Un message arrivé par Pusher recharge le fil plutôt que d'y être inséré :
    // le serveur reste seul maître de l'ordre, des accusés et des réactions.
    final sub = events.threadChanges.listen((id) {
      if (id == conversationId) ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    return messages;
  }

  /// Envoie un message et l'ajoute au fil sans attendre un rechargement.
  ///
  /// Le message revient du serveur avec son identifiant définitif : on l'insère
  /// tel quel plutôt que de deviner localement, faute de quoi une réponse citée
  /// pointerait sur un identifiant qui n'existe pas encore.
  Future<bool> send(String content, {String? replyTo}) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    final result = await ref
        .read(sendMessageUseCaseProvider)
        .call(
          SendMessageParams(
            conversationId: conversationId,
            content: trimmed,
            replyTo: replyTo,
          ),
        );

    return result.match((_) => false, (message) {
      final current = state.value ?? const <MessageEntity>[];
      state = AsyncValue.data([...current, message]);
      return true;
    });
  }

  Future<void> markRead() async {
    await ref
        .read(markReadUseCaseProvider)
        .call(MarkReadParams(conversationId));
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// L'utilisateur n'est pas encore participant de cette conversation.
///
/// Type dédié plutôt qu'un message d'erreur : l'écran doit pouvoir proposer la
/// prise en charge, ce qu'une chaîne de caractères ne permet pas de décider.
class NotAParticipant implements Exception {
  const NotAParticipant();

  @override
  String toString() => 'NotAParticipant';
}

/// Identifiant du compte connecté, pour distinguer ses propres bulles.
@riverpod
String? currentUserId(Ref ref) => ref.watch(currentUserProvider)?.id;
