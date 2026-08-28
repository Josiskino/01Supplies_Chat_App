import 'package:fpdart/fpdart.dart';

import '../../../core/abstract/failure.dart';
import '../../../core/abstract/usecase.dart';
import '../../repository/directory/directory_repository.dart';

/// Charge le répertoire des clients et partenaires.
class FetchContactsUseCase
    implements UseCase<DirectoryPage, FetchContactsParams> {
  const FetchContactsUseCase(this._repository);

  final DirectoryRepository _repository;

  @override
  Future<Either<Failure, DirectoryPage>> call(FetchContactsParams params) =>
      _repository.fetchContacts(params);
}
