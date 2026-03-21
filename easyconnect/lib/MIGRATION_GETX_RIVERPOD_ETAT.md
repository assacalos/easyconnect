# État navigation & état global (EasyConnect)

Ce document remplace l’ancien suivi GetX. **L’app n’utilise plus GetX dans le flux produit.**

## Stack actuelle

- **État** : `flutter_riverpod` (notifiers / providers dans `lib/providers/`).
- **Navigation** : `go_router` (`lib/router/app_router.dart`). Les anciens `lib/Controllers/` et `lib/bindings/` ont été **supprimés** (plus aucune référence).
- **Stockage clé-valeur** : `get_storage` (le paquet `get` peut apparaître en **dépendance transitive** uniquement).

## Auth & API

- Session / utilisateur : `authProvider` et services (`api_service.dart`, `headersAsync()` pour les en-têtes avec rafraîchissement token si besoin).
- **Requêtes API métier** : passer par `HttpInterceptor` (`get` / `post` / `put` / `patch` / `delete`) — aligné sur `headersAsync`, retry 401, `SessionService.ensureValidToken`. Exceptions : `api_service.dart` (login, CSRF web, multipart), `session_service` (`/refresh` sans intercepteur), pointage photo (`MultipartRequest`).
- **401 / session** : après l’intercepteur, `AuthErrorHandler.handleHttpResponse` (défaut `skipRefresh: true`) pour éviter un double refresh ; snackbar « session expirée » + `logoutCallback` inchangés. Erreurs métier affichées via `ErrorHelper`, pas de logique session dupliquée là.

## Fichiers legacy à connaître

- `lib/routes/app_routes.dart` : stub vide conservé pour compatibilité ; la source de vérité des routes est **`app_router.dart`**.

## Maintenance

- Après ajout d’une route « détail » qui exige un modèle déjà chargé, mettre à jour la logique dans `notification_navigation_service.dart` (liste des préfixes qui redirigent vers la liste si la navigation depuis une notif ne peut pas fournir l’objet).
