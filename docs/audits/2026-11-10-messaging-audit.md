# 01Chat messaging audit and proposed design

Status: implementation complete and verified on 2026-11-10. The user selected a unified but explicitly typed inbox and exclusive support ownership with implicit takeover on an intentional send.

## Scope and evidence

Audit the existing mobile and desktop messaging implementation against the live development OpenAPI specification, the latest fetched backend `origin/develop`, and the client application's messaging implementation. Preserve all existing uncommitted work in 01Chat and the backend. Do not use the outdated backend working tree as contract evidence.

Sources:

- https://devbackend.01supplies.com/api/spec.json (snapshot `/tmp/chat-audit-spec.json`).
- Backend `origin/develop`, fetched on 2026-11-10.
- `supplies_apk/lib/presentation/pages/messages/conversation_screen.dart` and its session-aware Pusher provider.
- 01Chat mobile, desktop, data models, providers, services, recorder and player widgets.

Baseline: 137 tests pass; `fvm flutter analyze` reports no issues. These tests include presentation fixtures and simulated playback; passing does not prove functional audio, desktop networking, or complete realtime coverage. Logs: `/tmp/01chat-audit-baseline-tests.log` and `/tmp/01chat-audit-baseline-analyze.log`.

## Findings

| Priority | Finding | Evidence | Required correction |
|---|---|---|---|
| P1 | Joining silently transfers exclusive ownership | `support_remote_datasource.dart:93`, `support_provider.dart:115`; backend assign/claim deactivates the previous support agent | Decide multi-agent participation versus exclusive ownership; use the documented claim permission for self-claim; never claim repeatedly to defeat concurrent agents |
| P1 | Latest support message and date are discarded | `support_ticket_model.dart:50`; queue enrichment depends on participant-only conversation results | Parse the embedded conversation metadata and preserve it independently of membership |
| P1 | First-page-only merging omits or misclassifies conversations | `support_remote_datasource.dart:17,45`, `support_provider.dart:95` | Page both sources, deduplicate by conversation ID, preserve support linkage even when its ticket is outside the loaded page |
| P1 | Shared realtime handlers are removed during thread refresh/disposal | `message_provider.dart:101`, `message_events_service.dart:204`, `pusher_service.dart:201` | Give background subscriptions and visible-thread subscriptions separate ownership; never remove another consumer's handlers |
| P1 | Logout/account replacement races with asynchronous subscriptions | `message_events_service.dart:35,174` | Session generations, captured API clients, serialized disconnect/connect and rejection of stale callbacks |
| P1 | Desktop conversation UI remains a fixture | `desktop_workspace_shell.dart:142,150`, `chat_thread_panel.dart:448` | Use the same real conversation/thread/outgoing providers and actions for desktop and mobile |
| P1 | Current realtime plugin does not support native desktop | `pusher_service.dart:3` | A platform-independent Pusher transport behind an injectable interface, using the same documented channels and auth |
| P1 | No reconnect/resume history catch-up | `pusher_service.dart:55,101` | Expose actual connection state; reconcile inbox and active thread through REST after reconnect/resume |
| P1 | Voice playback is simulated and loses its source | `voice_note_bubble.dart:37`, `conversation_view_data.dart:219` | Preserve local/remote media references and use real audio duration, position and completion events |
| P1 | Failed text sends lose the draft | `message_composer.dart:123` | Clear only the acknowledged draft; preserve text, reply and failed outgoing operation for retry |
| P1 | Recording start/stop/disposal can race | `voice_recorder_bar.dart:65,100,125,130` | Injectable recorder state machine, serialized commands, double-send guard and lifecycle-safe cancellation |
| P1 | macOS microphone configuration is incomplete | macOS Info.plist and entitlements | Add usage description and audio-input sandbox entitlement; verify actual capture on macOS |
| P2 | Delivered/read acknowledgements are incomplete | realtime event list; `conversation_detail_screen.dart:438` | Batch acknowledgements, mark newly visible messages read while app active, monotonic delivery states |
| P2 | Typing, presence, reactions and conversation updates are missing | `message_events_service.dart:82` | Implement documented events and UI state, with identity checks and timer disposal |
| P2 | Subscription membership is inferred incorrectly | `message_events_service.dart:110` | Respect active participation/assignment; reconcile removals and handle revoked authorization |
| P2 | Subscription failures are treated as lasting success | `pusher_service.dart:154`, `message_events_service.dart:182` | Distinguish desired, pending, subscribed and failed states; retry transient failures on recovery |
| P2 | Sender names are hidden or incorrectly substituted | `chat_bubble.dart:107`, `conversation_detail_screen.dart:130` | Show the actual author on every support bubble; never substitute the customer's name for an unknown admin |
| P2 | Assignee identity is inferred from participant order | `support_ticket_model.dart:99` | Consume `assignedAgent` or match `assignedTo` |
| P2 | Attachment failure removes recovery state | `message_provider.dart:198,211` | Keep failed outgoing item and successful upload IDs, allowing explicit retry/discard |
| P2 | Temporary audio is not cleaned and timing is approximate | `voice_recorder_bar.dart` | Track owned temporary files; delete after successful transfer/discard; derive elapsed time after recording starts |
| P2 | Desktop camera option and picker lifecycle are unsafe | `message_composer.dart:94,111` | Capability-aware media selection and origin-conversation/session checks after awaits |

Android microphone permission is supplied by the `record_android` dependency; its absence in the application manifest alone is not a confirmed permission bug. Existing pinned-row sorting fixes are already present and must be preserved.

## Approved product and state design

### One inbox, explicit conversation types

Keep one inbox to avoid fragmenting the agent workflow. Add clearly labeled Support and Direct entries, with optional All/Support/Direct filters. Maintain one entry per conversation ID; never infer direct type simply because a ticket is absent from one page. Use one deterministic ordering: pinned first, then latest actual activity descending, then a stable conversation ID tie-breaker. Merge current activity immediately on sends/events, then reconcile with authoritative paginated REST results. Preserve known newer activity against older snapshots.

Surface partial source failure with retry while retaining available rows. Support queue freshness for nonparticipants must use an authorized staff event or a bounded refresh fallback; private participant-only channels cannot cover the whole queue.

### Implicit support participation

Remove the mandatory manual claim action from the normal reply flow. Opening a readable support thread does not claim it. On first text or attachment send, ensure authorized participation before sending; serialize concurrent outgoing operations and preserve drafts on failure. Display each real author's name above each support message, including the current agent and adjacent bubbles. Render system messages separately.

Critical backend decision: existing `/claim` and `/assign` replace the prior support agent. The client cannot truthfully provide concurrent multi-agent replies using this contract alone.

Options:

1. **Recommended for the requested multi-admin workflow:** add backend participant join semantics distinct from the operational assignee. Provide an atomic join-and-send operation with authenticated author identity, permission checks, deduplication and an explicit participant event. Keep an assignee if needed for responsibility, but do not use it to evict authorized collaborators.
2. **Backend-compatible smaller change:** self-claim automatically before the first send; one agent remains authorized. If another agent takes over, show the state and preserve the draft. Do not steal ownership again in an automatic retry loop. Claim plus send is two requests and cannot be atomic from the client.

The user selected option 2: exclusive ownership, with implicit self-claim on a deliberate send. No backend changes are required or performed. Do not claim on opening a thread and do not automatically reclaim after a failed send.

### Realtime contract

Handle `message.new`, `message.updated`, `message.deleted`, `message.delivered`, `message.read`, `message.reaction`, `conversation.created`, `conversation.updated` and `support.ticket.updated` on their documented channels. Normalize documented payload envelopes once. Reactions must persist through the API; local decoration alone is insufficient.

Use `client-typing` with authenticated user identity: throttle true events to at most every 3 seconds, send false after 4 seconds idle, expire remote indicators after 6 seconds. Remove state on conversation/session change. `presence-conversation-{id}` describes participants with that thread open; do not claim it proves account-wide online presence. A global online state requires its own authoritative contract.

Use one session-owned realtime coordinator with injectable transport, explicit connection states, handler ownership, membership reconciliation and reconnect/resume REST catch-up. Share domain state across mobile and desktop, while adapting only the layout.

### Riverpod and hooks

Use generated Riverpod providers for inbox/thread data, session lifecycle, per-conversation drafts, reply targets, outgoing operations, pagination and delivery state. Guard asynchronous completions by session and conversation identity. Retain pending and failed sends during REST reconciliation; deduplicate echoes by stable IDs.

Use StatefulWidget/ConsumerStatefulWidget or hooks for widget-local controllers, focus and animations. Hooks may simplify lifecycle code but are not a replacement for state ownership, cancellation or concurrency control. Avoid a blanket widget rewrite.

### Audio and attachment behavior

Record through an injectable service with starting/recording/stopping/error states. Prevent double stop/send, handle permission denial and disposal, preserve retryable recordings, and clean owned temporary files safely. Playback must use a real local/remote source, expose duration and position, support completion and retry, and coordinate concurrent playback. Handle signed media expiration through the documented refresh path.

## Verification plan

- Models and inbox: embedded latest message, pagination beyond 50, mixed-source deduplication, equal-date sorting, pinned rows, out-of-order snapshots and partial endpoint failures.
- Support: approved ownership policy, simultaneous admins, join/claim failure, claim-success/send-failure, takeover between operations, missing author profile and every-bubble author labels.
- Realtime: duplicate events, read/delivered monotonicity, reactions, typing expiry, presence semantics, subscription rejection/recovery, reconnect catch-up, background-thread lease retention and stale callbacks after account change/logout.
- Outgoing: failed draft preservation, partial uploads, retry without duplicate upload/message, retained reply targets and navigation during asynchronous operations.
- Audio: real source adapter, playback completion/error, permission/start/stop/dispose races, double send, short recording and file cleanup.
- UI: shared functional mobile/desktop views and no fixture-only production conversation data.
- Integration smoke: Android/iOS/macOS/Windows capture and playback, background/resume, network loss/recovery, and client/vendor/driver support interoperability. Report unavailable device/platform checks explicitly; widget tests cannot prove native codec behavior.

## Boundaries

No production messaging actions, store deployments, existing-work resets, or backend working-tree edits during audit. The backend has existing staged delivery changes unrelated to this task. Any implementation must isolate the approved messaging work and preserve those changes. Backend writes are also outside this workspace's writable roots and require the environment's permission mechanism.


## Implementation and validation results

Branch: `fix/01chat-messaging-reliability`.

- One chronological inbox distinguishes Support and Direct. New activity moves known threads immediately; pagination and reconciliation preserve their type and prevent stale previews from taking precedence.
- Support remains exclusive. The first deliberate text or attachment send takes ownership through the authenticated bodyless claim endpoint when needed. Reading alone does not claim a ticket, and a rejected send does not trigger a repeated takeover. Each support bubble shows its actual author; system history is neutral.
- Mobile and desktop share real inbox and thread providers. Typing, thread presence, receipts, reactions, reconnect catch-up, message edits/deletes, and foreground banner routing use the documented realtime/REST paths.
- Drafts are scoped to the conversation and account. Failed attachments retain retry/discard actions and already uploaded media IDs. Voice notes record and play through native adapters; stable media IDs allow targeted renewal of private URLs.
- Mobile push registration and tap routing are scoped to the session. Background data messages can produce local notifications; generic content protects unverified recipients. Push tokens are masked in logs.

| Check | Result | Local log |
|---|---|---|
| Riverpod generation | Passed | `/tmp/01chat-validated-codegen.log` |
| Complete Flutter suite | 210 passed, 0 failed (137 baseline) | `/tmp/01chat-validated-tests.log` |
| Flutter analysis | No issues | `/tmp/01chat-validated-analyze.log` |
| macOS development debug build | Passed | `/tmp/01chat-validated-macos.log` |
| Android development debug build | Passed | `/tmp/01chat-validated-android.log` |
| iOS development simulator build | Passed | `/tmp/01chat-validated-ios.log` |

Physical microphone and push delivery, live multi-role interoperability and the Windows native build were not exercised on this Mac. The tests cover the corresponding app state, contracts and adapters with controlled inputs. No store submission or backend change was made.
