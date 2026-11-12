import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_calls/support.dart';

class SupportCallbackButton extends ConsumerWidget {
  const SupportCallbackButton({
    required this.conversationId,
    required this.eligible,
    super.key,
  });
  final String conversationId;
  final bool eligible;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!eligible || !ref.watch(supportCallsEnabledProvider)) {
      return const SizedBox.shrink();
    }
    return IconButton(
      tooltip: 'Appeler le client',
      icon: const Icon(Icons.phone_outlined),
      onPressed: () {
        final state = ref.read(supportCallControllerProvider);
        if (state.active?.isActive != true) {
          unawaited(
            ref
                .read(supportCallControllerProvider.notifier)
                .start(conversationId),
          );
        }
        context.push('/call');
      },
    );
  }
}
