import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Résout un chemin d'image vers son [ImageProvider], quelle qu'en soit l'origine.
///
/// Une pièce jointe peut venir de trois endroits : le serveur (URL), l'appareil
/// (fichier choisi mais pas encore envoyé), ou le bundle (les images de
/// démonstration du fil). Sans point de résolution unique, chaque widget qui
/// affiche une image refait le test — et en oublie un : la visionneuse ne
/// reconnaissait que les deux premières formes, si bien qu'un asset lui arrivait
/// comme un `File` inexistant et n'affichait que l'écran d'erreur.
ImageProvider imageProviderFor(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return CachedNetworkImageProvider(path);
  }
  if (path.startsWith('assets/')) return AssetImage(path);
  return FileImage(File(path));
}
