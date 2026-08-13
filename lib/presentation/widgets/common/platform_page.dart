import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/platform_ui.dart';
import '../../../core/platform/platform_ui_provider.dart';

/// Écran secondaire rendu selon la plateforme.
///
/// À utiliser à la place d'un `Scaffold` + `AppBar` dans tout écran applicatif :
/// c'est ce qui donne une barre de navigation Cupertino sur iOS et une `AppBar`
/// Material ailleurs, sans que l'écran ait à le savoir.
///
/// Sans ce passage par l'abstraction, un écran garde une barre de titre Material
/// jusque sur iOS — visible immédiatement, et d'autant plus incohérent que la
/// barre d'onglets, elle, est bien native.
class PlatformPage extends ConsumerWidget {
  const PlatformPage({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.backgroundColor,
  });

  final String title;
  final Widget body;
  final List<PlatformAction> actions;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformUi = ref.watch(platformUiProvider);

    return platformUi.shell.buildPage(
      title: title,
      body: body,
      actions: actions,
      backgroundColor: backgroundColor,
    );
  }
}
