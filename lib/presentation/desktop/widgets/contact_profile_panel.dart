import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../config/theme/glass_surfaces.dart';
import '../../shared/models/conversation_view_data.dart';
import 'presence_avatar.dart';

/// Colonne 5 — profil du contact actif.
///
/// Fermable : à partir de la maquette, c'est la première colonne sacrifiée quand
/// la fenêtre se réduit, puisqu'elle ne porte que de la consultation.
class ContactProfilePanel extends StatelessWidget {
  const ContactProfilePanel({
    super.key,
    required this.contact,
    this.onClose,
  });

  final ContactProfileData contact;
  final VoidCallback? onClose;

  static const double width = 296;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassPanel(
      width: width,
      color: GlassSurfaces.surface(isDark),
      border: BorderDirectional(
        start: BorderSide(
          color: GlassSurfaces.divider(isDark),
          width: DesignTokens.borderWidthThin,
        ),
      ),
      child: SafeArea(
        left: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceL,
                DesignTokens.spaceM,
                DesignTokens.spaceS,
                DesignTokens.spaceM,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profil',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    iconSize: DesignTokens.iconS,
                    tooltip: 'Fermer',
                    icon: Icon(
                      Iconsax.close_circle,
                      color: DesignTokens.getTextColorWithOpacity(context, 0.5),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceL,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: DesignTokens.spaceM),
                    PresenceAvatar(
                      name: contact.name,
                      avatarUrl: contact.avatarUrl,
                      presence: contact.presence,
                      size: DesignTokens.avatarXxl,
                    ),
                    const SizedBox(height: DesignTokens.spaceM),
                    Text(
                      contact.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 17,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contact.role,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: DesignTokens.getTextColorWithOpacity(
                          context,
                          0.55,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DesignTokens.spaceL),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ProfileAction(
                          icon: Iconsax.message_text,
                          tooltip: 'Envoyer un message',
                        ),
                        _ProfileAction(
                          icon: Iconsax.call,
                          tooltip: 'Appeler',
                        ),
                        _ProfileAction(
                          icon: Iconsax.sms,
                          tooltip: 'Envoyer un e-mail',
                        ),
                        _ProfileAction(
                          icon: Iconsax.more,
                          tooltip: 'Plus d\'actions',
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceXl),

                    _ProfileField(
                      icon: Iconsax.call,
                      label: 'Téléphone',
                      value: contact.phone,
                      isCopyable: true,
                    ),
                    _ProfileField(
                      icon: Iconsax.sms,
                      label: 'E-mail',
                      value: contact.email,
                      isCopyable: true,
                    ),

                    const SizedBox(height: DesignTokens.spaceM),
                    _ProfileRow(
                      icon: Iconsax.user,
                      label: 'Nom complet',
                      value: contact.name,
                    ),
                    _ProfileRow(
                      icon: Iconsax.location,
                      label: 'Localisation',
                      value: contact.location,
                    ),
                    _ProfileRow(
                      icon: Iconsax.calendar_1,
                      label: 'Client depuis',
                      value: contact.memberSince,
                    ),
                    _ProfileRow(
                      icon: Iconsax.global,
                      label: 'Site web',
                      value: contact.website,
                      isLink: true,
                    ),
                    const SizedBox(height: DesignTokens.spaceXl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXs),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: isDark
              ? theme.colorScheme.surface
              : DesignTokens.getSubtleBackground(context, opacity: 0.05),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {},
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceM),
              child: Icon(
                icon,
                size: DesignTokens.iconS,
                color: DesignTokens.getTextColorWithOpacity(context, 0.65),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Champ encadré, avec bouton de copie.
///
/// Un agent recopie un numéro ou un e-mail plusieurs fois par jour : le bouton
/// évite une sélection à la souris dans un texte de 11 px.
class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
    this.isCopyable = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isCopyable;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: DesignTokens.getTextColorWithOpacity(context, 0.45),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: DesignTokens.getTextColorWithOpacity(context, 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceM,
              vertical: DesignTokens.spaceS,
            ),
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusS,
              border: Border.all(
                color: DesignTokens.getBorderColor(isDark, opacity: 0.12),
                width: DesignTokens.borderWidthThin,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value!,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCopyable)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value!));
                      ScaffoldMessenger.maybeOf(context)
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('$label copié'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            margin: const EdgeInsets.all(DesignTokens.spaceL),
                          ),
                        );
                    },
                    child: Icon(
                      Iconsax.copy,
                      size: 13,
                      color: DesignTokens.getTextColorWithOpacity(context, 0.45),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceS),
      child: Row(
        children: [
          Icon(
            icon,
            size: 13,
            color: DesignTokens.getTextColorWithOpacity(context, 0.45),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: DesignTokens.getTextColorWithOpacity(context, 0.55),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value!,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11.5,
                color: isLink
                    ? theme.colorScheme.primary
                    : DesignTokens.getTextColorWithOpacity(context, 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
