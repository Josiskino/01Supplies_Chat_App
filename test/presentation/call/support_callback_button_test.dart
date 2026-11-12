import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplies_calls/support.dart';
import 'package:supplies_chat_app/presentation/pages/call/widgets/support_callback_button.dart';

void main() {
  for (final eligible in [false, true]) {
    testWidgets('callback action eligibility $eligible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [supportCallsEnabledProvider.overrideWithValue(true)],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  SupportCallbackButton(
                    conversationId: 'thread',
                    eligible: eligible,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        find.byTooltip('Appeler le client'),
        eligible ? findsOneWidget : findsNothing,
      );
    });
  }
}
