# CLAUDE.md — `supplies_chat_app`

Messagerie interne 01Supplies, pour les **agents logistique** et les
**admins / superviseurs**. Remplace les échanges WhatsApp entre les clients et la
logistique, que Meta bloque régulièrement.

**Quatre plateformes cibles : Android, iOS, Windows, macOS.** Linux et web restent
en template `flutter create` et ne sont pas supportés.

État actuel : **socle uniquement**. L'architecture, le thème, le routage, la
coquille de navigation et les widgets partagés sont en place ; la feature
messagerie reste à écrire.

---

## Lancer depuis l'éditeur

Les configurations sont versionnées pour les deux éditeurs :

- **VS Code / Cursor** : `.vscode/launch.json` (5 configurations + variantes
  Windows), `.vscode/tasks.json` (build_runner, analyze, test, l10n).
- **Android Studio / IntelliJ** : `.idea/runConfigurations/*.xml`.

⚠️ `.vscode/settings.json` déclare `dart.flutterSdkPath: .fvm/flutter_sdk`. Sans
ce réglage, l'éditeur analyse avec le Flutter global du poste (3.38.4) alors que
le projet est piné sur 3.44.2 — d'où des erreurs qui n'apparaissent que dans
l'éditeur, ou l'inverse.

⚠️ **Les flavors ne sont pas supportés par Flutter sur Windows ni Linux** :
`--flavor` y fait échouer la commande. Les configurations « (Windows) » s'en
passent ; l'environnement reste correct puisqu'il est déterminé par le point
d'entrée, pas par le drapeau.

Une configuration `FORCE_PLATFORM` permet d'inspecter le rendu iOS depuis macOS
sans simulateur (`--dart-define=FORCE_PLATFORM=ios`). La tab bar UIKit native y
reste indisponible : le plugin n'est pas enregistré hors iOS.

## Commandes

FVM est obligatoire (`.fvmrc` pin **Flutter 3.44.2**). Préfixer toutes les
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

---

## À trancher avant la feature messagerie

1. **Temps réel** — `pusher_channels_flutter`, utilisé par les apps client et
   management, ne supporte que **Android, iOS et web** : ni Windows ni macOS. Il
   est donc inutilisable ici. `socket_io_client` (pur Dart, déjà employé par
   `supplies_apk` via `SOCKET_URL`) fonctionne sur les quatre cibles. À confirmer
   contre le backend.
2. **Notifications** — `firebase_messaging` ne supporte pas Windows. Sur desktop,
   passer par `flutter_local_notifications` alimenté par le canal temps réel.
3. **Widgets de chat prêts à reprendre** — `supplies_apk` a déjà
   `ChatBubbleContent`, `ChatDateHeader`, `StickyDateChatList`, `ReactionBar`,
   `SwipeToReply`, `ChatInputWidget`, `VoiceMessageInputWidget`. Vérifier alors les
   dépendances desktop (`record`, `audio_waveforms`, `emoji_picker_flutter`).

Absents du socle par choix : Firebase, Crashlytics, Sentry, Shorebird, et toute la
couche `data`/`domain` de la messagerie.

---

## Backend partagé

- Base URL : `https://devbackend.01supplies.com`
- Spec OpenAPI : `GET /api/spec.json`
- Docs : `https://devbackend.01supplies.com/api/reference`
- Code source : `/Users/jojo/Projects/Node/supplies-backend-v2`

Point d'entrée messagerie connu : `GET /api/messaging/support/me` (filtre
`orderId` disponible). Les chemins sont regroupés dans
`core/constants/api_endpoints_urls.dart`.
