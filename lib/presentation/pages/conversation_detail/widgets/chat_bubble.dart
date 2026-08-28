import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../desktop/widgets/presence_avatar.dart';
import '../../../shared/models/conversation_view_data.dart';
import 'photo_stack.dart';
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
    this.onOpenGallery,
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

  /// Appelé au tap sur un lot de photos, avec toutes les images du message.
  final ValueChanged<List<String>>? onOpenGallery;

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

    // Un message qui n'est **que** des photos n'a pas de bulle : le fond coloré
    // s'y réduirait à un liseré autour de l'aperçu.
    final hasBubble =
        !message.hasAttachments ||
        message.text.isNotEmpty ||
        message.isVoice ||
        message.isTyping ||
        message.replyTo != null;

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
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          // Une bulle qui traverse tout l'écran empêche de distinguer
                          // l'émetteur d'un coup d'œil.
                          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Les photos sont posées **hors** de la bulle, comme
                            // dans Messages : un lot d'images enfermé dans un
                            // fond coloré paraîtrait encadré, et le fond
                            // n'apporte rien à un contenu qui porte déjà le sien.
                            if (message.hasAttachments)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: hasBubble ? DesignTokens.spaceS : 0,
                                ),
                                child: PhotoStack(
                                  images: message.attachments,
                                  // Le voile de chargement vit sur la pile
                                  // elle-même, pas sur le composer.
                                  isUploading:
                                      message.status == MessageStatus.sending,
                                  // Sans bulle, l'heure n'a aucune ligne où se
                                  // glisser : la pile la pose sur la photo, à la
                                  // place que sa géométrie lui laisse.
                                  timeLabel: hasBubble
                                      ? null
                                      : message.timeLabel,
                                  onTap: () =>
                                      onOpenGallery?.call(message.attachments),
                                ),
                              ),
                            if (hasBubble)
                              Container(
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
                                      _TextWithTime(
                                        text: message.text,
                                        timeLabel: message.timeLabel,
                                        foreground: foreground,
                                      ),
                                    // Les bulles sans texte portent leur heure en
                                    // dessous : il n'y a pas de ligne dans laquelle la
                                    // glisser.
                                    if (message.isVoice &&
                                        message.timeLabel.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: _BubbleTime(
                                            label: message.timeLabel,
                                            foreground: foreground,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
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

    // L'heure n'est plus reprise ici : chaque bulle porte la sienne. La
    // répéter juste en dessous donnait deux fois la même information à deux
    // pixels d'écart.
    final subtle = DesignTokens.getTextColorWithOpacity(context, 0.45);

    // « Envoyé » n'est pas nommé : c'est l'état par défaut d'un message parti,
    // et l'annoncer ne répond à aucune question que le lecteur se pose.
    final (label, color) = switch (status) {
      MessageStatus.sending => ('Envoi…', subtle),
      MessageStatus.sent => (null, subtle),
      MessageStatus.delivered => ('Distribué', subtle),
      MessageStatus.read => ('Lu', subtle),
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

/// Texte d'un message suivi de son heure, à la manière de WhatsApp.
///
/// L'heure se glisse **dans** la bulle, en bout de dernière ligne quand la place
/// le permet, sinon sur une ligne à elle. C'est obtenu en réservant un blanc à
/// la fin du texte, puis en y posant l'heure : sans cette réserve, l'heure
/// recouvrirait les derniers mots.
///
/// Un simple `Row` ne conviendrait pas — il mettrait l'heure à côté du bloc de
/// texte entier, et une bulle de trois lignes se retrouverait avec son heure
/// centrée verticalement à droite, loin de la fin du message.
class _TextWithTime extends StatelessWidget {
  const _TextWithTime({
    required this.text,
    required this.timeLabel,
    required this.foreground,
  });

  final String text;
  final String timeLabel;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (timeLabel.isEmpty) {
      return Text(
        text,
        style: theme.textTheme.bodyMedium
            ?.merge(AppleType.body)
            .copyWith(color: foreground),
      );
    }

    return Stack(
      children: [
        Text.rich(
          TextSpan(
            text: text,
            children: [
              // Blanc réservé à l'heure. `WidgetSpan` plutôt qu'une suite
              // d'espaces : la largeur est exacte quelle que soit la police, là
              // où des espaces varient d'une plateforme à l'autre.
              WidgetSpan(
                child: SizedBox(width: _reservedWidth(context), height: 1),
              ),
            ],
          ),
          style: theme.textTheme.bodyMedium
              ?.merge(AppleType.body)
              .copyWith(color: foreground),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _BubbleTime(label: timeLabel, foreground: foreground),
        ),
      ],
    );
  }

  /// Largeur du blanc, mesurée sur l'heure elle-même.
  double _reservedWidth(BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(
        text: timeLabel,
        style: AppleType.caption2.copyWith(fontWeight: FontWeight.w400),
      ),
      textDirection: Directionality.of(context),
    )..layout();
    // Quelques points de marge : collée au dernier mot, l'heure se lirait comme
    // la suite du message.
    return painter.width + 10;
  }
}

/// Horodatage discret, dans la bulle.
class _BubbleTime extends StatelessWidget {
  const _BubbleTime({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall
          ?.merge(AppleType.caption2)
          .copyWith(color: foreground.withValues(alpha: 0.6)),
    );
  }
}
