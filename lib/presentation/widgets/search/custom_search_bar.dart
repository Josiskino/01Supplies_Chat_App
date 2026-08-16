import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../config/theme/design_tokens.dart';

/// Tag partagé par les barres de recherche qui se relaient d'un écran à
/// l'autre : celle de l'accueil et celle de l'écran de recherche produit.
///
/// Déclaré ici plutôt que dans l'un des deux écrans pour qu'ils ne puissent
/// pas diverger — deux tags différents désactiveraient silencieusement
/// l'animation, sans erreur ni avertissement.
///
/// Un seul Hero portant ce tag doit exister par écran, sans quoi Flutter lève
/// une assertion.
const String kSearchBarHeroTag = 'search-bar';

/// Barre de recherche qui voyage d'un écran à l'autre.
///
/// Réunit les trois précautions qu'exige ce vol, chacune apprise d'un bug :
///
/// 1. le `Material` — dans l'Overlay, la barre quitte l'arbre de son Scaffold
///    et son `TextField` n'a plus la surface qu'il réclame ;
/// 2. le placeholder de l'écran d'**arrivée** pendant le vol, sans quoi le
///    texte change brutalement à l'atterrissage ;
/// 3. surtout : la barre transportée est une barre **neuve**, sans controller
///    ni focusNode. Transporter celle de destination faisait coexister deux
///    `TextField` branchés sur le même `FocusNode` ; le second captait la
///    connexion au clavier, et son démontage en fin de vol la refermait — le
///    clavier surgissait puis repartait de lui-même.
///
/// Les écrans reliés par ce vol doivent tous passer par ce widget : c'est ce
/// qui garantit qu'ils partagent le tag et ces trois précautions.
class SearchBarHero extends StatelessWidget {
  const SearchBarHero({super.key, required this.hintText, required this.child});

  /// Placeholder affiché pendant un vol qui arrive sur cet écran.
  final String hintText;

  /// La barre réelle de l'écran, avec son controller et son focusNode.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: kSearchBarHeroTag,
      flightShuttleBuilder: (_, _, _, _, toHeroContext) {
        final destination = toHeroContext
            .findAncestorWidgetOfExactType<SearchBarHero>();
        return Material(
          type: MaterialType.transparency,
          // Purement décorative : ni saisie, ni focus, ni tap pendant le vol.
          child: AbsorbPointer(
            child: CustomSearchBar(hintText: destination?.hintText ?? hintText),
          ),
        );
      },
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}

/// Modern Search Bar Widget
/// Pill-shaped, flat design with minimal shadows
/// Follows iOS and Material Design 3 principles
class CustomSearchBar extends StatefulWidget {
  const CustomSearchBar({
    super.key,
    this.hintText = 'Search for an address...',
    this.onActionPressed,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.controller,
    this.padding,
    this.readOnly = false,
    this.onTap,
  });
  final String hintText;
  final VoidCallback? onActionPressed;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final EdgeInsetsGeometry? padding;

  /// Champ en lecture seule : le tap déclenche [onTap] (ex. navigation vers un
  /// écran de recherche dédié) sans ouvrir le clavier.
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late final TextEditingController _controller;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    if (mounted) setState(() {}); // refresh clear button visibility
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Modern flat design colors
    final backgroundColor = isDarkMode
        ? const Color(0xFF1E1E1E)
        : Colors.white; // Changed from 0xFFF5F5F5 to White for better contrast

    final borderColor = _isFocused
        ? primaryColor
        : DesignTokens.getBorderColor(isDarkMode, opacity: 0.12);

    return Padding(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: DesignTokens.spaceL),
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: Container(
              height: DesignTokens.heightSearchBar,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: DesignTokens.borderRadiusPill, // Pill shape
                border: Border.all(
                  color: borderColor,
                  width: _isFocused
                      ? DesignTokens.borderWidthFocus
                      : DesignTokens.borderWidthThin,
                ),
                // Minimal shadow for flat design - Always show shadow for better visibility
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  // Search Icon
                  prefixIcon: AnimatedContainer(
                    duration: DesignTokens.durationFast,
                    curve: DesignTokens.curveDefault,
                    child: Icon(
                      Iconsax.search_normal_1,
                      color: _isFocused
                          ? primaryColor
                          : DesignTokens.getTextColorWithOpacity(
                              context,
                              DesignTokens.opacitySubtle,
                            ),
                      size: DesignTokens.iconS,
                    ),
                  ),

                  // Clear Button
                  suffixIcon: _controller.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(DesignTokens.spaceM),
                          child: InkWell(
                            onTap: () {
                              _controller.clear();
                              widget.onChanged?.call('');
                            },
                            borderRadius: DesignTokens.borderRadiusPill,
                            child: Icon(
                              Iconsax.close_circle,
                              size: DesignTokens.iconS,
                              color: DesignTokens.getTextColorWithOpacity(
                                context,
                                DesignTokens.opacitySubtle,
                              ),
                            ),
                          ),
                        )
                      : null,

                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: DesignTokens.getTextColorWithOpacity(
                      context,
                      DesignTokens.opacitySubtle,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceL,
                    vertical: DesignTokens.spaceM,
                  ),
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                textInputAction: widget.onSubmitted != null
                    ? TextInputAction.search
                    : null,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),

          // Filter/Action Button
          if (widget.onActionPressed != null) ...[
            const SizedBox(width: DesignTokens.spaceM),
            Container(
              height: DesignTokens.heightSearchBar,
              width: DesignTokens.heightSearchBar,
              decoration: BoxDecoration(
                // Flat design - no gradient
                color: primaryColor,
                borderRadius: DesignTokens.borderRadiusM,
                // Minimal shadow
                boxShadow: DesignTokens.shadowLow(isDarkMode),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: DesignTokens.borderRadiusM,
                  onTap: widget.onActionPressed,
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: const Center(
                    child: Icon(
                      Iconsax.filter,
                      color: Colors.white,
                      size: DesignTokens.iconS,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
