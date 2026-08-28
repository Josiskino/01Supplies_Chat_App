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
import '../../../domain/repository/media/media_repository.dart';
import '../media/media_provider.dart';
import '../realtime/realtime_provider.dart';
import 'support_provider.dart';
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

/// Ce qu'un fil peut être.
///
/// « Non participant » est un **état**, pas un échec. Le représenter par une
/// exception le faisait retenter indéfiniment par Riverpod, avec son backoff
/// exponentiel : le fil repassait en chargement toutes les quelques secondes et
/// l'écran restait bloqué sur son indicateur, sans jamais afficher le motif.
sealed class ThreadState {
  const ThreadState();
}

/// Le fil est accessible.
class ThreadMessages extends ThreadState {
  const ThreadMessages(this.messages);
  final List<MessageEntity> messages;
}

/// Le dossier n'a pas été pris en charge : l'API refuse la lecture.
class ThreadLocked extends ThreadState {
  const ThreadLocked();
}

/// Le fil d'une conversation.
///
/// ## L'accès n'est pas acquis
///
/// Un admin qui n'a pas pris le dossier n'est **pas participant** : l'API
/// répond « Not a participant in this conversation ». C'est l'état normal d'un
/// ticket qui attend dans la file, et l'écran doit proposer de s'en saisir.
@riverpod
class Thread extends _$Thread {
  @override
  Future<ThreadState> build(String conversationId) async {
    final result = await ref
        .read(fetchMessagesUseCaseProvider)
        .call(FetchMessagesParams(conversationId: conversationId));

    // Le refus d'accès sort par la porte des valeurs, pas par celle des
    // exceptions : c'est une réponse du serveur, pas une panne. Les autres
    // échecs restent des exceptions, et le réessai de Riverpod y est utile —
    // une coupure réseau finit par se rétablir, un droit manquant non.
    if (result.isLeft()) {
      final failure = result.getLeft().toNullable()!;
      if (failure is ForbiddenFailure) return const ThreadLocked();
      throw Exception(failure.message);
    }
    final messages = result.getRight().toNullable()!;

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

    return ThreadMessages(messages);
  }

  /// Envoie un message et l'ajoute au fil sans attendre un rechargement.
  ///
  /// Le message revient du serveur avec son identifiant définitif : on l'insère
  /// tel quel plutôt que de deviner localement, faute de quoi une réponse citée
  /// pointerait sur un identifiant qui n'existe pas encore.
  Future<bool> send(
    String content, {
    String? replyTo,
    MessageType type = MessageType.text,
    List<String> attachmentMediaIds = const [],
  }) async {
    final trimmed = content.trim();
    // Un texte vide reste refusé, sauf s'il accompagne une pièce jointe : une
    // photo se passe très bien de légende.
    if (trimmed.isEmpty && attachmentMediaIds.isEmpty) return false;

    final result = await ref
        .read(sendMessageUseCaseProvider)
        .call(
          SendMessageParams(
            conversationId: conversationId,
            content: trimmed,
            replyTo: replyTo,
            type: type,
            attachmentMediaIds: attachmentMediaIds,
          ),
        );

    return result.match((_) => false, (message) {
      final current = switch (state.value) {
        ThreadMessages(:final messages) => messages,
        _ => const <MessageEntity>[],
      };
      state = AsyncValue.data(ThreadMessages([...current, message]));

      // La liste porte le dernier message et sa date : sans ce rechargement,
      // la conversation où l'on vient d'écrire garde l'aperçu précédent et ne
      // remonte pas en tête.
      ref.invalidate(supportQueueProvider);
      return true;
    });
  }

  Future<void> markRead() async {
    final result = await ref
        .read(markReadUseCaseProvider)
        .call(MarkReadParams(conversationId));

    // La file porte les compteurs : sans ce rechargement, la pastille de
    // non-lus reste affichée alors que le fil vient d'être lu.
    if (result.isRight()) ref.invalidate(supportQueueProvider);
  }

  /// Dépose des fichiers puis les envoie dans un seul message.
  ///
  /// L'envoi n'a lieu qu'une fois **tous** les dépôts réussis : un message
  /// partiel afficherait deux photos sur trois sans que rien ne signale la
  /// troisième.
  ///
  /// Une bulle provisoire paraît immédiatement, avec les fichiers **locaux** :
  /// le téléversement peut durer, et sans elle l'utilisateur ne voit rien
  /// partir. Elle est remplacée par le message du serveur, ou retirée si
  /// l'envoi échoue.
  Future<bool> sendAttachments({
    required List<String> filePaths,
    required MessageType type,
    String content = '',
    String? replyTo,
  }) async {
    if (filePaths.isEmpty) return false;

    final pendingId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    _appendPending(pendingId, filePaths, type, content);

    final ids = <String>[];
    for (final path in filePaths) {
      final upload = await ref
          .read(uploadMediaUseCaseProvider)
          .call(UploadMediaParams(path));
      final media = upload.getRight().toNullable();
      // Un identifiant vide signalerait un dépôt mal lu : l'envoyer ferait
      // refuser le message par le serveur, avec une erreur qui ne dirait rien
      // du vrai problème.
      if (media == null || media.id.isEmpty) {
        _removePending(pendingId);
        return false;
      }
      ids.add(media.id);
    }

    final sent = await send(
      content,
      replyTo: replyTo,
      type: type,
      attachmentMediaIds: ids,
    );
    _removePending(pendingId);
    return sent;
  }

  /// Insère la bulle provisoire, avec les chemins locaux comme pièces jointes.
  void _appendPending(
    String id,
    List<String> filePaths,
    MessageType type,
    String content,
  ) {
    final current = switch (state.value) {
      ThreadMessages(:final messages) => messages,
      _ => const <MessageEntity>[],
    };
    state = AsyncValue.data(
      ThreadMessages([
        ...current,
        MessageEntity(
          id: id,
          conversationId: conversationId,
          senderId: ref.read(currentUserProvider)?.id ?? '',
          content: content,
          type: type,
          delivery: MessageDelivery.sent,
          sentAt: DateTime.now(),
          attachments: filePaths,
          isPending: true,
        ),
      ]),
    );
  }

  void _removePending(String id) {
    final current = switch (state.value) {
      ThreadMessages(:final messages) => messages,
      _ => const <MessageEntity>[],
    };
    state = AsyncValue.data(
      ThreadMessages([...current.where((m) => m.id != id)]),
    );
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Identifiant du compte connecté, pour distinguer ses propres bulles.
@riverpod
String? currentUserId(Ref ref) => ref.watch(currentUserProvider)?.id;
