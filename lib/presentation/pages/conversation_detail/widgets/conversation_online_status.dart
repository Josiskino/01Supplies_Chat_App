import 'package:flutter/material.dart';

bool isConversationPeerPresent({
  required String? peerId,
  required String? currentUserId,
  required bool isSupport,
  required Map<String, Map<String, dynamic>> members,
}) {
  if (peerId != null && peerId.isNotEmpty) return members.containsKey(peerId);
  // In a support thread, another admin must not impersonate the customer.
  return !isSupport && members.keys.any((id) => id != currentUserId);
}

class ConversationOnlineStatus extends StatelessWidget {
  const ConversationOnlineStatus({super.key, required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    if (!online) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: const ValueKey('conversation-online-dot'),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF209B55),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'En ligne',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF209B55)),
        ),
      ],
    );
  }
}
