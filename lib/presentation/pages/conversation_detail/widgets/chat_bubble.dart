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
    this.showStatus = false,
    this.onTapQuote,
    this.contactName = '',
  });

  final ChatMessageData message;

  /// Première bulle d'une série du même auteur : porte le nom.
  final bool isFirstOfGroup;

  /// Dernière bulle d'une série : porte l'avatar et l'ergot.
  final bool isLastOfGroup;

  /// Affiche le libellé d'acheminement sous la bulle.
  ///
  /// Réservé au **dernier** message émis du fil : iOS n'en montre qu'un, et le
  /// répéter transformerait la colonne de droite en litanie de « Distribué ».
  final bool showStatus;

  /// Appelé au tap sur la citation, avec l'identifiant du message d'origine.
  final ValueChanged<String>? onTapQuote;

  final String contactName;

  /// Débordement de la pastille de réaction sous la bulle.
  static const double _reactionOverhang = 12;

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
          Stack(
            clipBehavior: Clip.none,
            alignment: isMine ? Alignment.bottomRight : Alignment.bottomLeft,
            children: [
              Padding(
                // Place réservée sous la bulle pour la moitié basse de la
                // pastille : sans elle, `Clip.none` la ferait bien déborder,
                // mais elle chevaucherait le message suivant.
                padding: EdgeInsets.only(
                  bottom: message.reaction != null ? _reactionOverhang : 0,
                ),
                child: Row(
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
                                  onTap: onTapQuote,
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
              ),
              if (message.reaction != null)
                Positioned(
                  bottom: 0,
                  right: isMine ? DesignTokens.spaceM : null,
                  left: isMine ? null : _avatarGutter + DesignTokens.spaceM,
                  child: _ReactionChip(
                    // La clé porte l'emoji : en changer remonte le widget, et
                    // l'animation rejoue. Sans elle, remplacer 👍 par ❤️
                    // échangerait le glyphe sans que rien ne bouge.
                    key: ValueKey(message.reaction),
                    emoji: message.reaction!,
                    isDark: isDark,
                  ),
                ),
            ],
          ),
          if (isMine && (showStatus || message.status == MessageStatus.failed))
            Padding(
              padding: const EdgeInsets.only(
                right: DesignTokens.spaceXs,
                top: 2,
              ),
              child: _StatusLabel(
                status: message.status,
                timeLabel: message.timeLabel,
              ),
            ),
        ],
      ),
    );
  }
}

/// Libellé d'acheminement, sous le dernier message émis.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status, required this.timeLabel});

  final MessageStatus status;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // L'heure accompagne **tous** les états, pas seulement « Lu ».
    //
    // Sans elle, un message distribué n'avait aucun horodatage nulle part : les
    // bulles n'en portent pas, et le séparateur de jour ne donne que la date.
    // Savoir qu'un message est parti sans savoir quand ne sert à rien dans une
    // messagerie de terrain, où l'écart entre deux échanges est précisément ce
    // qu'on cherche.
    final time = timeLabel.isEmpty ? '' : ' $timeLabel';
    final subtle = DesignTokens.getTextColorWithOpacity(context, 0.45);

    // « Envoyé » n'est pas nommé : c'est l'état par défaut d'un message parti,
    // et l'annoncer ne répond à aucune question. Son heure, elle, reste due.
    final (label, color) = switch (status) {
      MessageStatus.sending => ('Envoi…', subtle),
      MessageStatus.sent => (timeLabel.isEmpty ? null : timeLabel, subtle),
      MessageStatus.delivered => ('Distribué$time', subtle),
      MessageStatus.read => ('Lu$time', subtle),
      MessageStatus.failed => ('Non distribué', theme.colorScheme.error),
    };

    if (label == null) return const SizedBox.shrink();

    return Text(
      label,
      style: theme.textTheme.labelSmall
          ?.merge(AppleType.caption2)
          .copyWith(
            color: color,
            fontWeight: status == MessageStatus.failed
                ? FontWeight.w600
                : FontWeight.w400,
          ),
    );
  }
}

/// Pastille de réaction, posée à cheval sur le bord bas de la bulle.
///
/// Chevaucher plutôt que suivre : détachée sous la bulle, la pastille flottait
/// entre deux messages sans qu'on sache lequel elle qualifiait. C'est la
/// disposition d'iOS et de WhatsApp, et elle répond seule à la question.
class _ReactionChip extends StatefulWidget {
  const _ReactionChip({super.key, required this.emoji, required this.isDark});

  final String emoji;
  final bool isDark;

  @override
  State<_ReactionChip> createState() => _ReactionChipState();
}

class _ReactionChipState extends State<_ReactionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    // Rebond à l'arrivée : la réaction est un accusé de réception, elle doit se
    // voir sans qu'on ait à la chercher. Une apparition en fondu seul passerait
    // inaperçue sur une pastille de cette taille.
    curve: Curves.elasticOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: FadeTransition(
        opacity: _controller.drive(CurveTween(curve: Curves.easeOut)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF2C2C34) : Colors.white,
            borderRadius: DesignTokens.borderRadiusPill,
            // Anneau de la couleur du fond : c'est lui qui détache la pastille
            // de la bulle qu'elle recouvre.
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 2,
            ),
          ),
          child: Text(widget.emoji, style: const TextStyle(fontSize: 13)),
        ),
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
    this.onTap,
  });

  final ChatReplyPreview reply;
  final Color foreground;
  final bool isMine;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // La citation vit *dans* la bulle : ses couleurs dérivent du texte de
    // celle-ci, sinon une réponse émise porterait un bloc clair sur fond
    // violet.
    final tint = foreground.withValues(alpha: 0.12);

    return GestureDetector(
      // Toucher la citation ramène au message d'origine : c'est le geste que
      // tout le monde essaie, et sans lui la citation n'est qu'une image.
      onTap: reply.messageId == null
          ? null
          : () => onTap?.call(reply.messageId!),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: DesignTokens.borderRadiusS,
          border: BorderDirectional(
            start: BorderSide(
              color: foreground.withValues(alpha: 0.5),
              width: 3,
            ),
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
      ),
    );
  }
}
