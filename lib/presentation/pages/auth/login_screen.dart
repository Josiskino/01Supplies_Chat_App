import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../config/theme/app_colors.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/platform/window_glass.dart';
import '../../../core/providers/auth/auth_status_provider.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../flavors.dart';
import 'widgets/auth_glass_card.dart';
import 'widgets/glass_text_field.dart';

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
///
/// C'est le seul écran de l'app qui **ignore le thème** : il est sombre en clair
/// comme en sombre. La photographie de fond ne peut pas s'éclaircir, et un texte
/// noir posé dessus serait illisible. Les couleurs y sont donc littérales plutôt
/// que tirées du `ColorScheme` — exception assumée, confinée à `pages/auth/`.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (ref.read(authStatusProvider) == AuthGateStatus.loading) return;
    ref.read(authStatusProvider.notifier).signInPlaceholder();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = LocalizationHelper.of(context);
    final isLoading = ref.watch(authStatusProvider) == AuthGateStatus.loading;

    // L'écran est sombre quel que soit le thème : sans cette annotation, l'heure
    // et les indicateurs de la barre d'état restent peints en noir sur le fond
    // sombre, donc illisibles. La région rend le réglage local — le reste de
    // l'app garde la barre d'état de son thème.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // Le fond remonte sous la barre d'état : la photographie doit occuper
        // tout l'écran, bords compris.
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Bascule sur la **largeur disponible**, jamais sur la plateforme :
            // une fenêtre macOS réduite à la taille d'un téléphone doit adopter
            // la disposition du téléphone. C'est la règle suivie par la coquille
            // de navigation, et elle vaut aussi ici.
            final isWide =
                Breakpoints.formFactorOf(constraints.maxWidth) ==
                FormFactor.expanded;

            final form = _LoginForm(
              l10n: l10n,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              rememberMe: _rememberMe,
              onToggleRemember: () =>
                  setState(() => _rememberMe = !_rememberMe),
              isLoading: isLoading,
              onSubmit: _submit,
              // Le panneau de marque porte déjà le nom de l'app en grand : le
              // répéter en pied de formulaire ferait doublon.
              showFlavor: !isWide,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  // Deux cadrages de la même composition. `BoxFit.cover` ne sait
                  // que rogner : la version portrait posée sur une fenêtre large
                  // n'en laisserait voir qu'une bande verticale, amputée de ses
                  // deux lobes — et réciproquement.
                  isWide
                      ? AppImages.authBackgroundWide
                      : AppImages.authBackground,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                // Voile sombre : le cadrage varie d'un écran à l'autre, et rien
                // ne garantit qu'une tache claire ne tombe pas derrière la carte.
                const ColoredBox(color: Color(0x33000000)),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceXxl,
                        // Sur macOS, le contenu passe sous une barre de titre
                        // transparente : sans cette marge, la carte pourrait
                        // remonter sous les trois boutons système.
                        vertical:
                            DesignTokens.spaceXxl + WindowGlass.titleBarInset,
                      ),
                      child: ConstrainedBox(
                        // Un formulaire pleine largeur sur un écran 27" serait
                        // illisible ; en deux colonnes, la carte peut respirer
                        // davantage sans que les lignes s'allongent.
                        constraints: BoxConstraints(
                          maxWidth: isWide ? 880 : 400,
                        ),
                        child: AuthGlassCard(
                          child: isWide
                              ? _WideLayout(l10n: l10n, form: form)
                              : form,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Disposition en deux colonnes, à partir de 900 px.
///
/// La marque à gauche, le formulaire à droite. Empiler verticalement comme sur
/// téléphone donnerait une carte étroite perdue au milieu d'une grande fenêtre,
/// et gâcherait la seule chose que le desktop offre en plus : de la largeur.
class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.l10n, required this.form});

  final AppLocalizations l10n;
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: _BrandPanel(l10n: l10n)),
          const SizedBox(width: DesignTokens.spaceXxl),
          // Filet de séparation, à l'image des colonnes de l'espace de travail.
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          const SizedBox(width: DesignTokens.spaceXxxl),
          Expanded(flex: 6, child: Center(child: form)),
        ],
      ),
    );
  }
}

/// Colonne de marque : logo, nom de l'app, baseline et environnement.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(AppImages.appIcon, width: 96, height: 96),
        const SizedBox(height: DesignTokens.spaceL),
        Text(
          FlavorConfig.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          l10n.appTagline,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Contenu de la carte.
///
/// Extrait de l'écran pour que la composition reste lisible : le `Stack` du
/// parent ne porte plus que la superposition fond / verre.
class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.l10n,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.rememberMe,
    required this.onToggleRemember,
    required this.isLoading,
    required this.onSubmit,
    this.showFlavor = true,
  });

  final AppLocalizations l10n;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool rememberMe;
  final VoidCallback onToggleRemember;
  final bool isLoading;
  final VoidCallback onSubmit;

  /// Masqué en disposition large, où le panneau de marque affiche déjà le nom
  /// de l'app et donc l'environnement.
  final bool showFlavor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.loginTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          l10n.loginSubtitle.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.82),
            letterSpacing: 0.6,
            height: 1.3,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceXxl),

        GlassTextField(
          controller: emailController,
          hint: l10n.emailLabel,
          icon: Iconsax.user,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: DesignTokens.spaceM),

        GlassTextField(
          controller: passwordController,
          hint: l10n.passwordLabel,
          icon: obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
          onIconTap: onToggleObscure,
          obscureText: obscurePassword,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: DesignTokens.spaceL),

        _RememberMe(
          label: l10n.rememberMe,
          value: rememberMe,
          onTap: onToggleRemember,
        ),
        const SizedBox(height: DesignTokens.spaceL),

        _SubmitButton(
          label: l10n.signIn.toUpperCase(),
          isLoading: isLoading,
          onPressed: onSubmit,
        ),
        const SizedBox(height: DesignTokens.spaceM),

        Center(
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceM,
                vertical: DesignTokens.spaceXs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.forgotPassword,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (showFlavor) ...[
          const SizedBox(height: DesignTokens.spaceXxl),
          Center(
            child: Text(
              // Pas de lien d'inscription, contrairement à la maquette : les
              // comptes sont créés par l'administration, l'app est réservée à
              // l'équipe. Le flavor prend la place, pour qu'un agent distingue
              // d'un coup d'œil une recette d'une production.
              FlavorConfig.appName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Case à cocher « rester connecté ».
class _RememberMe extends StatelessWidget {
  const _RememberMe({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      // Le libellé fait partie de la cible : viser une case de 20 px au doigt
      // est inutilement exigeant.
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: DesignTokens.durationFast,
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusXs,
              color: value
                  ? AppColors.secondaryColorLight
                  : Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: value
                    ? AppColors.secondaryColorLight
                    : Colors.white.withValues(alpha: 0.45),
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: DesignTokens.spaceM),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton principal, en pilule pleine.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // L'orange de la marque plutôt que le rouge de la maquette : c'est la
          // couleur secondaire des trois apps 01Supplies, et celle de la bulle
          // du logo.
          backgroundColor: AppColors.secondaryColorLight,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.secondaryColorLight.withValues(
            alpha: 0.6,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusPill,
          ),
        ),
        // Le libellé cède la place à l'indicateur en fondu : permuter les deux
        // d'une image à l'autre produit un à-coup au moment précis où
        // l'utilisateur regarde le bouton.
        child: AnimatedSwitcher(
          duration: DesignTokens.durationNormal,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: DesignTokens.iconS,
                  width: DesignTokens.iconS,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }
}
