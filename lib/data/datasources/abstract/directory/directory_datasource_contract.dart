import '../../../../core/utils/api_types.dart';
import '../../../../domain/entity/auth/user_role.dart';
import '../../../models/directory/user_page_model.dart';

/// Accès distant au répertoire des interlocuteurs.
abstract interface class DirectoryDataSourceContract {
  Future<ApiResult<UserPageModel>> fetchUsers({
    required List<UserRole> roles,
    String? query,
    int page,
    int limit,
  });
}
