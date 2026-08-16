import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/conversation_view_data.dart';
import 'voice_note_bubble.dart';

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
                style: theme.textTheme.labelSmall
                    ?.merge(AppleType.caption2)
                    .copyWith(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.replyTo != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: DesignTokens.spaceS,
                          ),
                          child: _QuotedMessage(
                            reply: message.replyTo!,
                            foreground: foreground,
                            isMine: isMine,
                          ),
                        ),
                      if (message.isTyping)
                        const TypingDots()
                      else if (message.isVoice)
                        VoiceNoteBubble(
                          voice: message.voice!,
                          foreground: foreground,
                          // Sur une bulle émise, l'accent de marque se
                          // confondrait avec son fond : la partie lue est donc
                          // peinte dans la couleur du texte.
                          accent: isMine
                              ? foreground
                              : theme.colorScheme.primary,
                        )
                      else
                        Text(
                          message.text,
                          style: theme.textTheme.bodyMedium
                              ?.merge(AppleType.body)
                              .copyWith(color: foreground),
                        ),
                    ],
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          style: theme.textTheme.labelSmall
              ?.merge(AppleType.footnote)
              .copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.getTextColorWithOpacity(context, 0.45),
              ),
        ),
      ),
    );
  }
}

/// Extrait du message cité, en tête d'une bulle de réponse.
///
/// Un filet vertical et un fond légèrement contrasté : c'est la convention
/// partagée par WhatsApp, Messages et Slack, et elle se lit sans légende.
class _QuotedMessage extends StatelessWidget {
  const _QuotedMessage({
    required this.reply,
    required this.foreground,
    required this.isMine,
  });

  final ChatReplyPreview reply;
  final Color foreground;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // La citation vit *dans* la bulle : ses couleurs dérivent du texte de
    // celle-ci, sinon une réponse émise porterait un bloc clair sur fond
    // violet.
    final tint = foreground.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: DesignTokens.borderRadiusS,
        border: BorderDirectional(
          start: BorderSide(color: foreground.withValues(alpha: 0.5), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.author,
            style: theme.textTheme.labelSmall
                ?.merge(AppleType.caption2)
                .copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 1),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reply.isVoice) ...[
                Icon(
                  CupertinoIcons.mic_fill,
                  size: 11,
                  color: foreground.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  reply.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.merge(AppleType.caption1)
                      .copyWith(color: foreground.withValues(alpha: 0.65)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
