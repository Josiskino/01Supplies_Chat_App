# Backend proposal: shared read state for support conversations

Date: 2026-11-13. Status: proposal, not applied. Target: `messaging-service`, base `origin/develop` @ `ed67989f`.
Client: 01 Chat (`supplies_chat_app`), the support app for admins and agents.

## Expected behaviour

A customer message in a support conversation is unread, meaning not yet handled, for **every** back-office user (support, admin, super admin) until **any one of them** reads it or replies after it. Once that happens, the badge disappears for all of them. Reading it on one device must still count after a restart on any device.

## Why the current backend cannot do this

Every line reference below is to `origin/develop:services/messaging-service/src/...`.

1. **Read state is per user, stored in per-recipient receipts.**
   - `services/message.service.ts:57,98`: when a message is sent, a receipt is created for each *active participant*. An unclaimed ticket only has the customer as a participant, so the customer's messages get `receipts: []`.
   - `services/conversation.service.ts:480-495` (`countUnreadMessages`) counts the messages that have no `readAt` receipt **for the viewer**. Another admin's read never changes this count.
2. **Only the assigned agent can record a read.**
   - `controllers/conversation.controller.ts:116` calls `getConversationById(id, userId)` without the role or permissions, so a non-participant gets a 403 (`services/conversation.service.ts:87`) before anything is recorded.
   - `services/message.service.ts:633` → `assertCanAccessConversation` (`:545-559`) requires an active participant. A `support_agent` participant must also be the assignee (`:561-575`).
   - So an admin who reads without claiming cannot persist the read. This is the path the owner hits most often.
3. **The queue shows 0 to non-participants.**
   - `services/conversation.service.ts:372-375`: `unreadCount` is only computed when the viewer is an active participant. Otherwise it is 0. `support.service.ts:802` (the shared queue, `GET /messaging/support`) passes only `viewerId`.
   - The app therefore rebuilds the count from message history (`message.status != "read"`).
4. **The message-level `status` can get stuck below `read`.**
   - `services/message.service.ts:829-859`: `status` becomes `read` only when **every** receipt has a `readAt`.
   - After a takeover, the previous agent is deactivated (`support.service.ts:635-670`), but his receipt with no `readAt` stays on every message he had not read. The message then never reaches `read`, even after the new assignee reads it.
   - Other admins, who derive unread from `status`, keep seeing it as unread forever.

## Proposed change

### Model: `models/message.model.ts`

Add the team read state next to `receipts`. It is only used for support conversations.

```diff
@@ messageSchema (after `receipts`)
     receipts: [
       {
         userId: { type: Schema.Types.ObjectId, ref: "User", required: true },
         deliveredAt: Date,
         readAt: Date,
         _id: false,
       },
     ],
+    // Support conversations only: the back-office team reads as one.
+    // Set the first time any support/admin user reads or answers the message.
+    teamReadAt: { type: Date, default: null },
+    teamReadBy: { type: Schema.Types.ObjectId, ref: "User", default: null },
@@ indexes
 messageSchema.index({ "receipts.userId": 1 });
+messageSchema.index({ conversationId: 1, senderId: 1, teamReadAt: 1 });
```

Add the same two optional fields to `IMessageDocument` and `IMessageResponse` in `interfaces/message.interface.ts`. Expose `teamReadAt` in `formatMessageResponse` (`services/message.service.ts:983-1001`):

```diff
       status: message.status,
+      teamReadAt: message.teamReadAt ?? undefined,
       attachments,
```

### Who counts as "the team"

Add a single helper and reuse it. It matches the permission that already gates non-participant reads (`message.service.ts:349-373`):

```ts
// services/supportTeam.util.ts (new)
import { AccountRole } from "../enums/account-role.enum";

export function isSupportTeamMember(role?: string, permissions: string[] = []): boolean {
  return (
    role === AccountRole.SUPER_ADMIN ||
    role === AccountRole.ADMIN ||
    role === AccountRole.SUPPORT ||
    permissions.includes("*") ||
    permissions.includes("messaging.support_messages.read.any_non_participant")
  );
}
```

### Service: `services/message.service.ts`

```ts
  /**
   * Marks customer messages of a support conversation as handled by the team.
   * Any back-office user allowed to read the ticket may do it; participation
   * and assignment are not required, because reading is not claiming.
   */
  async markSupportMessagesReadByTeam(
    conversationId: string,
    userId: string,
    userRole?: string,
    userPermissions: string[] = [],
    messageIds?: string[]
  ): Promise<{ updated: number; messageIds: string[]; readAt: Date } | null> {
    const conversation = await Conversation.findById(conversationId);
    if (!conversation || conversation.type !== "support") return null;
    if (!isSupportTeamMember(userRole, userPermissions)) return null;
    // Same rule as reading the messages: throws 403/404 when not allowed.
    await this.assertCanReadConversationMessages(conversation, userId, userRole, userPermissions);

    const ticket = await this.findVisibleSupportTicketForConversation(conversation);
    if (!ticket) return null;

    const readAt = new Date();
    const query: any = {
      conversationId: new Types.ObjectId(conversationId),
      senderId: ticket.userId,            // the customer who opened the ticket
      type: { $ne: "system" },
      teamReadAt: null,
    };
    if (messageIds?.length) {
      query._id = { $in: messageIds.map((id) => new Types.ObjectId(id)) };
    }
    const targets = (await Message.find(query).select("_id").lean()).map((m: any) => m._id);
    if (targets.length === 0) return { updated: 0, messageIds: [], readAt };

    await Message.updateMany(
      { _id: { $in: targets }, teamReadAt: null },
      { $set: { teamReadAt: readAt, teamReadBy: new Types.ObjectId(userId) } }
    );

    const ids = targets.map((id: any) => id.toString());
    const payload = {
      conversationId,
      ticketId: ticket._id.toString(),
      userId,
      messageIds: ids,
      readAt: readAt.toISOString(),
    };
    // Viewers of the thread, and every staff inbox (see "Realtime" below).
    PusherService.trigger(`private-conversation-${conversationId}`, "support.read", payload);
    PusherService.trigger("private-support-team", "support.read", payload);
    return { updated: ids.length, messageIds: ids, readAt };
  }

  /** Customer messages no one in the team has read or answered yet. */
  async countSupportTeamUnread(conversationId: any, customerId: any): Promise<number> {
    return Message.countDocuments({
      conversationId,
      senderId: customerId,
      type: { $ne: "system" },
      teamReadAt: null,
    });
  }
```

In `createMessage` (after `Message.create`, around `:86-100`), a reply from the team counts as reading everything before it:

```diff
       const message = await Message.create({ ... });
+      if (conversation.type === "support" && participant.role === "support_agent") {
+        const ticket = await this.findVisibleSupportTicketForConversation(conversation);
+        if (ticket) {
+          await Message.updateMany(
+            {
+              conversationId: conversation._id,
+              senderId: ticket.userId,
+              type: { $ne: "system" },
+              teamReadAt: null,
+              createdAt: { $lte: message.createdAt },
+            },
+            { $set: { teamReadAt: message.createdAt, teamReadBy: message.senderId } }
+          );
+        }
+      }
```

(The sender of a support reply is always the assigned `support_agent`: `assertSupportAgentCanAccessConversation` at `:44` already enforces it.)

### Controller: `controllers/conversation.controller.ts` `markRead` (`:113-130`)

```diff
   markRead = asyncTryCatch(async (req: Request, res: Response) => {
     const userId = req.user!.id;
+    const role = req.user!.role;
+    const permissions = req.user!.permissions ?? [];
     const { messageIds } = req.body ?? {};
-    const conversation = await ConversationService.getConversationById(req.params.id, userId);
+    const conversation = await ConversationService.getConversationById(
+      req.params.id, userId, role, permissions
+    );

     if (!conversation) {
       throw new ApiError(404, "Conversation not found");
     }

-    const result = await MessageService.markMessagesAsRead(req.params.id, userId, messageIds);
+    // Team read first: it is the one that clears every admin's badge.
+    const team = await MessageService.markSupportMessagesReadByTeam(
+      req.params.id, userId, role, permissions, messageIds
+    );
+
+    // Personal receipts (read ticks, the participant's own count) only for
+    // participants allowed to acknowledge. A non-assigned reader is not one.
+    const isParticipant = conversation.participants.some(
+      (p) => p.userId === userId && p.isActive
+    );
+    let result = { updated: 0, messageIds: [] as string[] } as any;
+    if (isParticipant) {
+      try {
+        result = await MessageService.markMessagesAsRead(req.params.id, userId, messageIds);
+      } catch (error) {
+        if (!(team && error instanceof ApiError && error.statusCode === 403)) throw error;
+      }
+    } else if (!team) {
+      throw new ApiError(403, "Not a participant in this conversation");
+    }

     sendResponse(res, {
       statusCode: 200,
       success: true,
       message: `${result.updated} message(s) marked as read`,
-      data: result,
+      data: { ...result, teamRead: team ?? undefined },
     });
   });
```

### Unread counts: `services/conversation.service.ts` and `services/support.service.ts`

Give `formatConversationResponse` (`conversation.service.ts:364-410`) the viewer's team membership. For a support conversation viewed by a team member, the count is the team count, **whether or not the viewer is a participant**:

```diff
   async formatConversationResponse(
     conversation: any,
     viewerId?: string,
     userMap?: UserProfileMap,
-    unreadCount?: number
+    unreadCount?: number,
+    viewerIsSupportTeam = false
   ): Promise<IConversationResponse> {
     const users = userMap ?? await UserProfileService.getUsersByIds(this.collectUserIds(conversation));
     const lastMessageSenderId = conversation.lastMessageData?.senderId?.toString();
-    const resolvedUnreadCount = unreadCount ??
-      (viewerId && this.hasActiveParticipant(conversation, viewerId)
-        ? await this.countUnreadMessages(conversation._id, viewerId)
-        : 0);
+    const supportCustomerId = conversation.type === "support" && viewerIsSupportTeam
+      ? await this.findSupportCustomerId(conversation)
+      : null;
+    const resolvedUnreadCount = supportCustomerId
+      ? await MessageService.countSupportTeamUnread(conversation._id, supportCustomerId)
+      : unreadCount ??
+        (viewerId && this.hasActiveParticipant(conversation, viewerId)
+          ? await this.countUnreadMessages(conversation._id, viewerId)
+          : 0);
```

with

```ts
  private async findSupportCustomerId(conversation: any): Promise<Types.ObjectId | null> {
    const query: any = { deletedAt: null };
    if (conversation.metadata?.supportTicketId) query._id = conversation.metadata.supportTicketId;
    else query.conversationId = conversation._id;
    const ticket = await SupportTicket.findOne(query).select("userId").lean();
    return (ticket as any)?.userId ?? null;
  }
```

Pass the flag from the three entry points:

- `SupportController.listAll` → `SupportService.getSupportTickets(filters, page, limit, viewerId, isSupportTeamMember(req.user!.role, req.user!.permissions ?? []))` → `formatTicketResponse(ticket, viewerId, userMap, viewerIsSupportTeam)` → `ConversationService.formatConversationResponse(ticket.conversation, viewerId, users, undefined, viewerIsSupportTeam)` (`support.service.ts:169-198, 776-806`).
- `ConversationController.list` → `getUserConversations(userId, page, limit, type, viewerIsSupportTeam)` (`conversation.service.ts:112-171`). Pass `undefined` for `unreadCount` on support rows so the team count applies.
- `ConversationController.getById` → `getConversationById(..., role, permissions)`. It already receives them; compute the flag inside.

To avoid N+1 queries on the queue, the team count can be batched for a page with one aggregation:

```ts
Message.aggregate([
  { $match: { conversationId: { $in: ids }, type: { $ne: "system" }, teamReadAt: null } },
  { $lookup: { from: "supporttickets", localField: "conversationId", foreignField: "conversationId", as: "t" } },
  { $match: { $expr: { $eq: ["$senderId", { $first: "$t.userId" }] } } },
  { $group: { _id: "$conversationId", n: { $sum: 1 } } },
]);
```

### Fix the stuck `status` after a takeover

In `deactivateOtherSupportAgentParticipants` (`support.service.ts:635-670`), drop the removed agents' **unread** receipts so the aggregate status can still reach `read`:

Insert this after the `Conversation.updateOne(...)` that deactivates them. `removedAgentIds` holds strings at that point.

```diff
+    const removedObjectIds = removedAgentIds.map((id) => new Types.ObjectId(id));
+    await Message.updateMany(
+      { conversationId: ticket.conversationId, "receipts.userId": { $in: removedObjectIds } },
+      [
+        {
+          $set: {
+            receipts: {
+              $filter: {
+                input: "$receipts",
+                as: "r",
+                cond: {
+                  $or: [
+                    { $not: [{ $in: ["$$r.userId", removedObjectIds] }] },
+                    { $ne: [{ $ifNull: ["$$r.readAt", null] }, null] },
+                  ],
+                },
+              },
+            },
+          },
+        },
+        MessageService.buildAggregateStatusStage(), // make it public (message.service.ts:820)
+      ],
+      { session }
+    );
```

`$pull` alone is not enough here, because `status` has to be recomputed in the same pipeline. Note that `status` only ever moves upward (`read` stays `read`). This change also makes the customer's "read" ticks correct after a reassignment.

### Realtime

`support.read` on `private-conversation-{id}` reaches the people viewing the thread. Staff inboxes need a channel every team member can subscribe to. Two options:

- `private-support-team`, authorised in the Pusher auth endpoint with `isSupportTeamMember`. This is preferred: one trigger.
- Or emit the existing `support.ticket.updated` on `private-user-{staffId}` for each staff user. The app already refreshes its queue on that event (`lib/core/services/message_events_service.dart:189-199`), but this costs one trigger per staff user.

### Migration

The migration is a one-off script, idempotent and safe to re-run. It backfills `teamReadAt` so the first deploy does not light up every badge:

```js
// For each support ticket: the customer's messages are handled if
// (a) any team member has a readAt receipt on them, or
// (b) a non-customer, non-system message was sent after them.
for await (const t of db.supporttickets.find({ deletedAt: null }, { conversationId: 1, userId: 1 })) {
  const lastReply = await db.messages.find(
    { conversationId: t.conversationId, senderId: { $ne: t.userId }, type: { $ne: "system" } }
  ).sort({ createdAt: -1 }).limit(1).next();
  if (lastReply) {
    await db.messages.updateMany(
      { conversationId: t.conversationId, senderId: t.userId, teamReadAt: null,
        createdAt: { $lte: lastReply.createdAt } },
      { $set: { teamReadAt: lastReply.createdAt, teamReadBy: lastReply.senderId } }
    );
  }
  await db.messages.updateMany(
    { conversationId: t.conversationId, senderId: t.userId, teamReadAt: null,
      receipts: { $elemMatch: { readAt: { $ne: null } } } },
    [{ $set: { teamReadAt: { $max: "$receipts.readAt" } } }]
  );
}
```

### OpenAPI

Update `POST /api/messaging/conversations/{id}/read`:

- Support/admin users may call it on any support conversation they can read, without participating or being assigned. The call records the team read.
- The response adds `data.teamRead` (`{ updated, messageIds, readAt }`).
- `unreadCount` on support conversations seen by staff is the team count.
- `IMessageResponse` adds `teamReadAt`.
- Document the `support.read` event.

### Tests to add (backend)

- An admin who is not a participant calls `POST /read`. The response is 200, `teamReadAt` is set, and a second admin's queue `unreadCount` is 0.
- A customer message arrives after a team read. It counts 1 for every admin, assignee included.
- An assignee reply sets `teamReadAt` on earlier customer messages.
- After agent A is reassigned to B and B reads, `status` is `read`, and A's stale receipt is removed.
- The customer calling `POST /read` never sets `teamReadAt`.
- A user without the role or permission still gets a 403.

## Client follow-up once deployed

These go in a Shorebird patch:

- `lib/core/providers/messaging/message_provider.dart` (`markRead`): remove the guard `if (entry?.ticketId != null && entry?.assigneeId != owner) return;`, so a non-assigned reader sends the acknowledgement. Keep the bodyless call.
- `lib/core/providers/messaging/support_provider.dart` (`build`): drop the history scan for non-participant rows (`_queueUnreadCache`, `_unreadScans`, the reply heuristic) and use `conversation.unreadCount` for every support row. Keep the local read watermark only as an optimistic overlay until the next snapshot.
- Subscribe to `support.read` (team channel), and to `private-conversation-{id}` while a thread is open, to clear badges live.
