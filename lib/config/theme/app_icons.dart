import 'package:flutter/cupertino.dart';
import 'package:iconsax/iconsax.dart';

/// Jeu d'icônes de l'application, nommé par **rôle** et non par dessin.
///
/// ## Pourquoi une table centrale
///
/// Les icônes étaient choisies écran par écran : Cupertino sur iPhone, Iconsax
/// sur l'espace de travail. Or macOS et iOS partagent le langage visuel d'Apple,
/// et un appel manqué dessiné par un combiné raccroché dans la liste des
/// conversations mais par une flèche dans l'historique donne deux vocabulaires
/// pour une même notion. Passer par un rôle rend la divergence impossible : il
/// n'existe qu'un seul `missedCall`.
///
/// ## Deux dessins, une seule décision
///
/// Chaque rôle porte sa variante Apple et sa variante Material. Le choix se fait
/// sur [AppPlatform.isApple] — donc **macOS suit iPhone**, ce qui est le point
/// de la manœuvre, tandis qu'Android garde des icônes qui ne détonnent pas chez
/// lui.
abstract final class AppIcons {
  /// Résout un rôle pour la plateforme courante.
  static IconData of(AppIconPair pair, {required bool isApple}) =>
      isApple ? pair.apple : pair.material;

  // ── Communication ─────────────────────────────────────────────────────────
  static const messages = AppIconPair(
    CupertinoIcons.chat_bubble_2,
    Iconsax.message,
  );
  static const calls = AppIconPair(CupertinoIcons.phone, Iconsax.call);

  /// Appel manqué : un combiné **raccroché**, jamais une flèche.
  ///
  /// La flèche dit d'où venait l'appel, pas qu'il a échoué — c'est la couleur
  /// qui portait seule l'information, et elle ne suffit pas.
  static const missedCall = AppIconPair(
    CupertinoIcons.phone_down_fill,
    Iconsax.call_slash,
  );

  static const incomingCall = AppIconPair(
    CupertinoIcons.arrow_down_left,
    Iconsax.arrow_down_2,
  );
  static const outgoingCall = AppIconPair(
    CupertinoIcons.arrow_up_right,
    Iconsax.arrow_up_3,
  );
  static const videoCall = AppIconPair(
    CupertinoIcons.video_camera,
    Iconsax.video,
  );

  // ── Navigation ────────────────────────────────────────────────────────────
  static const home = AppIconPair(CupertinoIcons.house, Iconsax.home_2);
  static const requests = AppIconPair(
    CupertinoIcons.cube_box,
    Iconsax.task_square,
  );
  static const planning = AppIconPair(
    CupertinoIcons.calendar,
    Iconsax.calendar_1,
  );
  static const supervision = AppIconPair(
    CupertinoIcons.chart_bar_square,
    Iconsax.chart_2,
  );
  static const documents = AppIconPair(CupertinoIcons.folder, Iconsax.folder_2);
  static const contacts = AppIconPair(CupertinoIcons.person_2, Iconsax.people);
  static const settings = AppIconPair(
    CupertinoIcons.settings,
    Iconsax.setting_2,
  );
  static const search = AppIconPair(
    CupertinoIcons.search,
    Iconsax.search_normal_1,
  );

  // ── Actions ───────────────────────────────────────────────────────────────
  static const add = AppIconPair(CupertinoIcons.plus, Iconsax.add);
  static const more = AppIconPair(CupertinoIcons.ellipsis, Iconsax.more);
  static const info = AppIconPair(
    CupertinoIcons.info_circle,
    Iconsax.info_circle,
  );
  static const archive = AppIconPair(
    CupertinoIcons.archivebox,
    Iconsax.archive_1,
  );
  static const delete = AppIconPair(CupertinoIcons.trash, Iconsax.trash);
  static const star = AppIconPair(CupertinoIcons.star_fill, Iconsax.star1);
  static const reply = AppIconPair(
    CupertinoIcons.arrowshape_turn_up_left,
    Iconsax.undo,
  );
  static const signOut = AppIconPair(
    CupertinoIcons.square_arrow_right,
    Iconsax.logout,
  );
  static const theme = AppIconPair(CupertinoIcons.moon, Iconsax.moon);
  static const language = AppIconPair(CupertinoIcons.globe, Iconsax.global);
  static const notifications = AppIconPair(
    CupertinoIcons.bell,
    Iconsax.notification,
  );
}

/// Les deux dessins d'un même rôle.
class AppIconPair {
  const AppIconPair(this.apple, this.material);

  final IconData apple;
  final IconData material;
}
