import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    this.onPickImages,
    this.onTyping,
    this.initialText = '',
    this.onDraftChanged,
    this.restorationId,
  });

  final Future<bool> Function(String)? onSend;
  final ValueChanged<bool>? onTyping;
  final String initialText;
  final ValueChanged<String>? onDraftChanged;
  final String? restorationId;
  final String? placeholder;

  /// Message cité au-dessus du champ, quand une réponse est en cours.
  final ChatReplyPreview? replyTo;
  final VoidCallback? onCancelReply;

  /// Bascule vers la barre d'enregistrement. Sans callback, le micro reste un
  /// repère inerte.
  final VoidCallback? onRecordVoice;

  /// Envoie des images choisies dans la photothèque ou prises à l'instant.
  final ValueChanged<List<String>>? onPickImages;

  @override
  ConsumerState<MessageComposer> createState() => _MessageComposerState();
}

/// Hauteur partagée par le champ et les boutons ronds.
///
/// Sans hauteur commune, un bouton de 34 px à côté d'un champ de 38 px paraît
/// décalé même en alignant les bases : c'est l'écart entre les deux centres
/// optiques que l'œil remarque.
const double _controlHeight = 38;

class _MessageComposerState extends ConsumerState<MessageComposer>
    with RestorationMixin {
  final _controller = TextEditingController();
  late final RestorableString _restoredDraft;
  bool _draftRegistered = false;
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _restoredDraft = RestorableString(widget.initialText);
    // Écouter le contrôleur plutôt que `onChanged` : la bascule micro/envoi doit
    // aussi suivre un collage ou un effacement programmatique.
    _controller.text = widget.initialText;
    _hasText = widget.initialText.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_draftRegistered) _restoredDraft.value = _controller.text;
    final hasText = _controller.text.trim().isNotEmpty;
    widget.onTyping?.call(hasText);
    widget.onDraftChanged?.call(_controller.text);
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restoredDraft, 'draft');
    _draftRegistered = true;
    _controller.removeListener(_onTextChanged);
    _controller.text = _restoredDraft.value;
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
    final restoredText = _controller.text;
    if (restoredText != widget.initialText) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.text == restoredText) {
          widget.onDraftChanged?.call(restoredText);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MessageComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        _controller.text != widget.initialText) {
      // External restoration is already represented in provider state. Do not
      // echo it back into Riverpod while this widget is being rebuilt.
      _controller.removeListener(_onTextChanged);
      _controller.value = TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      );
      _hasText = widget.initialText.trim().isNotEmpty;
      if (_draftRegistered) {
        _restoredDraft.value = widget.initialText;
      }
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.onTyping?.call(false);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _restoredDraft.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Feuille des pièces jointes.
  ///
  /// Passe par `PlatformOverlays.pickOption` plutôt que d'ouvrir directement une
  /// feuille Cupertino : le composer sert les deux plateformes, et c'est au
  /// contrat de décider de la présentation.
  Future<void> _openAttachments(BuildContext context) async {
    final ui = ref.read(platformUiProvider);
    final overlays = ui.overlays;
    // Seules les deux premières entrées sont branchées : proposer « Document »
    // ou « Position » sans les servir ferait chercher une panne là où il n'y a
    // qu'une fonctionnalité absente.
    final choice = await overlays.pickOption(
      context: context,
      title: 'Joindre',
      labels: ui.platform.isMobile
          ? const ['Photothèque', 'Prendre une photo']
          : const ['Choisir des images'],
    );
    if (choice == null || !context.mounted) return;

    final picker = ImagePicker();
    try {
      final files = choice == 0
          // Plusieurs photos en une fois : la galerie de la bulle est faite
          // pour les lots, et forcer un envoi par image la rendrait inutile.
          ? await picker.pickMultiImage(imageQuality: 85)
          : <XFile>[
              ?await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 85,
              ),
            ];

      if (!mounted || files.isEmpty) return;
      widget.onPickImages?.call(files.map((f) => f.path).toList());
    } catch (e) {
      if (!context.mounted) return;
      overlays.notify(
        context: context,
        message: 'Impossible d’accéder aux photos.',
        isError: true,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final send = widget.onSend;
    if (text.isEmpty || _sending || send == null) return;
    final submitted = _controller.text;
    setState(() => _sending = true);
    try {
      final accepted = await send(text);
      if (!mounted) return;
      // A draft edited while this send was pending belongs to the next message.
      if (accepted && _controller.text == submitted) _controller.clear();
      _focusNode.requestFocus();
    } catch (_) {
      // The originating screen reports failures; retain the draft here.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isApple = ref.watch(platformUiProvider).platform.isApple;

    // Aplat opaque, et non un fond transparent : le fil défile juste au-dessus,
    // et un composer translucide laissait le motif de fond traverser le champ.
    // Le thème sombre le masquait presque, le clair le rendait illisible.
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
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
                  // Le bouton reste disponible pendant un téléversement :
                  // l'attente se voit sur la bulle concernée, et rien
                  // n'empêche de préparer l'envoi suivant.
                  _RoundButton(
                    icon: isApple ? CupertinoIcons.plus : Iconsax.add,
                    onTap: () => _openAttachments(context),
                    tooltip: 'Ajouter une pièce jointe',
                  ),
                  const SizedBox(width: DesignTokens.spaceS),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: _controlHeight,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_controlHeight / 2),
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
                                      color:
                                          DesignTokens.getTextColorWithOpacity(
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

    // Bandeau **rectangulaire**, pleine largeur. Un conteneur arrondi force son
    // filet à épouser le rayon, ce qui lui donne des extrémités courbes ; le
    // repère de citation se lit mieux comme un trait franc.
    return Container(
      width: double.infinity,
      // Le voile se détache du composer, pas du motif : celui-ci ne passe plus
      // derrière. Un cran plus marqué qu'à l'origine, où 6 % disparaissaient sur
      // un fond clair.
      color: DesignTokens.getSubtleBackground(context, opacity: 0.09),
      child: Row(
        children: [
          // Filet posé comme un élément de la rangée, et non comme une bordure :
          // c'est ce qui le garde droit sur toute la hauteur.
          Container(width: 3, color: theme.colorScheme.primary),
          const SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: DesignTokens.spaceS,
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
          ),
          GestureDetector(
            onTap: onCancel,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
              ),
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
