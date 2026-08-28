import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/abstract/directory/directory_datasource_contract.dart';
import '../../../data/datasources/remote/directory_remote_datasource.dart';
import '../../../data/repository/directory_repository_impl.dart';
import '../../../domain/entity/auth/user_entity.dart';
import '../../../domain/repository/directory/directory_repository.dart';
import '../../../domain/usecases/directory/directory_usecases.dart';
import '../request/api_provider.dart';

part 'directory_provider.g.dart';

// ── Infrastructure ──────────────────────────────────────────────────────────

@riverpod
DirectoryDataSourceContract directoryDataSource(Ref ref) =>
    DirectoryRemoteDataSource(ref.watch(apiClientProvider));

@riverpod
DirectoryRepository directoryRepository(Ref ref) =>
    DirectoryRepositoryImpl(ref.watch(directoryDataSourceProvider));

// ── Use cases ───────────────────────────────────────────────────────────────

@riverpod
FetchContactsUseCase fetchContactsUseCase(Ref ref) =>
    FetchContactsUseCase(ref.watch(directoryRepositoryProvider));

// ── Notifier ────────────────────────────────────────────────────────────────

/// Le répertoire des clients et partenaires.
///
/// Chargé **en une fois** plutôt que page par page : la plateforme compte moins
/// de deux cents interlocuteurs, et une liste complète en mémoire rend la
/// recherche instantanée, sans aller-retour réseau à chaque lettre tapée. Le
/// jour où ce volume décuplera, c'est `query` côté serveur qu'il faudra brancher
/// — le paramètre est déjà prévu.
@riverpod
class Contacts extends _$Contacts {
  @override
  Future<List<UserEntity>> build() async {
    final result = await ref
        .read(fetchContactsUseCaseProvider)
        .call(const FetchContactsParams());

    return result.match((failure) => throw Exception(failure.message), (page) {
      final contacts = [...page.contacts];
      // Tri par nom : l'API rend l'ordre de création, qui ne veut rien dire
      // pour quelqu'un qui cherche un interlocuteur.
      contacts.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return contacts;
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
    await future;
  }
}
