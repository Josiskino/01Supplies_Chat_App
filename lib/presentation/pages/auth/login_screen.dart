import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/design_tokens.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/providers/auth/auth_status_provider.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../flavors.dart';

/// Écran de connexion — **factice**.
///
/// Le formulaire est complet et le bouton ouvre bien une session, mais rien n'est
/// envoyé au serveur : `signInPlaceholder()` pose un jeton local. Périmètre
/// assumé du socle, pour que la coquille de navigation soit atteignable et
/// testable.
///
/// À l'arrivée de la vraie feature auth : remplacer l'appel par un
/// `LoginUseCase`, valider les champs, et afficher l'échec via `AuthGateStatus`.
/// La structure de l'écran, elle, n'a pas à changer.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = LocalizationHelper.of(context);
    final isLoading =
        ref.watch(authStatusProvider) == AuthGateStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: DesignTokens.pagePaddingLarge,
            child: ConstrainedBox(
              // Un formulaire pleine largeur sur un écran 27" serait illisible.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.loginTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: DesignTokens.spaceS),
                  Text(l10n.loginSubtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: DesignTokens.spaceXxxl),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Iconsax.sms),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceL),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Iconsax.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXxl),

                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => ref
                              .read(authStatusProvider.notifier)
                              .signInPlaceholder(),
                    child: isLoading
                        ? const SizedBox(
                            height: DesignTokens.iconS,
                            width: DesignTokens.iconS,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(l10n.signIn),
                  ),

                  const SizedBox(height: DesignTokens.spaceXxl),
                  Text(
                    FlavorConfig.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
