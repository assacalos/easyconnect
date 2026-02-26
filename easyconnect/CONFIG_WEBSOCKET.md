# Configuration WebSocket (Pusher) – notifications en temps réel

**En production, Pusher est activé** : le backend (BROADCAST_DRIVER=pusher) et l’app utilisent les mêmes identifiants (PUSHER_APP_KEY, PUSHER_APP_CLUSTER=eu). Les clés dans `lib/utils/app_config.dart` sont alignées avec le `.env` production.

Ce guide décrit la configuration et les options de dépannage.

---

## Configuration actuelle (production)

### Backend Laravel (`.env` production)

- **BROADCAST_DRIVER=pusher**
- **PUSHER_APP_ID**, **PUSHER_APP_KEY**, **PUSHER_APP_SECRET**, **PUSHER_APP_CLUSTER=eu**

### App Flutter (`lib/utils/app_config.dart`)

- **websocketKey** = même valeur que `PUSHER_APP_KEY` du backend.
- **websocketCluster** = `"eu"` (même valeur que `PUSHER_APP_CLUSTER`).

L’app se connecte à Pusher au démarrage (après login) et utilise l’URL d’auth Laravel : `https://easykonect.smil-app.com/broadcasting/auth`.

---

## En cas de problème (erreurs CONNECTING / RECONNECTING / ON_ERROR)

### Vérifications

| Élément | Où vérifier |
|--------|--------------|
| Backend : BROADCAST_DRIVER=pusher | `.env` du backend |
| Backend : PUSHER_APP_KEY / SECRET / CLUSTER | `.env` du backend |
| App : même clé et même cluster | `app_config.dart` (websocketKey, websocketCluster) |
| Auth : token valide | Connexion utilisateur + pas de session expirée |
| Réseau / proxy | Pas de blocage WebSocket (wss) vers Pusher |

### Option de dépannage : désactiver temporairement le WebSocket

Si vous devez couper le WebSocket (par ex. pour réduire le bruit dans les logs pendant du debug) :

1. Ouvrez **`lib/utils/app_config.dart`**.
2. Mettez temporairement la clé à vide : `static const String websocketKey = "";`
3. L’app ne tentera plus de se connecter à Pusher. Les notifications restent disponibles via **Firebase (FCM)** et le chargement de la liste.

**À remettre ensuite** avec la vraie clé production pour retrouver le temps réel.

---

## Mise à jour du package Pusher (optionnel)

Le projet utilise **`pusher_client`** (communauté). Pour migrer vers le client officiel **`pusher_channels_flutter`**, il faudrait adapter le code (API différente) et vérifier la compatibilité avec **`laravel_echo`**. Ce n’est pas nécessaire pour faire fonctionner Pusher en production.
