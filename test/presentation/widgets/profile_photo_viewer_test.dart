import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supplies_chat_app/core/constants/app_ui_route.dart';
import 'package:supplies_chat_app/core/l10n/generated/app_localizations.dart';
import 'package:supplies_chat_app/core/platform/app_platform.dart';
import 'package:supplies_chat_app/core/platform/platform_ui_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/message_provider.dart';
import 'package:supplies_chat_app/core/providers/messaging/support_provider.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_entity.dart';
import 'package:supplies_chat_app/domain/entity/auth/user_role.dart';
import 'package:supplies_chat_app/domain/entity/messaging/conversation_list_entry.dart';
import 'package:supplies_chat_app/domain/entity/messaging/message_entity.dart';
import 'package:supplies_chat_app/presentation/pages/conversation_detail/conversation_detail_screen.dart';
import 'package:supplies_chat_app/presentation/widgets/profile_photo/profile_photo_viewer.dart';
import 'package:supplies_chat_app/presentation/widgets/profile_photo/tappable_avatar.dart';

import '../../helpers/test_environment.dart';

const _clientPhoto = 'https://cdn.example.com/client.jpg';
const _driverPhoto = 'https://cdn.example.com/driver.jpg';
const _agentPhoto = _clientPhoto;

const _client = UserEntity(
  id: 'client',
  email: 'afi@example.com',
  firstName: 'Afi',
  lastName: 'Mensah',
  role: UserRole.client,
  avatarUrl: _clientPhoto,
);
const _driver = UserEntity(
  id: 'driver',
  email: 'kofi@example.com',
  firstName: 'Kofi',
  lastName: '',
  role: UserRole.delivery,
  avatarUrl: _driverPhoto,
);
const _noPhoto = UserEntity(
  id: 'nophoto',
  email: 'yao@example.com',
  firstName: 'Yao',
  lastName: '',
  role: UserRole.client,
);

class _Queue extends SupportQueue {
  @override
  Future<List<ConversationListEntry>> build() async => [
    ConversationListEntry(
      conversationId: 'c1',
      title: 'Afi Mensah',
      preview: '',
      date: DateTime(2026, 11, 16),
      avatarUrl: _clientPhoto,
      peerRole: UserRole.client,
      peerId: 'client',
    ),
  ];
}

/// Afi writes several times between the agent's replies, so her avatar
/// shows on several bubbles; Kofi and Yao (no photo) join the thread.
class _Thread extends Thread {
  @override
  Future<ThreadState> build(String conversationId) async {
    MessageEntity message(String id, UserEntity? sender, int minute) =>
        MessageEntity(
          id: id,
          conversationId: conversationId,
          senderId: sender?.id ?? 'me',
          sender: sender,
          content: 'Message $id',
          type: MessageType.text,
          delivery: MessageDelivery.read,
          sentAt: DateTime.now().subtract(Duration(minutes: 30 - minute)),
        );
    return ThreadMessages([
      message('c1m', _client, 0),
      message('me1', null, 1),
      message('c2m', _client, 2),
      message('me2', null, 3),
      message('k1', _driver, 4),
      message('me3', null, 5),
      message('y1', _noPhoto, 6),
      message('me4', null, 7),
      message('c3m', _client, 8),
    ]);
  }

  @override
  Future<void> markRead() async {}
}

GoRouter _router(Widget home) => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => home),
    GoRoute(
      path: AppUiRoute.profilePhotoViewer,
      pageBuilder: (_, state) => buildProfilePhotoViewerPage(state),
    ),
  ],
);

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(402, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportQueueProvider.overrideWith(_Queue.new),
        appPlatformProvider.overrideWithValue(AppPlatform.ios),
        threadProvider('c1').overrideWith(_Thread.new),
        currentUserIdProvider.overrideWithValue('me'),
      ],
      child: MaterialApp.router(
        routerConfig: _router(home),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _openConversation(WidgetTester tester) => _pumpApp(
  tester,
  const ConversationDetailScreen(conversationId: 'c1', contactName: 'Afi'),
);

Finder _hero(String tag) =>
    find.byWidgetPredicate((w) => w is Hero && w.tag == tag);

Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// The viewer's loading spinner never settles in tests (no network), so
/// frames are pumped for a fixed time instead of `pumpAndSettle`.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Avatar exposing [label] to accessibility (matched on the widget, since
/// chat rows may merge semantics nodes).
Finder _avatarLabeled(String label) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

Finder get _viewer => find.byType(ProfilePhotoViewer);

String _viewerUrl(WidgetTester tester) => tester
    .widget<CachedNetworkImage>(
      find.descendant(of: _viewer, matching: find.byType(CachedNetworkImage)),
    )
    .imageUrl;

void main() {
  setUpAll(setUpTestEnvironment);

  testWidgets('bubble avatar opens the sender photo with name and role', (
    tester,
  ) async {
    await _openConversation(tester);
    // Afi heads three runs: one Hero each, no duplicate tag.
    final afi = _avatarLabeled("View Afi Mensah's profile photo");
    expect(afi, findsNWidgets(3));
    await tester.tap(afi.at(1));
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(_viewer, findsOneWidget);
    expect(_viewerUrl(tester), _clientPhoto);
    expect(
      find.descendant(of: _viewer, matching: find.text('Afi Mensah')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _viewer, matching: find.text('Customer')),
      findsOneWidget,
    );
    await _disposeApp(tester);
  });

  testWidgets('each bubble avatar opens its own sender photo', (tester) async {
    await _openConversation(tester);
    await tester.tap(_avatarLabeled("View Kofi's profile photo"));
    await _settle(tester);
    expect(_viewerUrl(tester), _driverPhoto);
    expect(
      find.descendant(of: _viewer, matching: find.text('Driver')),
      findsOneWidget,
    );
    await _disposeApp(tester);
  });

  testWidgets('header avatar opens the peer photo', (tester) async {
    await _openConversation(tester);
    final header = find.ancestor(
      of: _hero('profile-photo:header:c1'),
      matching: _avatarLabeled("View Afi's profile photo"),
    );
    expect(header, findsOneWidget);
    expect(
      tester.getSemantics(header),
      isSemantics(isButton: true, hasTapAction: true),
    );
    expect(tester.getSize(header).height, greaterThanOrEqualTo(44));
    await tester.tap(header);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(_viewerUrl(tester), _clientPhoto);
    expect(
      find.descendant(of: _viewer, matching: find.text('Client')),
      findsOneWidget,
    );
    await _disposeApp(tester);
  });

  testWidgets('an avatar without photo does nothing', (tester) async {
    await _openConversation(tester);
    expect(_avatarLabeled("View Yao's profile photo"), findsNothing);
    final yao = find.ancestor(
      of: find.text('Y'),
      matching: find.byType(TappableAvatar),
    );
    expect(yao, findsOneWidget);
    await tester.tap(yao);
    await _settle(tester);
    expect(_viewer, findsNothing);
    await _disposeApp(tester);
  });

  group('viewer dismissal', () {
    Widget host() => const Scaffold(
      body: Center(
        child: TappableAvatar(
          photoUrl: _agentPhoto,
          name: 'Ama Mensah',
          heroTag: 'profile-photo:test',
          child: CircleAvatar(radius: 14),
        ),
      ),
    );

    Future<void> open(WidgetTester tester) async {
      await _pumpApp(tester, host());
      await tester.tap(find.byType(TappableAvatar));
      await _settle(tester);
      expect(_viewer, findsOneWidget);
    }

    testWidgets('close button dismisses the viewer', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(ProfilePhotoViewer.closeButtonKey));
      await _settle(tester);
      expect(_viewer, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('swiping down dismisses the viewer', (tester) async {
      await open(tester);
      await tester.drag(
        find.byKey(ProfilePhotoViewer.zoomAreaKey),
        const Offset(0, 320),
      );
      await _settle(tester);
      expect(_viewer, findsNothing);
    });

    testWidgets('a short swipe snaps the photo back', (tester) async {
      await open(tester);
      await tester.timedDrag(
        find.byKey(ProfilePhotoViewer.zoomAreaKey),
        const Offset(0, 50),
        const Duration(milliseconds: 600),
      );
      await _settle(tester);
      expect(_viewer, findsOneWidget);
    });

    testWidgets('a null photo URL keeps the avatar inert', (tester) async {
      await _pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: TappableAvatar(
              photoUrl: null,
              name: 'Yao',
              heroTag: 'profile-photo:none',
              child: CircleAvatar(radius: 14),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(TappableAvatar)),
        const Size.square(TappableAvatar.minTapTarget),
      );
      await tester.tap(find.byType(TappableAvatar));
      await _settle(tester);
      expect(_viewer, findsNothing);
    });
  });

  test('route extra round-trips and rejects unusable URLs', () {
    const args = ProfilePhotoViewerArgs(
      photoUrl: _agentPhoto,
      name: 'Ama',
      heroTag: 'tag',
      roleLabel: 'Support',
    );
    final back = ProfilePhotoViewerArgs.fromExtra(args.toExtra())!;
    expect(back.photoUrl, _agentPhoto);
    expect(back.roleLabel, 'Support');
    expect(back.heroTag, 'tag');
    expect(ProfilePhotoViewerArgs.fromExtra({'photoUrl': ''}), isNull);
    expect(ProfilePhotoViewerArgs.fromExtra(null), isNull);
    expect(isViewablePhotoUrl('file:///x.jpg'), isFalse);
  });
}
