import 'package:fpdart/fpdart.dart';

import 'failure.dart';

/// Contrat d'un cas d'usage.
///
/// Un use case sans paramètre déclare quand même une classe de params
/// (`const GetConversationsParams()`) plutôt que `void` : ajouter un filtre plus
/// tard ne casse alors aucun appelant.
abstract interface class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}
