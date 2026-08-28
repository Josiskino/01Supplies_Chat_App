import 'package:fpdart/fpdart.dart';

import '../../core/abstract/base_repository.dart';
import '../../core/abstract/failure.dart';
import '../../domain/repository/directory/directory_repository.dart';
import '../datasources/abstract/directory/directory_datasource_contract.dart';
import '../models/directory/user_page_model.dart';

class DirectoryRepositoryImpl extends BaseRepository
    implements DirectoryRepository {
  DirectoryRepositoryImpl(this._remote);

  final DirectoryDataSourceContract _remote;

  @override
  Future<Either<Failure, DirectoryPage>> fetchContacts(
    FetchContactsParams p,
  ) async {
    final result = await execute<UserPageModel>(
      () => _remote.fetchUsers(
        roles: p.roles,
        query: p.query,
        page: p.page,
        limit: p.limit,
      ),
    );

    return result.map(
      (page) => DirectoryPage(
        contacts: page.users.map((u) => u.toEntity()).toList(),
        total: page.total,
        pages: page.pages,
      ),
    );
  }
}
