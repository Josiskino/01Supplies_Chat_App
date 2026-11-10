import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_chat_app/core/providers/auth/auth_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/draft_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';

void main() {
  test(
    'drafts survive leaving a conversation but are cleared on account replacement',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(messageDraftProvider('first').notifier).set('Draft one');
      container.read(messageDraftProvider('second').notifier).set('Draft two');
      expect(container.read(messageDraftProvider('first')), 'Draft one');
      expect(container.read(messageDraftProvider('second')), 'Draft two');
      container
          .read(currentUserProvider.notifier)
          .set(
            const UserEntity(
              id: 'another-account',
              email: '',
              firstName: '',
              lastName: '',
              role: null,
            ),
          );
      expect(container.read(messageDraftProvider('first')), isEmpty);
      expect(container.read(messageDraftProvider('second')), isEmpty);
    },
  );
}
