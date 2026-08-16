import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/apple_type.dart';
import '../../../config/theme/design_tokens.dart';
import '../../../core/platform/platform_ui_provider.dart';
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
  Timer? _speakerTimer;
  Duration _elapsed = Duration.zero;
  bool _isMuted = false;
  bool _isCameraOn = false;

  /// Participants, tenus en état : ils changent quand quelqu'un prend la parole
  /// ou quitte l'appel.
  late List<CallParticipantData> _participants = List.of(_session.participants);

  /// Mode retrait, armé par un appui long sur un avatar.
  bool _editing = false;

  /// La vignette caméra est-elle au premier plan ?
  bool _selfInFront = false;

  /// Réaction en cours d'envol, affichée brièvement au centre.
  String? _flyingReaction;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    // Rotation de la parole. Le socle n'a pas de flux audio : sans ce
    // simulateur, le halo resterait figé sur le même participant et on ne
    // verrait jamais ce que l'écran est censé montrer.
    _speakerTimer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      setState(() {
        // Seuls les micros ouverts peuvent prendre la parole — un participant
        // coupé qui « parlerait » serait un contresens.
        final eligible = _participants
            .where((p) => !p.isMuted)
            .toList(growable: false);
        if (eligible.isEmpty) return;
        final current = _participants.indexWhere((p) => p.isSpeaking);
        final next = eligible[(current + 1) % eligible.length];
        _participants = [
          for (final p in _participants) _withSpeaking(p, p.id == next.id),
        ];
      });
    });
  }

  /// Copie d'un participant avec un état de parole donné.
  CallParticipantData _withSpeaking(CallParticipantData p, bool speaking) =>
      CallParticipantData(
        id: p.id,
        name: p.name,
        handle: p.handle,
        avatarUrl: p.avatarUrl,
        isMuted: p.isMuted,
        isSpeaking: speaking,
        isSelf: p.isSelf,
      );

  /// Retire un participant, après confirmation.
  Future<void> _confirmRemove(CallParticipantData participant) async {
    final confirmed = await ref
        .read(platformUiProvider)
        .overlays
        .confirm(
          context: context,
          title: 'Retirer ${participant.name} ?',
          message: 'Cette personne quittera l’appel immédiatement.',
          confirmLabel: 'Retirer',
          cancelLabel: 'Annuler',
          isDestructive: true,
        );
    if (confirmed != true || !mounted) return;
    setState(() {
      _participants = _participants
          .where((p) => p.id != participant.id)
          .toList();
      // Plus personne à retirer : on sort du mode plutôt que de laisser des
      // avatars tressauter sans raison.
      if (_participants.length <= 1) _editing = false;
    });
  }

  /// Ouvre la liste des personnes qu'on peut faire entrer.
  Future<void> _invite() async {
    final overlays = ref.read(platformUiProvider).overlays;
    final candidates = CallFixtures.invitables
        .where((name) => !_participants.any((p) => p.name == name))
        .toList();

    if (candidates.isEmpty) {
      overlays.notify(context: context, message: 'Tout le monde est déjà là');
      return;
    }

    final choice = await overlays.pickOption(
      context: context,
      title: 'Ajouter à l’appel',
      labels: candidates,
    );
    if (choice == null || !mounted) return;
    setState(() {
      _participants = [
        ..._participants,
        CallParticipantData(
          id: 'invited-${_participants.length}',
          name: candidates[choice],
        ),
      ];
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speakerTimer?.cancel();
    super.dispose();
  }

  /// Réactions, ouvertes depuis « Plus ».
  ///
  /// Une rangée d'emojis posée en permanence occupait une bande entière au bas
  /// de l'écran, alors qu'on y réagit une fois par appel. Elle est passée
  /// derrière un bouton : la place revient aux visages, qui sont le sujet.
  Future<void> _openReactions(BuildContext context) async {
    const emojis = ['👏', '👍', '🎉', '💯', '🔥', '😮', '😂'];
    final choice = await ref
        .read(platformUiProvider)
        .overlays
        .pickOption(context: context, title: 'Réagir', labels: emojis);
    if (choice == null || !mounted) return;
    _react(emojis[choice]);
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
                      // Toucher le vide autour des avatars quitte le mode
                      // retrait. Un détecteur plein écran posé sous le contenu
                      // ne suffisait pas : la zone de défilement captait le tap
                      // avant lui, et il fallait retirer quelqu'un pour sortir
                      // du mode.
                      child: GestureDetector(
                        onTap: _editing
                            ? () => setState(() => _editing = false)
                            : null,
                        behavior: HitTestBehavior.opaque,
                        child: _ParticipantConstellation(
                          participants: _participants,
                          freeSlots: _session.freeSlots,
                          isEditing: _editing,
                          onInvite: _invite,
                          onRemove: _confirmRemove,
                          // L'appui long arme le retrait, comme la
                          // réorganisation d'icônes sur iOS.
                          onLongPressParticipant: () =>
                              setState(() => _editing = true),
                        ),
                      ),
                    ),
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
                        onMore: () => _openReactions(context),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceL),
                  ],
                ),
              ),
              if (_isCameraOn)
                _CameraPreview(
                  selfInFront: _selfInFront,
                  onSwap: () => setState(() => _selfInFront = !_selfInFront),
                  remoteName: _participants
                      .firstWhere(
                        (p) => !p.isSelf,
                        orElse: () => _participants.first,
                      )
                      .name,
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
    required this.participants,
    required this.freeSlots,
    required this.isEditing,
    required this.onInvite,
    required this.onRemove,
    required this.onLongPressParticipant,
  });

  final List<CallParticipantData> participants;
  final int freeSlots;
  final bool isEditing;
  final VoidCallback onInvite;
  final ValueChanged<CallParticipantData> onRemove;
  final VoidCallback onLongPressParticipant;

  /// Décalage vertical par colonne, en points.
  static const List<double> _columnOffsets = [16, -18, 8];

  @override
  Widget build(BuildContext context) {
    final others = participants.where((p) => !p.isSelf).toList();
    final slots = <Widget>[];

    for (final participant in others) {
      slots.add(
        CallParticipantTile(
          participant: participant,
          isEditing: isEditing,
          onRemove: () => onRemove(participant),
          onLongPress: onLongPressParticipant,
        ),
      );
    }
    for (var i = 0; i < freeSlots; i++) {
      slots.add(CallInviteSlot(onTap: onInvite));
    }

    // L'utilisateur est inséré au centre de la séquence : c'est le repère qui
    // permet de se situer sans lire les noms.
    final middle = (slots.length / 2).floor();
    final self = participants.where((p) => p.isSelf).firstOrNull;
    if (self != null) {
      slots.insert(
        middle,
        CallParticipantTile(
          participant: self,
          size: 96,
          onLongPress: onLongPressParticipant,
        ),
      );
    }

    // Centrée dans la place disponible : ancrée en haut, elle laissait sous
    // elle un vide de la moitié de l'écran. Le défilement reste là pour les
    // appels nombreux, mais ne s'impose plus quand tout tient.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceL,
        vertical: DesignTokens.spaceXl,
      ),
      // Sans cela, `Center` n'aurait aucun effet dans une zone défilante.
      physics: const ClampingScrollPhysics(),
      child: Center(
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

/// Vignette de la caméra, en bas à droite.
///
/// Toucher la vignette **échange les plans**. C'est le geste de FaceTime : le
/// grand cadre montre l'interlocuteur, la vignette montre ce qu'on envoie, et
/// on inverse d'un tap quand on veut se voir.
///
/// ⚠️ Aucune caméra n'est ouverte : les deux plans sont des aplats dégradés
/// portant une initiale. Brancher une vraie prévisualisation revient à
/// remplacer ces deux surfaces.
class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.selfInFront,
    required this.onSwap,
    required this.remoteName,
  });

  final bool selfInFront;
  final VoidCallback onSwap;
  final String remoteName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      right: DesignTokens.spaceL,
      // Au-dessus de la barre de contrôles, jamais dessus : une vignette qui
      // recouvre le bouton de raccroché est un piège.
      bottom: 200,
      child: GestureDetector(
        onTap: onSwap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: DesignTokens.durationNormal,
          curve: Curves.easeOutCubic,
          width: 96,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: DesignTokens.borderRadiusM,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _FakeVideoFeed(
                // La vignette montre celui qui n'est pas au premier plan.
                label: selfInFront ? remoteName : 'Vous',
                accent: selfInFront
                    ? theme.colorScheme.secondary
                    : theme.colorScheme.primary,
              ),
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_2_squarepath,
                    size: 12,
                    color: Colors.white,
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

/// Aplat tenant lieu de flux vidéo.
class _FakeVideoFeed extends StatelessWidget {
  const _FakeVideoFeed({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Center(
        child: Text(
          label.characters.first.toUpperCase(),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
