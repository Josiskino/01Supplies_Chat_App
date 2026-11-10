# CLAUDE.md — `supplies_chat_app`

Messagerie interne 01Supplies, pour les **agents logistique** et les
**admins / superviseurs**. Remplace les échanges WhatsApp entre les clients et la
logistique, que Meta bloque régulièrement.

**Quatre plateformes cibles : Android, iOS, Windows, macOS.** Linux et web restent
en template `flutter create` et ne sont pas supportés.

Current implementation: real messaging on mobile and desktop, with a unified
Support/Direct inbox. Support ownership is exclusive; another agent takes over
implicitly on an intentional first send, never merely by opening the thread.

---

## Lancer depuis l'éditeur

Les configurations sont versionnées pour les deux éditeurs :

- **VS Code / Cursor** : `.vscode/launch.json` (5 configurations + variantes
  Windows), `.vscode/tasks.json` (build_runner, analyze, test, l10n).
- **Android Studio / IntelliJ** : `.idea/runConfigurations/*.xml`.

⚠️ `.vscode/settings.json` déclare `dart.flutterSdkPath: .fvm/flutter_sdk`. Sans
ce réglage, l'éditeur analyse avec le Flutter global du poste (3.38.4) alors que
le projet est piné sur 3.44.4 — d'où des erreurs qui n'apparaissent que dans
l'éditeur, ou l'inverse.

⚠️ **Les flavors ne sont pas supportés par Flutter sur Windows ni Linux** :
`--flavor` y fait échouer la commande. Les configurations « (Windows) » s'en
passent ; l'environnement reste correct puisqu'il est déterminé par le point
d'entrée, pas par le drapeau.

Une configuration `FORCE_PLATFORM` permet d'inspecter le rendu iOS depuis macOS
sans simulateur (`--dart-define=FORCE_PLATFORM=ios`). La tab bar UIKit native y
reste indisponible : le plugin n'est pas enregistré hors iOS.

## Commandes

FVM est obligatoire (`.fvmrc` pin **Flutter 3.44.4**). Préfixer toutes les
commandes par `fvm`.

```bash
fvm flutter pub get

# Lancer — l'entry point choisit l'environnement
fvm flutter run --flavor development -t lib/main_development.dart
fvm flutter run --flavor staging     -t lib/main_staging.dart
fvm flutter run --flavor production  -t lib/main_production.dart

# Cibler une plateforme
fvm flutter run -d macos   --flavor development -t lib/main_development.dart
fvm flutter run -d windows --flavor development -t lib/main_development.dart

# Génération de code — obligatoire après toute modification de provider
fvm dart run build_runner build
fvm dart run build_runner watch      # pendant le développement

# Traductions (ARB → Dart)
fvm flutter gen-l10n

# Qualité
fvm flutter analyze                  # doit rester à 0 issue
fvm flutter test

# Icônes de lancement
fvm dart run flutter_launcher_icons

# Écran de démarrage natif (config : flutter_native_splash.yaml)
fvm dart run flutter_native_splash:create
```

---

## Architecture

Clean Architecture **layer-first** (comme `supplies_apk`), pas feature-first.

```
lib/
├── config/         theme, locale, router
├── core/           infrastructure partagée (api, abstractions, utils, providers)
├── data/           models, data sources, implémentations de repository
├── domain/         entities, contrats de repository, use cases
└── presentation/   main (coquille de nav), pages, widgets partagés
```

### Conventions de nommage

Le domaine est un **dossier dans chaque couche**, pas un dossier de feature.
Pour un domaine `conversation` :

| Rôle | Emplacement | Nom |
|---|---|---|
| Contrat de data source | `data/datasources/abstract/conversation/` | `ConversationDataSourceContract` → `ApiResult<Model>` |
| Data source distante | `data/datasources/remote/` (plat) | `ConversationRemoteDataSource` |
| Model | `data/models/conversation/` | `ConversationModel` + `fromJson` + **`toEntity()`** |
| Entity | `domain/entity/conversation/` | `ConversationEntity`, immuable + `copyWith` |
| Contrat de repository | `domain/repository/conversation/` | `abstract interface class ConversationRepository` → `Either<Failure, T>` |
| Implémentation | `data/repository/` (singulier) | `ConversationRepositoryImpl extends BaseRepository` |
| Params | `domain/repository/conversation/params/` | classe dédiée avec `toJson()` |
| Use case | `domain/usecases/conversation/` | `GetConversationsUseCase implements UseCase<R, P>` |
| Providers | `core/providers/conversation/` | sections `// ── Infrastructure ──` / `// ── Use cases ──` / `// ── Notifier ──` |
| Écrans | `presentation/pages/conversation/` | `conversation_screen.dart` + `widgets/` local |

Règles :
- Les mappers vivent **dans le model** (`toEntity()`), pas dans un fichier séparé.
- Un use case sans paramètre déclare quand même une classe
  (`const GetConversationsParams()`), jamais `void`.
- **Pas de `freezed`, `json_serializable` ni `mockito`** : tout est écrit à la
  main dans cette famille de projets.

### State management

Riverpod 3 avec **codegen systématique** (`@riverpod` + `build_runner`). Aucun
provider écrit à la main — c'est un écart assumé par rapport à `supplies_apk`, qui
mélange les deux styles.

Le generator **retire le suffixe `Notifier`** : `class ThemeNotifier` produit
`themeProvider`. Utiliser `@Riverpod(keepAlive: true)` pour tout état global
(session, onglet actif, thème, langue) — en auto-dispose, une écriture d'état
après un `await` peut retomber sur un provider déjà détruit.

### Gestion d'erreur

`fpdart`. Les use cases renvoient `Either<Failure, T>`. Hiérarchie :
`NetworkFailure`, `AuthFailure`, `ForbiddenFailure`, `NotFoundFailure`,
`BusinessFailure`, `UnexpectedFailure`. Le mapping code HTTP → `Failure` est
centralisé dans `BaseRepository`.

Le message serveur brut ne doit **jamais** être affiché : `ApiErrorMessages`
produit un message métier, la chaîne serveur reste dans les journaux.

### Routage

GoRouter, `lib/config/router/app_router.dart`. Routes **plates**, aucun
`ShellRoute` : la coquille est un `IndexedStack` sur `AppUiRoute.main`.

> **RÈGLE IMPÉRATIVE** — navigation **exclusivement** GoRouter (`context.push` /
> `context.go` / `context.pop`), routes déclarées dans `app_router.dart` et
> constantes dans `core/constants/app_ui_route.dart`. **Jamais**
> `Navigator.of(context).push`, `MaterialPageRoute` ni `PageRouteBuilder`. Pour un
> écran superposé : `CustomTransitionPage(opaque: false)` et retour de valeur via
> `context.pop(result)`. Transitions prêtes dans `AppPageTransitions`.

La décision de redirection est dans `core/auth/auth_gate.dart` — fonction **pure**,
donc testée sans widget tree (`test/core/auth/auth_gate_test.dart`).

### Adaptation par plateforme

Deux axes distincts, portés ensemble par `PlatformLayout` :

- **la largeur** décide de la disposition (barre du bas / rail) ;
- **la plateforme** décide du vocabulaire de widgets (Material / Cupertino).

Les croiser est nécessaire : « iOS » et « iPad en paysage » sont deux questions
différentes, et une tab bar d'iPhone étirée sur 1 300 px est un défaut, pas une
adaptation.

```
core/platform/
  app_platform.dart          enum + résolution (surchargeable)
  platform_ui.dart           contrats : Shell / Controls / Overlays / Motion
  impl/material_platform_ui.dart      Android
  impl/cupertino_platform_ui.dart     iOS — seul fichier qui importe le package
  impl/desktop_platform_ui.dart       macOS + Windows, hérite de Material
  platform_ui_provider.dart  @riverpod, surchargeable en test
```

Règles :

- **Aucun écran ne teste la plateforme.** Un `if (Platform.isIOS)` dans un widget
  est le début de la divergence incontrôlée — quatre interfaces dont trois jamais
  testées. Tout passe par `ref.watch(platformUiProvider)`.
- Les écrans utilisent `PlatformPage` plutôt que `Scaffold` + `AppBar`, sinon ils
  gardent une barre de titre Material jusque sur iOS.
- `AppPlatform` dérive de `defaultTargetPlatform`, **jamais** de `dart:io` : c'est
  ce qui rend les trois rendus testables depuis une seule machine.

**Une seule exception, `pages/auth/`.** L'écran de connexion est une vitrine de
marque : photographie de fond, carte de verre, rendu identique sur les quatre
plateformes et **sombre quel que soit le thème**. Ses couleurs sont donc
littérales plutôt que tirées du `ColorScheme`, et ses champs sont des
`GlassTextField` locaux et non `PlatformControls.textField` — un champ Material à
fond opaque trouerait la carte. `AnnotatedRegion<SystemUiOverlayStyle>` y force
une barre d'état claire, faute de quoi l'heure reste peinte en noir sur le fond
sombre. Ces widgets restent confinés à `pages/auth/widgets/` : rien d'autre dans
l'app n'hérite de cette exception.

**`adaptive_platform_ui` est confiné à `impl/cupertino_platform_ui.dart`.** Trois
raisons : il est en `0.1.x` avec une API qui bouge vite, il ne déclare pas de
support macOS/Windows, et son `PlatformInfo` lit `dart:io` en statique. Une
conséquence concrète à connaître : en test sur macOS, sa coquille rend des widgets
**Material** (car `PlatformInfo.isIOS` est faux), lesquels exigent
`MaterialLocalizations` — d'où les delegates fournis même à l'hôte Cupertino dans
les tests.

Son `AdaptiveScaffold` n'a pas de `backgroundColor` : l'implémentation Cupertino
pose la couleur sous le corps, pour que le paramètre du contrat ne soit pas
silencieusement ignoré.

### Navigation adaptative

`presentation/main/` bascule sur la **largeur disponible**, jamais sur la
plateforme (une fenêtre macOS réduite doit se comporter comme un téléphone) :

- `< 600 px` : barre de navigation en bas
- `600–899 px` : rail latéral replié
- `>= 900 px` : rail latéral étendu

Seuils dans `core/responsive/breakpoints.dart`. Les destinations sont déclarées
**une seule fois** dans `presentation/main/nav_destinations.dart` et consommées par
la barre comme par le rail.

---

## Environnement

Trois flavors : `development`, `staging`, `production`. Le flavor est figé par
l'entry point (`lib/main_<flavor>.dart`) — seul mécanisme qui marche sur les
quatre plateformes, Windows n'ayant pas de flavors natifs.

Les `.env` ne sont pas versionnés mais sont déclarés comme assets : un build
échoue si le fichier manque.

```
BASE_URL=https://devbackend.01supplies.com   # stagapi / backend selon l'env
APP_ENV=development
X_API_KEY=
SOCKET_URL=https://realtimedev.01supplies.com
```

| Flavor | applicationId / bundle id | Nom affiché |
|---|---|---|
| development | `com.zeroonesupplies.chat.dev` | 01 Chat Dev |
| staging | `com.zeroonesupplies.chat.stg` | 01 Chat Stg |
| production | `com.zeroonesupplies.chat` | 01 Chat |

Team ID Apple : **`787AZUSBKX`** (le même que les trois autres apps 01Supplies).

---

## Pièges recensés

Chacun a déjà coûté un bug dans cette famille de projets.

1. **`com.apple.security.network.client` (macOS)** — absent du template
   `flutter create`. Sans cette clé dans `DebugProfile.entitlements` **et**
   `Release.entitlements`, le sandbox bloque silencieusement toute requête HTTP et
   tout WebSocket : l'app se comporte comme si le serveur ne répondait jamais.
   Aucune erreur de build ne le signale.

2. **Signature Android** — le template signe la release avec la clé de debug.
   Android rejette alors silencieusement toute mise à jour
   (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) et conserve l'ancien code. La clé de
   distribution doit être identique d'une version à l'autre ; vérifier avec
   `apksigner verify --print-certs <apk>`.

3. **Permission INTERNET** — Flutter ne l'ajoute qu'aux manifests debug et
   profile. Elle est déclarée explicitement dans `AndroidManifest.xml`, sans quoi
   un build release n'a aucun accès réseau.

4. **`copyWith(textTheme:)`** — remplace intégralement le `TextTheme` ; les styles
   non redéfinis perdent leur couleur et sont peints en blanc, donc invisibles en
   thème clair. `TAppTheme` **fusionne** (`merge`). Couvert par
   `test/config/theme/text_theme_colors_test.dart`.

5. **Providers auto-dispose et état global** — voir *State management* ci-dessus.

6. **Splash sans navigation** — le splash doit appeler
   `splashCompletedProvider.complete()`, sinon le redirect ne se relance jamais et
   l'app reste bloquée (défaut constaté sur `supplies_apk_management`).

7. **Taille du logo de splash sur iOS** — le storyboard contraint la vue image
   aux **quatre bords de l'écran**. En `scaleAspectFit`, une image carrée est donc
   ajustée à la largeur entière, et le logo occupe la même part de l'écran que du
   canevas de son PNG. Augmenter la résolution n'y change rien : seule la marge
   transparente autour du logo décide de sa taille perçue. D'où `image_ios`, dont
   le canevas est volontairement plus grand que celui d'Android.

8. **Cache du launch screen (iOS)** — SpringBoard conserve un instantané de
   l'écran de démarrage qui **survit à la désinstallation de l'app**. Après une
   régénération, le simulateur continue d'afficher l'ancien splash, ce qui donne
   l'impression que la modification n'a pas pris. Purger avec
   `xcrun simctl shutdown <UDID>` puis `boot`, app désinstallée.

9. **Splash natif absent sur desktop** — `flutter_native_splash` ne couvre
   qu'Android, iOS et le web. Sur macOS et Windows, c'est `SplashScreen` (Dart)
   qui prend le relais, via `PulsingLogo` → `AppImages.appIcon`. Changer le logo
   suppose donc de mettre à jour **`assets/icon/app_icon.png` aussi**, pas
   seulement les sources de `assets/branding/`.

10. **`adaptive_icon_foreground_inset` sans effet** — dans
    `flutter_launcher_icons` 0.14.4, les valeurs 6, 20 et 30 produisent toutes le
    même contenu de 312 px, qui déborde du masque de 288 px de l'icône
    adaptative. La marge est donc portée par un fichier dédié,
    `assets/branding/adaptive_foreground.png`, dont le contenu occupe 46 % du
    canevas — vérifiable, contrairement à l'option.

11. **`get-task-allow` injecté en release (macOS)** — `flutter build macos` lance
    un build ordinaire, pas une archive : Xcode y ajoute
    `com.apple.security.get-task-allow` pour permettre le débogage. L'App Store
    **rejette** cet entitlement, et ni le build ni la signature ne le signalent —
    seule la validation du paquet échoue. D'où
    `CODE_SIGN_INJECT_BASE_ENTITLEMENTS = NO` sur les configurations `Release-*`.
    Vérifier avec `codesign -d --entitlements - --xml <app>`.

12. **`LSApplicationCategoryType` absent (macOS)** — le template
    `flutter create` ne le fournit pas, et sans lui la validation du paquet
    échoue en 409 alors que tout le reste réussit. Déclaré à
    `public.app-category.business` dans `macos/Runner/Info.plist`.

13. **Icônes Iconsax sur des marques combinantes** — les variantes pleines du
    pack occupent des codepoints arbitraires, dont certains tombent sur des
    marques combinantes hébraïques ou arabes (`setting_25` = U+05BC dagesh,
    `tick_circle5` = U+0610, `tick_square5` = U+0616…). HarfBuzz leur applique
    alors un positionnement de marque : le glyphe sort décalé d'une demi-largeur
    vers la droite, sans que rien ne le signale. Les variantes dont le codepoint
    est une lettre (`message5`, `call5`, `people5`) se rendent normalement.
    Avant d'adopter une icône pleine, vérifier sa catégorie Unicode :
    `python3 -c "import unicodedata; print(unicodedata.category(chr(0x5bc)))"` —
    tout ce qui commence par `M` est à écarter.

14. **`AppBarTheme.titleTextStyle` remplace le style du titre**, il ne le
    complète pas. N'y déclarer qu'une couleur laisse le titre retomber sur la
    taille héritée du `DefaultTextStyle`, soit un titre minuscule sur Android et
    desktop. Taille et graisse doivent être explicites — même piège que le n° 4.

---

## Signature Android

01 Chat a **sa propre clé d'upload**, distincte de celle des apps client et
livreur. Ces trois apps ne partagent pas de clé : qui détient la clé partagée
peut publier une mise à jour sur toutes les apps qu'elle signe, et rien ici ne
justifie ce cumul.

| | |
|---|---|
| Keystore | `android/app/upload-keystore.jks` (non versionné) |
| Alias | `upload` |
| Algorithme | RSA 4096, SHA384withRSA |
| Validité | jusqu'au 13 janvier 2054 |
| SHA-1 | `DC:9C:12:89:D3:17:48:7C:6C:AA:70:50:FD:3F:06:A8:53:43:9C:9D` |
| Mots de passe | `android/key.properties` (non versionné) |

⚠️ **Le `.jks` et le `key.properties` n'existent que sur le poste de
développement.** Les perdre, c'est perdre la possibilité de publier une mise à
jour : la clé d'upload d'une app déjà publiée ne se remplace qu'au prix d'une
demande de réinitialisation auprès de Google. Les sauvegarder hors du poste.

Avec Play App Signing, cette clé sert à **authentifier les envois** ; c'est
Google qui resigne l'app avec sa propre clé avant distribution. Aucun SHA-1
n'est déclaré dans `google-services.json` — l'app n'utilise ni Google Sign-In ni
aucun service qui l'exigerait, donc changer de clé n'a aucun effet côté Firebase.

### Release Shorebird

```bash
shorebird release android --flavor production -t lib/main_production.dart
```

Shorebird **refuse de republier une version déjà publiée** : pour resigner ou
reconstruire, il faut incrémenter `version:` dans `pubspec.yaml`. Un second appel
avec `--artifact apk` construit bien l'APK avant d'échouer à la publication —
c'est ainsi qu'on obtient l'APK d'appoint, mais l'artefact de référence pour les
correctifs OTA reste l'AAB publié.

## Distribution macOS (TestFlight)

Trois différences avec iOS, toutes bloquantes si on les découvre tard :

1. **Deux certificats, pas un.** L'app est signée avec *Apple Distribution*
   (le même que l'IPA), mais le paquet exige un certificat distinct,
   **Mac Installer Distribution**, sans lequel `productbuild` ne peut rien signer.
2. **Un `.pkg`, pas un `.app`.** TestFlight refuse le bundle nu :
   `productbuild --component <app> /Applications --sign "3rd Party Mac Developer
   Installer: …" out.pkg`.
3. **La plateforme macOS doit exister sur la fiche.** Une fiche iOS seule fait
   échouer l'envoi sur « Cannot determine the Apple ID from Bundle ID … and
   platform MAC_OS ». Les deux plateformes cohabitent sur une même fiche à
   condition de partager le bundle ID ; il suffit alors de déclarer une
   `appStoreVersion` de plateforme `MAC_OS`.

```bash
fvm flutter build macos --release --flavor development -t lib/main_development.dart
productbuild --component "build/macos/Build/Products/Release-development/01 Chat Dev.app" \
  /Applications --sign "3rd Party Mac Developer Installer: … (787AZUSBKX)" out.pkg
xcrun altool --validate-app -f out.pkg -t macos --apiKey … --apiIssuer …
xcrun altool --upload-app  -f out.pkg -t macos --apiKey … --apiIssuer …
```

Toujours passer par `--validate-app` avant l'envoi : les deux pièges ci-dessus
(11 et 12) ne se manifestent qu'à cette étape.

---

## Identité visuelle

Sources de génération dans **`assets/branding/`** (hors bundle : le dossier n'est
pas déclaré en assets). Seul `assets/icon/app_icon.png` est embarqué, car
`PulsingLogo` le charge au runtime.

| Fichier | Canevas | Contenu | Destination |
|---|---|---|---|
| `assets/icon/app_icon.png` | 1024 | 71 % | icônes des 4 plateformes + splash Dart desktop |
| `branding/adaptive_foreground.png` | 1024 | 46 % | calque avant-plan Android |
| `branding/splash_logo.png` | 1024 | 88 % | splash Android (densités) |
| `branding/splash_logo_ios.png` | 1640 | 55 % | splash iOS (cf. piège 7) |
| `branding/splash_logo_android12.png` | 960 | 49 % | splash Android 12+ (cercle de 640) |

Chaque proportion répond à une contrainte de plateforme différente : c'est
pourquoi un fichier unique ne convient pas. Après toute modification, relancer
`flutter_launcher_icons` **et** `flutter_native_splash:create`.

`assets/images/demo/` contient cinq photographies servant de pièces jointes à la
maquette du fil. Des assets et non des URL : le rendu doit tenir hors ligne, et
une galerie qui affiche cinq icônes d'erreur ne démontre rien de sa mise en page.
Elles partiront avec les fixtures, quand la couche `data` fournira de vraies
pièces jointes.

⚠️ **`assets/images/` n'est pas récursif** dans `pubspec.yaml` : tout
sous-dossier doit être déclaré à part, faute de quoi les images manquent à
l'exécution sans qu'aucun avertissement de build ne le signale.

---

## Messaging implementation

- Pusher uses an injectable native Dart WebSocket transport, shared by Android,
  iOS, Windows and macOS. The obsolete mobile-only Pusher plugin is removed.
- The realtime coordinator owns session generations, subscription leases,
  reconnect/resume catch-up, conversation presence and expiring typing state.
  Thread presence must not be described as account-wide online availability.
- Inbox entries preserve explicit support linkage/type, embedded latest activity,
  pagination, stable sorting and newer local activity against older snapshots.
- `/messaging/support/{id}/claim` is bodyless and uses the authenticated actor.
  Claim before a deliberate support send when needed; never automatically steal
  ownership again after a concurrent takeover failure. Read permission does not
  imply send or channel subscription permission.
- Generated Riverpod providers own thread data and account-scoped drafts. Widget
  controllers remain local. Failed outgoing attachments retain upload IDs and
  files for retry/discard; only owned temporary recordings may be deleted.
- Audio uses real recorder/player adapters. Private attachment URLs are renewed
  through authenticated `GET /media/{id}` using retained stable media IDs.
- Mobile background data pushes use a top-level Firebase handler and native local
  notifications. Durable session gates and account-bound tap payloads reject
  stale callbacks; unverifiable recipients receive generic notification text.
  Revoke the push session before clearing authentication during explicit logout.
- Desktop shares the functional mobile thread and real inbox state. Do not
  reintroduce fixture conversations, invented contact details or inert actions.
- Physical capture/playback and APNs/FCM delivery require device verification;
  passing widget tests alone does not prove native or OS delivery behavior.
- Audit and verification evidence: `docs/audits/2026-11-10-messaging-audit.md` and
  the implementation plan in `docs/superpowers/plans/`.

---

## Backend partagé

- Base URL : `https://devbackend.01supplies.com`
- Spec OpenAPI : `GET /api/spec.json`
- Docs : `https://devbackend.01supplies.com/api/reference`
- Code source : `/Users/jojo/Projects/Node/supplies-backend-v2`

Point d'entrée messagerie connu : `GET /api/messaging/support/me` (filtre
`orderId` disponible). Les chemins sont regroupés dans
`core/constants/api_endpoints_urls.dart`.
