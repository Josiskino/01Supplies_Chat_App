# 01Chat Messaging Reliability Implementation Plan

> **For agentic workers:** Use subagent-driven-development for independent implementation units. Preserve existing work and verify each change with focused regression tests.

**Goal:** Make the unified Support/Direct inbox and messaging functional across supported layouts, including implicit exclusive support claim, realtime state and real audio.

**Architecture:** Generated Riverpod providers own inbox, threads and outgoing operations. A session-owned injectable realtime coordinator handles Pusher subscriptions and recovery; local controllers remain widget-scoped. Support ownership stays exclusive: a deliberate send from a different agent claims once, awaits success, then sends; a concurrent takeover produces a recoverable failure without automatically stealing ownership again.

**Tech Stack:** Flutter 3.44.4, Riverpod 3/codegen, Pusher protocol, REST, record and audioplayers.

## Approved decisions

- User approved the audit corrections on 2026-11-10.
- Keep one inbox, identify Support versus Direct explicitly.
- One assigned support agent at a time. Another agent takes over implicitly on their first send, not on opening/reading a thread.
- Show each actual support author above every message bubble. Do not modify the backend's exclusive ownership contract.
- Preserve local changes present before this task; snapshot `/tmp/01chat-before-implementation`.

## Task 1: Inbox and support data contract

Files: support remote datasource, support/conversation models and entities, support provider, corresponding data/provider tests.

- [x] Write regressions for embedded latest support activity, authoritative assignee, more than 50 records, deduplication and support type outside a queue page.
- [x] Run focused tests and observe the expected failures.
- [x] Map complete metadata, retrieve remaining pages, use explicit type/linkage, apply deterministic ordering and expose partial-source failures.
- [x] Change self-join to a bodyless `/claim`, preserving compatibility at the repository boundary.
- [x] Verify focused tests and report API signatures to the thread coordinator.

## Task 2: Realtime transport and session coordinator

Files: Pusher transport/service, message events coordinator, realtime providers, transport/coordinator tests.

- [x] Write regressions for handler ownership, concurrent subscribe, rejected authorization, logout during connect and account replacement.
- [x] Verify failures, then implement injectable transport with real connection state and platform support.
- [x] Handle documented message/conversation/support events, typing throttle/expiry and thread presence.
- [x] Reconcile permitted channel additions/removals; expose reconnect/resume catch-up without rebuilding subscriptions on each message.
- [x] Verify focused tests and document the interface consumed by thread/UI providers.

## Task 3: Audio, attachments and composer

Files: voice recorder/player widgets and injectable audio services, message composer, voice view data, macOS microphone configuration, focused tests.

- [x] Write regressions proving the real source reaches playback, failed text keeps its draft, recorder operations serialize and disposal is safe.
- [x] Verify failures and implement real duration/position/completion/error playback and capability-aware recording/picking.
- [x] Preserve local/remote media sources and cleanup only owned temporary files on explicit discard or acknowledged transfer.
- [x] Keep failed outgoing attachment paths recoverable; coordinate integration with thread outgoing state.
- [x] Verify focused tests. Native device capture requires separate smoke checks and must not be claimed from widget tests.

## Task 4: Thread state, implicit claim and receipt integration

Files: message provider/domain use cases/remote datasource, conversation detail screen, bubble, thread tests.

- [x] Reproduce failed-send draft loss, duplicate echo, refresh during send, repeated read acknowledgements and missing per-bubble author.
- [x] Ensure support claim once per deliberate send operation before upload/send, await it, then send. Preserve reply/text/files on every failure.
- [x] Serialize outgoing operations and reconcile server snapshots with pending/failed messages by stable IDs.
- [x] Add paginated history, delivered/read acknowledgements and server reactions; prevent stale session/conversation completions.
- [x] Wire typing/presence through coordinator; render system messages neutrally and actual authors accurately.
- [x] Verify focused tests including concurrent takeover failure without automatic reclaim.

## Task 5: Functional desktop and inbox UI

Files: desktop workspace/thread/list panels, shared models and conversation rows, UI tests.

- [x] Replace production fixtures with the same inbox/thread/actions used on mobile, preserving the desktop layout.
- [x] Show Support/Direct identification and deterministic ordering; maintain selection across updates.
- [x] Wire text/image/audio/reply/read states consistently and hide unsupported actions rather than displaying inert controls.
- [x] Verify desktop widget tests and compile the available native target.

## Task 6: Review and verification

- [x] Run code generation where annotated providers change: `fvm dart run build_runner build`.
- [x] Run focused regressions after each lot; run `fvm flutter test` once integrated.
- [x] Run `fvm flutter analyze`, `git diff --check`, and review scoped source diffs against the initial dirty snapshot.
- [x] Review all audit findings for implementation or an explicit remaining external limitation.
- [x] Record device/platform checks actually performed; do not claim Windows or physical audio tests without an available device.
- [x] No store release or production customer messaging is authorized by this implementation task.


Verification completed: 210 passing tests, clean analysis, and successful macOS, Android and iOS simulator development builds. See `docs/audits/2026-11-10-messaging-audit.md` for evidence and the physical-device/Windows limits.
