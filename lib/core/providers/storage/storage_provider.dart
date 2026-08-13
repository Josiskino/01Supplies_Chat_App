import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../abstract/local_storage_interface.dart';
import '../../services/local_storage/shared_preferences_storage.dart';
import '../../services/storage_service.dart';

part 'storage_provider.g.dart';

/// Stockage clé/valeur brut. Surchargeable en test via `overrideWith`.
@riverpod
LocalStorageInterface localStorage(Ref ref) => SharedPreferencesStorage();

/// Préférences d'affichage (thème, langue).
@riverpod
StorageService storageService(Ref ref) => StorageService.instance;
