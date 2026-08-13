import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/platform_page.dart';

/// Recherche transverse : conversations, messages, contacts.
///
/// Écran vide du socle. Sur iOS, sa destination est détachée à droite de la barre,
/// suivant la disposition de l'App Store.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformPage(
      title: 'Rechercher',
      body: EmptyStateWidget(
        icon: Iconsax.search_normal_1,
        title: 'Rechercher',
        message: 'Retrouvez une conversation, un message ou un contact.',
      ),
    );
  }
}
