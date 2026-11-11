import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Matches the sliding segmented control used by the client app's favorites.
class InboxKindTabs extends StatelessWidget {
  const InboxKindTabs({
    super.key,
    required this.supportSelected,
    required this.supportUnread,
    required this.directUnread,
    required this.onChanged,
  });

  final bool supportSelected;
  final bool supportUnread;
  final bool directUnread;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<bool>(
          groupValue: supportSelected,
          backgroundColor: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHighest
              : const Color(0xFFECECEC),
          thumbColor: theme.colorScheme.primary,
          padding: const EdgeInsets.all(4),
          onValueChanged: (value) {
            if (value != null) onChanged(value);
          },
          children: {
            for (final support in [true, false])
              support: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      support ? 'Support' : 'Direct',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: support == supportSelected
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (support ? supportUnread : directUnread) ...[
                      const SizedBox(width: 6),
                      _UnreadDot(
                        key: ValueKey(
                          support ? 'support-unread' : 'direct-unread',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          },
        ),
      ),
    );
  }
}

class _UnreadDot extends StatefulWidget {
  const _UnreadDot({super.key});
  @override
  State<_UnreadDot> createState() => _UnreadDotState();
}

class _UnreadDotState extends State<_UnreadDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Messages non lus',
    child: FadeTransition(
      opacity: Tween<double>(begin: .35, end: 1).animate(_controller),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          shape: BoxShape.circle,
        ),
      ),
    ),
  );
}
