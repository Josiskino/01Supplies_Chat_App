import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../config/theme/apple_type.dart';
import '../../../../config/theme/design_tokens.dart';
import '../../../../core/platform/platform_ui_provider.dart';
import '../../../shared/models/conversation_view_data.dart';

/// Zone de saisie d'un message, présentation mobile.
///
/// Reprend la barre de Messages : un bouton rond `+` à gauche, un champ en pilule
/// bordé, et une action à droite qui bascule du micro au bouton d'envoi dès que
/// du texte est saisi.
class MessageComposer extends ConsumerStatefulWidget {
  const MessageComposer({
    super.key,
    this.onSend,
    this.placeholder,
    this.replyTo,
    this.onCancelReply,
    this.onRecordVoice,
  });

  final ValueChanged<String>? onSend;
  final String? placeholder;

  /// Message cité au-dessus du champ, quand une réponse est en cours.
  final ChatReplyPreview? replyTo;
  final VoidCallback? onCancelReply;

  /// Bascule vers la barre d'enregistrement. Sans callback, le micro reste un
  /// repère inerte.
  final VoidCallback? onRecordVoice;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

/// Hauteur partagée par le champ et les boutons ronds.
///
/// Sans hauteur commune, un bouton de 34 px à côté d'un champ de 38 px paraît
/// décalé même en alignant les bases : c'est l'écart entre les deux centres
/// optiques que l'œil remarque.
const double _controlHeight = 38;

class _MessageComposerState extends ConsumerState<MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    // Écouter le contrôleur plutôt que `onChanged` : la bascule micro/envoi doit
    // aussi suivre un collage ou un effacement programmatique.
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend?.call(text);
    _controller.clear();
    // Le focus est conservé : sur mobile, le clavier ne doit pas se refermer
    // entre deux messages.
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isApple = ref.watch(platformUiProvider).platform.isApple;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyTo != null)
            _ReplyBanner(
              reply: widget.replyTo!,
              onCancel: widget.onCancelReply,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.spaceS,
              DesignTokens.spaceS,
              DesignTokens.spaceS,
              DesignTokens.spaceS,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _RoundButton(
                  icon: isApple ? CupertinoIcons.plus : Iconsax.add,
                  onTap: () {},
                  tooltip: 'Ajouter une pièce jointe',
                ),
                const SizedBox(width: DesignTokens.spaceS),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: _controlHeight,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: DesignTokens.borderRadiusPill,
                      border: Border.all(
                        color: DesignTokens.getBorderColor(
                          isDark,
                          opacity: 0.20,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceM,
                      vertical: 2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            minLines: 1,
                            // Le champ grandit avec le texte, jusqu'à cinq lignes.
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            style: theme.textTheme.bodyMedium?.merge(
                              AppleType.body,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: widget.placeholder ?? 'Message',
                              hintStyle: theme.textTheme.bodyMedium
                                  ?.merge(AppleType.body)
                                  .copyWith(
                                    color: DesignTokens.getTextColorWithOpacity(
                                      context,
                                      0.4,
                                    ),
                                  ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        if (!_hasText)
                          GestureDetector(
                            onTap: widget.onRecordVoice,
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                left: 4,
                              ),
                              child: Icon(
                                isApple
                                    ? CupertinoIcons.mic
                                    : Iconsax.microphone_2,
                                size: DesignTokens.iconS,
                                color: DesignTokens.getTextColorWithOpacity(
                                  context,
                                  0.45,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Le bouton d'envoi n'apparaît qu'avec du texte : c'est ce qui évite
                // une action grisée en permanence dans le champ de vision.
                AnimatedSize(
                  duration: DesignTokens.durationFast,
                  curve: DesignTokens.curveDecelerate,
                  child: _hasText
                      ? Padding(
                          padding: const EdgeInsets.only(
                            left: DesignTokens.spaceS,
                          ),
                          child: _RoundButton(
                            icon: isApple
                                ? CupertinoIcons.arrow_up
                                : Iconsax.send_1,
                            onTap: _send,
                            tooltip: 'Envoyer',
                            isPrimary: true,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? theme.colorScheme.primary
            : (isDark
                  ? const Color(0xFF2C2C34)
                  : DesignTokens.getSubtleBackground(context, opacity: 0.06)),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: _controlHeight,
            height: _controlHeight,
            child: Icon(
              icon,
              size: DesignTokens.iconS,
              color: isPrimary
                  ? theme.colorScheme.onPrimary
                  : DesignTokens.getTextColorWithOpacity(context, 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bandeau du message auquel on répond, au-dessus du champ de saisie.
///
/// Reprend la citation affichée dans la bulle, pour que l'utilisateur voie ce
/// qu'il cite avant d'envoyer — et puisse s'en défaire d'un geste.
class _ReplyBanner extends StatelessWidget {
  const _ReplyBanner({required this.reply, this.onCancel});

  final ChatReplyPreview reply;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        DesignTokens.spaceS,
        DesignTokens.spaceS,
        DesignTokens.spaceS,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceM,
        vertical: DesignTokens.spaceS,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.getSubtleBackground(context, opacity: 0.06),
        borderRadius: DesignTokens.borderRadiusM,
        border: BorderDirectional(
          start: BorderSide(color: theme.colorScheme.primary, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
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
                        color: theme.colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    if (reply.isVoice) ...[
                      Icon(
                        CupertinoIcons.mic_fill,
                        size: 11,
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Expanded(
                      child: Text(
                        reply.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.merge(AppleType.caption1)
                            .copyWith(
                              color: DesignTokens.getTextColorWithOpacity(
                                context,
                                0.6,
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: DesignTokens.spaceS),
              child: Icon(
                CupertinoIcons.xmark,
                size: 16,
                color: DesignTokens.getTextColorWithOpacity(context, 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
