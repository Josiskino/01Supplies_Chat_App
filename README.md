# 01 Chat — messagerie interne 01Supplies

Application de messagerie interne destinée aux **agents logistique** et aux
**admins / superviseurs** de 01Supplies. Elle remplace les échanges WhatsApp avec
les clients pour les demandes de livraison, un canal que Meta bloque
régulièrement.

**Plateformes : Android, iOS, Windows, macOS.**

## État

Socle technique en place : architecture, thème, routage, coquille de navigation
adaptative, widgets partagés, flavors sur les quatre plateformes. La feature
messagerie reste à implémenter.

## Démarrage

Le projet utilise [FVM](https://fvm.app) et pin Flutter **3.44.2**.

```bash
fvm install
fvm flutter pub get
fvm dart run build_runner build
```

Créer les fichiers d'environnement (non versionnés, un par flavor) :

```bash
cat > .env.development <<'EOF'
BASE_URL=https://devbackend.01supplies.com
APP_ENV=development
X_API_KEY=<clé>
SOCKET_URL=https://realtimedev.01supplies.com
EOF
```

Puis lancer :

```bash
fvm flutter run --flavor development -t lib/main_development.dart
```

## Documentation

Architecture, conventions et pièges connus : [`CLAUDE.md`](CLAUDE.md).
