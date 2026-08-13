import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/locale/locale_provider.dart';
import '../../../config/theme/theme.dart';
import '../../../core/utils/localization_helper.dart';
import '../../widgets/settings/settings_widgets.dart';

/// Réglages d'affichage : thème et langue.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = LocalizationHelper.of(context);
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          SettingsCard(
            children: [
              for (final entry in <(ThemeMode, String, IconData)>[
                (ThemeMode.system, l10n.themeSystem, Iconsax.mobile),
                (ThemeMode.light, l10n.themeLight, Iconsax.sun_1),
                (ThemeMode.dark, l10n.themeDark, Iconsax.moon),
              ])
                SettingsItem(
                  icon: entry.$3,
                  title: entry.$2,
                  trailing: SettingsCheckmark(
                    isSelected: themeMode == entry.$1,
                  ),
                  onTap: () => ref
                      .read(themeProvider.notifier)
                      .setThemeMode(entry.$1),
                ),
            ],
          ),
          SettingsCard(
            children: [
              for (final entry in <(String, String)>[
                ('fr', l10n.languageFrench),
                ('en', l10n.languageEnglish),
              ])
                SettingsItem(
                  icon: Iconsax.global,
                  title: entry.$2,
                  trailing: SettingsCheckmark(
                    isSelected: locale.languageCode == entry.$1,
                  ),
                  onTap: () => ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(entry.$1)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
