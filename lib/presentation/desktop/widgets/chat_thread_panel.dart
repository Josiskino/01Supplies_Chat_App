import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/glass_surfaces.dart';
import '../../shared/models/conversation_view_data.dart';
import 'presence_avatar.dart';

/// Colonne 4 — fil de discussion.
///
/// Trois zones : en-tête du contact, historique des messages, zone de saisie.
class ChatThreadPanel extends StatelessWidget {
  const ChatThreadPanel({
    super.key,
    required this.contact,
    required this.entries,
    this.onToggleProfile,
    this.isProfileOpen = false,
  });

  final ContactProfileData contact;
  final List<ChatThreadEntry> entries;
  final VoidCallback? onToggleProfile;
  final bool isProfileOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassPanel(
      color: GlassSurfaces.surface(isDark),
      child: SafeArea(
        left: false,
        right: false,
        child: Column(
          children: [
            _ThreadHeader(
              contact: contact,
              onToggleProfile: onToggleProfile,
              isProfileOpen: isProfileOpen,
            ),
            Expanded(
              child: ListView.builder(
                // Un fil se lit du plus récent vers le haut : l'inverser ancre le
                // défilement en bas sans avoir à piloter un ScrollController.
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceL,
                  vertical: DesignTokens.spaceM,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[entries.length - 1 - index];
                  return switch (entry) {
                    ChatMessageEntry(message: final message) => _MessageRow(
                      message: message,
                      contactName: contact.name,
                    ),
                    ChatSeparatorEntry(separator: final separator) =>
                      _DaySeparator(label: separator.label),
                  };
                },
              ),
            ),
            const _MessageComposer(),
          ],
        ),
      ),
    );
  }
}

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.contact,
    required this.isProfileOpen,
    this.onToggleProfile,
  });

  final ContactProfileData contact;
  final bool isProfileOpen;
  final VoidCallback? onToggleProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceL,
        vertical: DesignTokens.spaceM,
      ),
      decoration: BoxDecoration(
        // L'en-tête est légèrement plus opaque que le fil : sur du verre, une
        // simple ligne ne suffit pas à détacher une zone — il faut une différence
        // de matière.
        color: GlassSurfaces.raised(isDark).withValues(alpha: 0.28),
        border: Border(
          bottom: BorderSide(
            color: GlassSurfaces.innerDivider(isDark),
            width: DesignTokens.borderWidthRegular,
          ),
        ),
      ),
      child: Row(
        children: [
          PresenceAvatar(
            name: contact.name,
            avatarUrl: contact.avatarUrl,
            presence: contact.presence,
            size: DesignTokens.avatarM,
          ),
          const SizedBox(width: DesignTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  contact.role,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: DesignTokens.getTextColorWithOpacity(context, 0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _HeaderAction(icon: Iconsax.call, tooltip: 'Appeler', onTap: () {}),
          _HeaderAction(
            icon: Iconsax.clock,
            tooltip: 'Historique',
            onTap: () {},
          ),
          _HeaderAction(
            icon: Iconsax.search_normal_1,
            tooltip: 'Rechercher dans la conversation',
            onTap: () {},
          ),
          _HeaderAction(
            icon: Iconsax.more,
            tooltip: isProfileOpen ? 'Masquer le profil' : 'Afficher le profil',
            onTap: onToggleProfile ?? () {},
            isActive: isProfileOpen,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: IconButton(
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        iconSize: DesignTokens.iconS,
        icon: Icon(
          icon,
          color: isActive
              ? theme.colorScheme.primary
              : DesignTokens.getTextColorWithOpacity(context, 0.55),
        ),
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceL),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: DesignTokens.getTextColorWithOpacity(context, 0.5),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Iconsax.arrow_down_1,
              size: 12,
              color: DesignTokens.getTextColorWithOpacity(context, 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.contactName});

  final ChatMessageData message;
  final String contactName;

  @override
  Widget build(BuildContext context) {
    final avatar = PresenceAvatar(
      name: message.isMine ? 'Moi' : contactName,
      avatarUrl: message.avatarUrl,
      size: 26,
    );

    // L'horodatage est placé hors de la bulle, du côté opposé : il reste lisible
    // sur un fond coloré et n'oblige pas à réserver de la place dans la bulle.
    final timestamp = message.timeLabel.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceS,
            ),
            child: Text(
              message.timeLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                color: DesignTokens.getTextColorWithOpacity(context, 0.4),
              ),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: message.isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: message.isMine
            ? [
                timestamp,
                Flexible(child: _Bubble(message: message)),
                const SizedBox(width: DesignTokens.spaceS),
                avatar,
              ]
            : [
                avatar,
                const SizedBox(width: DesignTokens.spaceS),
                Flexible(child: _Bubble(message: message)),
                timestamp,
              ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessageData message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMine = message.isMine;

    final background = isMine
        ? theme.colorScheme.primary
        : GlassSurfaces.raised(isDark);
    final foreground = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    // Le coin côté interlocuteur est peu arrondi : c'est ce qui donne à la bulle
    // sa direction, sans recourir à un ergot dessiné.
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(DesignTokens.radiusL),
      topRight: const Radius.circular(DesignTokens.radiusL),
      bottomLeft: Radius.circular(isMine ? DesignTokens.radiusL : 4),
      bottomRight: Radius.circular(isMine ? 4 : DesignTokens.radiusL),
    );

    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS + 2,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: radius,
            border: isMine
                ? null
                : Border.all(
                    color: DesignTokens.getBorderColor(isDark, opacity: 0.08),
                    width: DesignTokens.borderWidthThin,
                  ),
          ),
          child: message.isTyping
              ? const _TypingIndicator()
              : Text(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    height: 1.35,
                    color: foreground,
                  ),
                ),
        ),
        if (message.reaction != null)
          Transform.translate(
            offset: const Offset(0, -6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: GlassSurfaces.raised(isDark),
                borderRadius: DesignTokens.borderRadiusPill,
                border: Border.all(
                  color: DesignTokens.getBorderColor(isDark, opacity: 0.1),
                  width: DesignTokens.borderWidthThin,
                ),
              ),
              child: Text(
                message.reaction!,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

/// Trois points animés, pour signaler une saisie en cours.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
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
      width: 30,
      height: 12,
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
                  width: 6,
                  height: 6,
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

class _MessageComposer extends StatefulWidget {
  const _MessageComposer();

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    // La feature messagerie branchera l'envoi ici.
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceL,
        DesignTokens.spaceS,
        DesignTokens.spaceL,
        DesignTokens.spaceL,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: GlassSurfaces.raised(isDark),
          borderRadius: DesignTokens.borderRadiusM,
          border: Border.all(
            color: GlassSurfaces.border(isDark),
            width: DesignTokens.borderWidthThin,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceM,
                DesignTokens.spaceM,
                DesignTokens.spaceM,
                DesignTokens.spaceS,
              ),
              // Entrée envoie, Maj+Entrée insère un saut de ligne : la convention
              // de toutes les messageries desktop. Sur mobile, le clavier fournit
              // sa propre touche d'envoi.
              child: Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
                },
                child: Actions(
                  actions: {
                    _SendIntent: CallbackAction<_SendIntent>(
                      onInvoke: (_) {
                        _send();
                        return null;
                      },
                    ),
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 1,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.5),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Écrire un message…',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.4,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceS,
                0,
                DesignTokens.spaceS,
                DesignTokens.spaceS,
              ),
              child: Row(
                children: [
                  const _ComposerAction(icon: Iconsax.add, tooltip: 'Ajouter'),
                  const _ComposerAction(
                    icon: Iconsax.emoji_happy,
                    tooltip: 'Emoji',
                  ),
                  const _ComposerAction(
                    icon: Iconsax.paperclip,
                    tooltip: 'Pièce jointe',
                  ),
                  const _ComposerAction(
                    icon: Iconsax.microphone_2,
                    tooltip: 'Message vocal',
                  ),
                  const _ComposerAction(icon: Iconsax.video, tooltip: 'Vidéo'),
                  const Spacer(),
                  _SendButton(onPressed: _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Intention d'envoi, déclenchée par la touche Entrée.
class _SendIntent extends Intent {
  const _SendIntent();
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: IconButton(
        onPressed: () {},
        visualDensity: VisualDensity.compact,
        iconSize: DesignTokens.iconS,
        icon: Icon(
          icon,
          color: DesignTokens.getTextColorWithOpacity(context, 0.5),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primary,
      borderRadius: DesignTokens.borderRadiusS,
      child: InkWell(
        onTap: onPressed,
        borderRadius: DesignTokens.borderRadiusS,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceM,
            vertical: DesignTokens.spaceS,
          ),
          child: Row(
            children: [
              Icon(
                Iconsax.send_1,
                size: DesignTokens.iconXs,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 6),
              Container(
                width: DesignTokens.borderWidthThin,
                height: 12,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 4),
              Icon(
                Iconsax.arrow_down_1,
                size: 12,
                color: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
