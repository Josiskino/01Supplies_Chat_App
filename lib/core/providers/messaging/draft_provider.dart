import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_provider.dart';

part 'draft_provider.g.dart';

/// Draft text survives navigation and is reset whenever the account changes.
@Riverpod(keepAlive: true)
class MessageDraft extends _$MessageDraft {
  @override
  String build(String conversationId) {
    ref.watch(currentUserProvider.select((user) => user?.id));
    return '';
  }

  void set(String text) => state = text;
}
