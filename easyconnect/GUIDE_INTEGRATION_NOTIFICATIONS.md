# Guide d'Intégration - Système de Notifications Flutter

Ce guide explique comment intégrer le système de notifications dans l'application Flutter EasyConnect.

## 📦 Fichiers créés

1. **Modèle** : `lib/Models/notification_model.dart`
   - Modèle `AppNotification` conforme au format JSON du backend
   - Propriétés : `id`, `title`, `message`, `type`, `entityType`, `entityId`, `isRead`, `createdAt`, `actionRoute`, `metadata`

2. **Service API** : `lib/services/notification_api_service.dart`
   - Service pour communiquer avec l'API backend
   - Méthodes : `getNotifications()`, `markAsRead()`, `markAllAsRead()`, `getUnreadCount()`, `deleteNotification()`

3. **Contrôleur** : `lib/Controllers/notification_controller.dart`
   - Gestion de l'état des notifications
   - Polling automatique (toutes les 30 secondes)
   - Filtres et pagination
   - Navigation vers les entités

4. **Vue** : `lib/Views/Components/notifications_page.dart`
   - Page de liste des notifications
   - Widget `NotificationItemWidget` pour afficher une notification
   - Widget `NotificationBadge` pour le badge de compteur

## 🚀 Intégration

### 1. Ajouter le contrôleur dans les bindings

Le `NotificationController` est déjà ajouté dans `lib/bindings/app_bindings.dart` :

```dart
Get.put(NotificationController(), permanent: true);
```

### 2. Ajouter la route dans `app_routes.dart`

```dart
GetPage(
  name: '/notifications',
  page: () => const NotificationsPage(),
),
```

### 3. Ajouter le badge dans l'AppBar

Dans votre `AppBar` principale, ajoutez le badge de notifications :

```dart
AppBar(
  title: const Text('Dashboard'),
  actions: [
    NotificationBadge(
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () => Get.toNamed('/notifications'),
      ),
    ),
  ],
)
```

### 4. Exemple d'intégration dans un dashboard

```dart
import 'package:easyconnect/Views/Components/notifications_page.dart';
import 'package:easyconnect/Views/Components/notification_badge.dart';

class MyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => Get.toNamed('/notifications'),
            ),
          ),
        ],
      ),
      body: YourDashboardContent(),
    );
  }
}
```

## 📱 Utilisation

### Récupérer le contrôleur

```dart
final controller = Get.find<NotificationController>();
```

### Accéder aux notifications

```dart
// Liste des notifications
final notifications = controller.notifications;

// Compteur de non lues
final unreadCount = controller.unreadCount.value;
```

### Charger les notifications

```dart
// Charger toutes les notifications
await controller.loadNotifications();

// Charger seulement les non lues
controller.toggleUnreadOnly();
await controller.loadNotifications();

// Forcer le rafraîchissement
await controller.loadNotifications(forceRefresh: true);
```

### Marquer comme lue

```dart
// Une notification
await controller.markAsRead(notificationId);

// Toutes les notifications
await controller.markAllAsRead();
```

### Filtrer

```dart
// Par type
controller.filterByType('success'); // ou 'error', 'info', etc.

// Par type d'entité
controller.filterByEntityType('expense');

// Réinitialiser les filtres
controller.filterByType(null);
controller.filterByEntityType(null);
```

### Gérer le polling

Le polling démarre automatiquement quand le contrôleur est initialisé. Il se met à jour toutes les 30 secondes.

```dart
// Arrêter le polling (si nécessaire)
controller.stopPolling();

// Redémarrer avec un intervalle personnalisé
controller.startPolling(interval: Duration(seconds: 60));
```

## 🎨 Personnalisation

### Couleurs par type

Les couleurs sont définies dans le modèle `AppNotification` :

- `info` : Bleu (#2196F3)
- `success` : Vert (#4CAF50)
- `error` : Rouge (#F44336)
- `warning` : Orange (#FF9800)
- `task` : Violet (#9C27B0)

### Navigation personnalisée

Le contrôleur gère automatiquement la navigation selon le `entityType`. Si vous avez besoin de personnaliser la navigation, modifiez la méthode `_navigateToEntity()` dans `NotificationController`.

## 🔧 Configuration

### Intervalle de polling

Par défaut, le polling se fait toutes les 30 secondes. Pour changer :

```dart
controller.startPolling(interval: Duration(seconds: 60));
```

### Pagination

Par défaut, 20 notifications par page. Pour changer :

```dart
controller.perPage.value = 50;
```

## 📊 Mapping des routes

Le contrôleur mappe automatiquement les `entityType` vers les routes :

| entity_type | Route |
|-------------|-------|
| `expense` | `/expenses/{id}` |
| `leave_request` | `/leave-requests/{id}` |
| `attendance` | `/attendances/{id}` |
| `contract` | `/contracts/{id}` |
| `payment` | `/payments/{id}` |
| `client` | `/clients/{id}` |
| `devis` | `/devis/{id}` |
| `bordereau` | `/bordereaux/{id}` |
| `bon_commande` | `/bons-de-commande/{id}` |
| `invoice` | `/invoices/{id}` |
| `salary` | `/salaries/{id}` |
| `tax` | `/taxes/{id}` |
| `supplier` | `/fournisseurs/{id}` |
| `intervention` | `/interventions/{id}` |
| `recruitment` | `/recruitment-requests/{id}` |
| `stock` | `/stocks/{id}` |
| `reporting` | `/user-reportings/{id}` |

## ⚠️ Notes importantes

1. **Le contrôleur démarre automatiquement le polling** lors de l'initialisation
2. **Le polling s'arrête automatiquement** quand le contrôleur est supprimé
3. **Les notifications sont filtrées par utilisateur** côté backend
4. **Le compteur de non lues est mis à jour automatiquement** après chaque action
5. **La navigation utilise GetX** (`Get.toNamed()`)

## 🐛 Dépannage

### Les notifications ne s'affichent pas

1. Vérifiez que le contrôleur est bien initialisé dans les bindings
2. Vérifiez que l'API backend retourne les notifications au bon format
3. Vérifiez les logs dans la console

### Le polling ne fonctionne pas

1. Vérifiez que le contrôleur n'a pas été supprimé
2. Vérifiez que `startPolling()` est bien appelé
3. Vérifiez les logs pour les erreurs réseau

### La navigation ne fonctionne pas

1. Vérifiez que les routes sont bien définies dans `app_routes.dart`
2. Vérifiez que le `entityType` correspond à un type connu
3. Vérifiez que l'`entityId` est valide

## 📝 Exemple complet

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:easyconnect/Views/Components/notifications_page.dart';
import 'package:easyconnect/Views/Components/notification_badge.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Le contrôleur est déjà initialisé dans les bindings
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Badge avec compteur
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => Get.to(() => const NotificationsPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Afficher le compteur
          Obx(() => Text(
            'Notifications non lues: ${notificationController.unreadCount.value}',
          )),
          // Votre contenu
        ],
      ),
    );
  }
}
```

## ✅ Checklist d'intégration

- [x] Modèle `AppNotification` créé
- [x] Service API `NotificationApiService` créé
- [x] Contrôleur `NotificationController` créé avec polling
- [x] Page `NotificationsPage` créée
- [x] Widget `NotificationBadge` créé
- [x] Contrôleur ajouté dans `app_bindings.dart`
- [ ] Route `/notifications` ajoutée dans `app_routes.dart`
- [ ] Badge ajouté dans l'AppBar principale
- [ ] Test de l'affichage des notifications
- [ ] Test de la navigation vers les entités
- [ ] Test du polling automatique

