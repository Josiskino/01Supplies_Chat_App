import 'package:flutter/material.dart';

import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Bulle de message, présentation mobile.
///
/// Suit les conventions de Messages sur iOS :
/// - l'avatar n'accompagne que les messages **reçus**, jamais les siens ;
/// - il n'apparaît que sur la **dernière** bulle d'une série, celle qui porte
///   l'ergot — les précédentes sont simplement décalées ;
/// - le nom de l'auteur coiffe la **première** bulle d'une série ;
/// - il n'y a pas d'horodatage par message, seulement des séparateurs de jour.
///
/// Ce groupement n'est pas cosmétique : sans lui, une rafale de cinq messages
/// affiche cinq avatars et cinq noms, et le fil devient illisible.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.isFirstOfGroup,
    required this.isLastOfGroup,
    this.contactName = '',
  });

  final ChatMessageData message;

  /// Première bulle d'une série du même auteur : porte le nom.
  final bool isFirstOfGroup;

  /// Dernière bulle d'une série : porte l'avatar et l'ergot.
  final bool isLastOfGroup;

  final String contactName;

  static const double _avatarSize = 28;
  static const double _avatarGutter = _avatarSize + DesignTokens.spaceS;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMine = message.isMine;

    final background = isMine
        ? theme.colorScheme.primary
        : (isDark ? const Color(0xFF2C2C34) : const Color(0xFFE9E9EB));
    final foreground = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    // Le coin resserré marque la direction du message, et seulement sur la
    // dernière bulle : c'est ce qui soude visuellement une série.
    const round = Radius.circular(20);
    const tight = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: round,
      topRight: round,
      bottomLeft: !isMine && isLastOfGroup ? tight : round,
      bottomRight: isMine && isLastOfGroup ? tight : round,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: DesignTokens.spaceM,
        right: DesignTokens.spaceM,
        top: isFirstOfGroup ? DesignTokens.spaceM : 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMine && isFirstOfGroup && message.senderName != null)
            Padding(
              padding: const EdgeInsets.only(
                left: _avatarGutter + DesignTokens.spaceM,
                bottom: 3,
              ),
              child: Text(
                message.senderName!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: DesignTokens.getTextColorWithOpacity(context, 0.5),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMine
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine)
                SizedBox(
                  width: _avatarGutter,
                  // La gouttière est réservée même sans avatar : sans elle, les
                  // bulles d'une même série ne seraient pas alignées.
                  child: isLastOfGroup
                      ? PresenceAvatar(
                          name: message.senderName ?? contactName,
                          avatarUrl: message.avatarUrl,
                          size: _avatarSize,
                        )
                      : null,
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    // Une bulle qui traverse tout l'écran empêche de distinguer
                    // l'émetteur d'un coup d'œil.
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceM + 2,
                    vertical: DesignTokens.spaceS + 2,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: radius,
                  ),
                  child: message.isTyping
                      ? const TypingDots()
                      : Text(
                          message.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            height: 1.3,
                            color: foreground,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (message.reaction != null)
            Padding(
              padding: EdgeInsets.only(
                left: isMine ? 0 : _avatarGutter + DesignTokens.spaceS,
                right: isMine ? DesignTokens.spaceS : 0,
                top: 2,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C34) : Colors.white,
                  borderRadius: DesignTokens.borderRadiusPill,
                  border: Border.all(
                    color: DesignTokens.getBorderColor(isDark, opacity: 0.12),
                  ),
                ),
                child: Text(
                  message.reaction!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Trois points animés, pour signaler une saisie en cours.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = DesignTokens.getTextColorWithOpacity(context, 0.45);

    return SizedBox(
      width: 34,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              // Chaque point est décalé d'un tiers de cycle : l'onde se lit de
              // gauche à droite.
              final phase = (_controller.value - index * 0.2) % 1.0;
              final scale = 0.6 + 0.4 * (1 - (phase * 2 - 1).abs());
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Séparateur de jour, centré dans le fil.
class ChatDayDivider extends StatelessWidget {
  const ChatDayDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: DesignTokens.spaceL,
        horizontal: DesignTokens.spaceL,
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DesignTokens.getTextColorWithOpacity(context, 0.45),
          ),
        ),
      ),
    );
  }
}
