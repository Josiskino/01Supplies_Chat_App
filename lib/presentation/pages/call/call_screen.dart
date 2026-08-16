import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../shared/fixtures/call_fixtures.dart';
import '../../shared/models/call_view_data.dart';
import 'widgets/call_backdrop.dart';
import 'widgets/call_controls_bar.dart';
import 'widgets/call_participant_tile.dart';

/// Appel de groupe en cours.
///
/// ⚠️ Les participants viennent de [CallFixtures] : la présentation est réelle,
/// le contenu est une maquette. Aucun flux audio ni vidéo n'est établi — cela
/// relève de la feature temps réel, avec son transport et ses permissions.
///
/// L'écran est **sombre en permanence**, comme FaceTime : un appel se tient
/// souvent en mouvement, et un fond clair sur lequel des visages sont incrustés
/// fatigue plus qu'il n'aide. C'est, avec la connexion, la seconde exception à
/// la règle du thème.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, this.title});

  /// Sujet de l'appel — en général le nom de la conversation d'origine.
  final String? title;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  late final CallSessionData _session = CallFixtures.session(widget.title);

  /// Graine du fond, fixée à l'ouverture.
  ///
  /// Tirée une seule fois et gardée en champ : la calculer dans `build` ferait
  /// changer la palette à chaque reconstruction — et il y en a une par seconde,
  /// à cause du minuteur.
  late final int _backdropSeed = DateTime.now().millisecondsSinceEpoch;

  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _isMuted = false;
  bool _isCameraOn = false;

  /// Réaction en cours d'envol, affichée brièvement au centre.
  String? _flyingReaction;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _react(String emoji) {
    setState(() => _flyingReaction = emoji);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _flyingReaction = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF07070A),
        body: CallBackdrop(
          seed: _backdropSeed,
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    _CallHeader(
                      elapsed: _elapsed,
                      isRecording: _session.isRecording,
                      onMinimise: () => context.pop(),
                      onInvite: () {},
                    ),
                    const SizedBox(height: DesignTokens.spaceL),
                    _CallTitle(
                      title: _session.title,
                      subtitle: _session.subtitle,
                    ),
                    Expanded(
                      child: _ParticipantConstellation(
                        session: _session,
                        onInvite: () {},
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceL,
                      ),
                      child: CallReactionsBar(onReact: _react),
                    ),
                    const SizedBox(height: DesignTokens.spaceXl),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceS,
                      ),
                      child: CallControlsBar(
                        isMuted: _isMuted,
                        isCameraOn: _isCameraOn,
                        participantCount: _session.participants.length,
                        onToggleMute: () =>
                            setState(() => _isMuted = !_isMuted),
                        onToggleCamera: () =>
                            setState(() => _isCameraOn = !_isCameraOn),
                        onHangUp: () => context.pop(),
                        onShowParticipants: () {},
                        onMore: () {},
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceL),
                  ],
                ),
              ),
              if (_flyingReaction != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _FlyingReaction(
                      key: ValueKey(_flyingReaction),
                      emoji: _flyingReaction!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre du haut : réduire, minuteur, invitation.
class _CallHeader extends StatelessWidget {
  const _CallHeader({
    required this.elapsed,
    required this.isRecording,
    required this.onMinimise,
    required this.onInvite,
  });

  final Duration elapsed;
  final bool isRecording;
  final VoidCallback onMinimise;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceL,
        vertical: DesignTokens.spaceS,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMinimise,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.chevron_down,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isRecording) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceS),
                ],
                Text(
                  _format(elapsed),
                  style: theme.textTheme.bodyMedium
                      ?.merge(AppleType.headline)
                      .copyWith(
                        color: Colors.white,
                        // Chasse fixe : sans elle, le minuteur tressaute à
                        // chaque changement de chiffre.
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onInvite,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spaceL,
                vertical: DesignTokens.spaceS,
              ),
              decoration: BoxDecoration(
                borderRadius: DesignTokens.borderRadiusPill,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.9),
                  width: 1.5,
                ),
              ),
              child: Text(
                'Inviter',
                style: theme.textTheme.labelMedium
                    ?.merge(AppleType.subheadline)
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }
}

class _CallTitle extends StatelessWidget {
  const _CallTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXxl),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall
                ?.merge(AppleType.title2)
                .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.spaceXs),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.merge(AppleType.subheadline)
                  .copyWith(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Disposition des participants autour de l'utilisateur courant.
///
/// Trois colonnes décalées verticalement plutôt qu'une grille alignée : la
/// grille régulière donne un tableau de contacts, le décalage donne un groupe.
/// L'utilisateur courant occupe le centre, plus grand — c'est le repère qui
/// permet de se situer sans lire les noms.
class _ParticipantConstellation extends StatelessWidget {
  const _ParticipantConstellation({
    required this.session,
    required this.onInvite,
  });

  final CallSessionData session;
  final VoidCallback onInvite;

  /// Décalage vertical par colonne, en points.
  static const List<double> _columnOffsets = [16, -18, 8];

  @override
  Widget build(BuildContext context) {
    final others = session.others;
    // Trois colonnes : les deux premières places de la colonne centrale sont
    // réservées à l'utilisateur, qui doit tomber au milieu.
    final slots = <Widget>[];

    for (var i = 0; i < others.length; i++) {
      slots.add(CallParticipantTile(participant: others[i]));
    }
    for (var i = 0; i < session.freeSlots; i++) {
      slots.add(CallInviteSlot(onTap: onInvite));
    }

    // L'utilisateur est inséré au centre de la séquence.
    final middle = (slots.length / 2).floor();
    final self = session.self;
    if (self != null) {
      slots.insert(middle, CallParticipantTile(participant: self, size: 96));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceL,
        vertical: DesignTokens.spaceXl,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: DesignTokens.spaceXl,
        runSpacing: DesignTokens.spaceL,
        children: [
          for (var i = 0; i < slots.length; i++)
            Transform.translate(
              offset: Offset(0, _columnOffsets[i % _columnOffsets.length]),
              child: slots[i],
            ),
        ],
      ),
    );
  }
}

/// Réaction qui traverse l'écran après un appui sur la barre d'emojis.
///
/// Elle monte en s'effaçant : posée fixe, elle resterait à l'écran comme un
/// élément d'interface, alors que c'est un événement.
class _FlyingReaction extends StatefulWidget {
  const _FlyingReaction({super.key, required this.emoji});

  final String emoji;

  @override
  State<_FlyingReaction> createState() => _FlyingReactionState();
}

class _FlyingReactionState extends State<_FlyingReaction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Align(
          alignment: Alignment(0, 0.5 - t * 1.2),
          child: Opacity(
            // Reste pleine la première moitié, s'efface ensuite : disparaître
            // dès le départ la rendrait illisible.
            opacity: (1 - (t - 0.5).clamp(0.0, 0.5) * 2).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 1 + t * 0.6,
              child: Text(widget.emoji, style: const TextStyle(fontSize: 56)),
            ),
          ),
        );
      },
    );
  }
}
