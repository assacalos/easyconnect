# Guide Frontend - Système de Notifications

## Vue d'ensemble

Le système de notifications est **bidirectionnel** pour toutes les entités avec workflow d'approbation :

1. **Soumission** → L'approbateur (patron/admin) reçoit une notification
2. **Approbation** → Le soumetteur (user/employee) reçoit une notification
3. **Rejet** → Le soumetteur reçoit une notification avec la raison

---

## Structure des Notifications

### Format JSON

```json
{
  "id": "123",
  "title": "Soumission Dépense",
  "message": "Dépense #EXP-2024-0001 a été soumise pour validation",
  "type": "info",
  "entity_type": "expense",
  "entity_id": "456",
  "is_read": false,
  "created_at": "2024-01-15T10:30:00.000Z",
  "action_route": "/expenses/456",
  "metadata": {
    "reason": "Raison du rejet (si applicable)"
  }
}
```

### Champs

| Champ | Type | Description |
|-------|------|-------------|
| `id` | string | ID de la notification |
| `title` | string | Titre de la notification |
| `message` | string | Message détaillé |
| `type` | string | Type : `info`, `success`, `warning`, `error`, `task` |
| `entity_type` | string | Type d'entité concernée |
| `entity_id` | string | ID de l'entité concernée |
| `is_read` | boolean | État de lecture |
| `created_at` | string | Date de création (ISO 8601) |
| `action_route` | string | Route pour accéder à l'entité |
| `metadata` | object | Données supplémentaires (ex: raison du rejet) |

---

## Types de Notifications par Entité

### 1. Expenses (Dépenses)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Dépense"
- **Message** : "Dépense #[number] a été soumise pour validation"
- **action_route** : `/expenses/{id}`

#### Approbation
- **Destinataire** : Employé qui a soumis
- **Type** : `success`
- **Title** : "Approbation Dépense"
- **Message** : "Votre Dépense #[number] a été approuvée"
- **action_route** : `/expenses/{id}`

#### Rejet
- **Destinataire** : Employé qui a soumis
- **Type** : `error`
- **Title** : "Rejet Dépense"
- **Message** : "Votre Dépense #[number] a été rejetée. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/expenses/{id}`

---

### 2. LeaveRequest (Demandes de Congé)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Demande de Congé"
- **Message** : "Demande de Congé #[id] a été soumise pour validation"
- **action_route** : `/leave-requests/{id}`

#### Approbation
- **Destinataire** : Employé qui a soumis
- **Type** : `success`
- **Title** : "Approbation Demande de Congé"
- **Message** : "Votre Demande de Congé #[id] a été approuvée"
- **action_route** : `/leave-requests/{id}`

#### Rejet
- **Destinataire** : Employé qui a soumis
- **Type** : `error`
- **Title** : "Rejet Demande de Congé"
- **Message** : "Votre Demande de Congé #[id] a été rejetée. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/leave-requests/{id}`

---

### 3. Attendance (Pointages)

#### Approbation
- **Destinataire** : Utilisateur qui a pointé
- **Type** : `success`
- **Title** : "Approbation Pointage du [date]"
- **Message** : "Votre Pointage du [date] a été approuvé"
- **action_route** : `/attendances/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a pointé
- **Type** : `error`
- **Title** : "Rejet Pointage du [date]"
- **Message** : "Votre Pointage du [date] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/attendances/{id}`

**Note** : Les pointages sont créés automatiquement, donc pas de notification de soumission.

---

### 4. Contract (Contrats)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Contrat"
- **Message** : "Contrat #[number] a été soumis pour validation"
- **action_route** : `/contracts/{id}`

#### Approbation
- **Destinataire** : Employé concerné
- **Type** : `success`
- **Title** : "Approbation Contrat"
- **Message** : "Votre Contrat #[number] a été approuvé"
- **action_route** : `/contracts/{id}`

#### Rejet
- **Destinataire** : Employé concerné
- **Type** : `error`
- **Title** : "Rejet Contrat"
- **Message** : "Votre Contrat #[number] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/contracts/{id}`

---

### 5. Payment (Paiements)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Paiement"
- **Message** : "Paiement #[reference] a été soumis pour validation"
- **action_route** : `/payments/{id}`

#### Approbation
- **Destinataire** : Comptable qui a créé
- **Type** : `success`
- **Title** : "Approbation Paiement"
- **Message** : "Votre Paiement #[reference] a été approuvé"
- **action_route** : `/payments/{id}`

#### Rejet
- **Destinataire** : Comptable qui a créé
- **Type** : `error`
- **Title** : "Rejet Paiement"
- **Message** : "Votre Paiement #[reference] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/payments/{id}`

---

### 6. Client

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Client"
- **Message** : "Client [nom] a été soumis pour validation"
- **action_route** : `/clients/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Client"
- **Message** : "Client [nom] a été validé"
- **action_route** : `/clients/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Client"
- **Message** : "Client [nom] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/clients/{id}`

---

### 7. Devis

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Devis"
- **Message** : "Devis #[reference] a été soumis pour validation"
- **action_route** : `/devis/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Devis"
- **Message** : "Devis #[reference] a été validé"
- **action_route** : `/devis/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Devis"
- **Message** : "Devis #[reference] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/devis/{id}`

---

### 8. Bordereau

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Bordereau"
- **Message** : "Bordereau #[reference] a été soumis pour validation"
- **action_route** : `/bordereaux/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Bordereau"
- **Message** : "Bordereau #[reference] a été validé"
- **action_route** : `/bordereaux/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Bordereau"
- **Message** : "Bordereau #[reference] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/bordereaux/{id}`

---

### 9. BonDeCommande (Bon de Commande)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Bon de Commande"
- **Message** : "Bon de commande #[numero] a été soumis pour validation"
- **action_route** : `/bons-de-commande/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Bon de Commande"
- **Message** : "Bon de commande #[numero] a été validé"
- **action_route** : `/bons-de-commande/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Bon de Commande"
- **Message** : "Bon de commande #[numero] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/bons-de-commande/{id}`

---

### 10. Facture (Invoice)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Facture"
- **Message** : "Facture #[numero] a été soumise pour validation"
- **action_route** : `/invoices/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Facture"
- **Message** : "Facture #[numero] a été validée"
- **action_route** : `/invoices/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Facture"
- **Message** : "Facture #[numero] a été rejetée. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/invoices/{id}`

---

### 11. Salary (Salaire)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Salaire"
- **Message** : "Salaire #[id] a été soumis pour validation"
- **action_route** : `/salaries/{id}`

#### Approbation
- **Destinataire** : Employé concerné
- **Type** : `success`
- **Title** : "Approbation Salaire"
- **Message** : "Salaire pour [nom] a été approuvé"
- **action_route** : `/salaries/{id}`

#### Rejet
- **Destinataire** : Employé concerné
- **Type** : `error`
- **Title** : "Rejet Salaire"
- **Message** : "Salaire pour [nom] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/salaries/{id}`

---

### 12. Tax (Taxe)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Taxe"
- **Message** : "Taxe #[reference] a été soumise pour validation"
- **action_route** : `/taxes/{id}`

#### Approbation
- **Destinataire** : Comptable qui a créé
- **Type** : `success`
- **Title** : "Validation Taxe"
- **Message** : "Taxe #[reference] a été validée"
- **action_route** : `/taxes/{id}`

#### Rejet
- **Destinataire** : Comptable qui a créé
- **Type** : `error`
- **Title** : "Rejet Taxe"
- **Message** : "Taxe #[reference] a été rejetée. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/taxes/{id}`

---

### 13. Fournisseur (Supplier)

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Fournisseur"
- **Message** : "Fournisseur [nom] a été soumis pour validation"
- **action_route** : `/fournisseurs/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Fournisseur"
- **Message** : "Fournisseur [nom] a été validé"
- **action_route** : `/fournisseurs/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Fournisseur"
- **Message** : "Fournisseur [nom] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/fournisseurs/{id}`

---

### 14. Intervention

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Intervention"
- **Message** : "Intervention #[id] a été soumise pour validation"
- **action_route** : `/interventions/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Approbation Intervention"
- **Message** : "Intervention #[id] a été approuvée"
- **action_route** : `/interventions/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Intervention"
- **Message** : "Intervention #[id] a été rejetée. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/interventions/{id}`

---

### 15. Recruitment (Recrutement)

#### Soumission (Publication)
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Demande de Recrutement"
- **Message** : "Demande de recrutement #[id] a été soumise pour validation"
- **action_route** : `/recruitment-requests/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Approbation Demande de Recrutement"
- **Message** : "Demande de recrutement #[id] a été approuvée"
- **action_route** : `/recruitment-requests/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Demande de Recrutement"
- **Message** : "Demande de recrutement #[id] a été rejetée. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/recruitment-requests/{id}`

---

### 16. Stock

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Stock"
- **Message** : "Stock [nom] a été soumis pour validation"
- **action_route** : `/stocks/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Validation Stock"
- **Message** : "Stock [nom] a été validé"
- **action_route** : `/stocks/{id}`

#### Rejet
- **Destinataire** : Utilisateur qui a créé
- **Type** : `error`
- **Title** : "Rejet Stock"
- **Message** : "Stock [nom] a été rejeté. Raison: [reason]"
- **metadata** : `{ "reason": "..." }`
- **action_route** : `/stocks/{id}`

---

### 17. Reporting

#### Soumission
- **Destinataire** : Patron (role 6)
- **Type** : `info`
- **Title** : "Soumission Reporting"
- **Message** : "Reporting #[id] a été soumis pour validation"
- **action_route** : `/user-reportings/{id}`

#### Approbation
- **Destinataire** : Utilisateur qui a créé
- **Type** : `success`
- **Title** : "Approbation Reporting"
- **Message** : "Reporting #[id] a été approuvé"
- **action_route** : `/user-reportings/{id}`

---

## Types de Notifications

| Type | Description | Usage Frontend | Couleur Recommandée |
|------|-------------|----------------|---------------------|
| `info` | Information générale | Badge bleu, icône info | Bleu (#2196F3) |
| `success` | Succès/Validation | Badge vert, icône check | Vert (#4CAF50) |
| `warning` | Avertissement | Badge orange, icône warning | Orange (#FF9800) |
| `error` | Erreur/Rejet | Badge rouge, icône error | Rouge (#F44336) |
| `task` | Tâche à effectuer | Badge violet, icône task | Violet (#9C27B0) |

---

## API Endpoints

### Récupérer les notifications

```http
GET /api/notifications
```

**Query Parameters** :
- `type` : Filtrer par type (`info`, `success`, `error`, etc.)
- `unread_only` : Seulement les non lues (`true`/`false`)
- `entity_type` : Filtrer par type d'entité (`expense`, `leave_request`, etc.)
- `per_page` : Nombre par page (défaut: 20)
- `page` : Numéro de page (défaut: 1)

**Response** :
```json
{
  "success": true,
  "data": [
    {
      "id": "123",
      "title": "Soumission Dépense",
      "message": "Dépense #EXP-2024-0001 a été soumise pour validation",
      "type": "info",
      "entity_type": "expense",
      "entity_id": "456",
      "is_read": false,
      "created_at": "2024-01-15T10:30:00.000Z",
      "action_route": "/expenses/456",
      "metadata": null
    }
  ],
  "unread_count": 5,
  "pagination": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 45
  }
}
```

### Marquer comme lue

```http
PUT /api/notifications/{id}/read
```

**Response** :
```json
{
  "success": true,
  "message": "Notification marquée comme lue"
}
```

### Marquer toutes comme lues

```http
PUT /api/notifications/read-all
```

**Response** :
```json
{
  "success": true,
  "message": "Toutes les notifications ont été marquées comme lues",
  "count": 5
}
```

### Supprimer une notification

```http
DELETE /api/notifications/{id}
```

**Response** :
```json
{
  "success": true,
  "message": "Notification supprimée"
}
```

### Compter les non lues

```http
GET /api/notifications/unread
```

**Response** :
```json
{
  "success": true,
  "count": 5
}
```

---

## Implémentation Frontend Recommandée

### 1. Modèle de Données (Flutter/Dart)

```dart
class Notification {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'success', 'error', 'warning', 'task'
  final String entityType;
  final String entityId;
  final bool isRead;
  final DateTime createdAt;
  final String actionRoute;
  final Map<String, dynamic>? metadata;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.createdAt,
    required this.actionRoute,
    this.metadata,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      entityType: json['entity_type'] ?? '',
      entityId: json['entity_id'].toString(),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      actionRoute: json['action_route'] ?? '',
      metadata: json['metadata'],
    );
  }
}
```

### 2. Service de Notifications

```dart
class NotificationService {
  final ApiClient _api = ApiClient();
  
  Future<List<Notification>> getNotifications({
    bool unreadOnly = false,
    String? type,
    String? entityType,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    
    if (unreadOnly) params['unread_only'] = 'true';
    if (type != null) params['type'] = type;
    if (entityType != null) params['entity_type'] = entityType;
    
    final response = await _api.get('/notifications', params: params);
    
    return (response['data'] as List)
        .map((json) => Notification.fromJson(json))
        .toList();
  }
  
  Future<void> markAsRead(String notificationId) async {
    await _api.put('/notifications/$notificationId/read');
  }
  
  Future<void> markAllAsRead() async {
    await _api.put('/notifications/read-all');
  }
  
  Future<int> getUnreadCount() async {
    final response = await _api.get('/notifications/unread');
    return response['count'] ?? 0;
  }
  
  Future<void> deleteNotification(String notificationId) async {
    await _api.delete('/notifications/$notificationId');
  }
}
```

### 3. Polling des Notifications

```dart
class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollingTimer;
  
  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  
  Future<void> loadNotifications({bool unreadOnly = false}) async {
    try {
      _notifications = await _service.getNotifications(unreadOnly: unreadOnly);
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }
  
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      loadNotifications();
    });
  }
  
  void stopPolling() {
    _pollingTimer?.cancel();
  }
  
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = Notification(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        type: _notifications[index].type,
        entityType: _notifications[index].entityType,
        entityId: _notifications[index].entityId,
        isRead: true, // Updated
        createdAt: _notifications[index].createdAt,
        actionRoute: _notifications[index].actionRoute,
        metadata: _notifications[index].metadata,
      );
      _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
      notifyListeners();
    }
  }
  
  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
    _unreadCount = 0;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = Notification(
          id: _notifications[i].id,
          title: _notifications[i].title,
          message: _notifications[i].message,
          type: _notifications[i].type,
          entityType: _notifications[i].entityType,
          entityId: _notifications[i].entityId,
          isRead: true,
          createdAt: _notifications[i].createdAt,
          actionRoute: _notifications[i].actionRoute,
          metadata: _notifications[i].metadata,
        );
      }
    }
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
```

### 4. Widget d'Affichage des Notifications

```dart
Widget buildNotificationItem(Notification notification) {
  Color badgeColor;
  IconData icon;
  
  switch (notification.type) {
    case 'success':
      badgeColor = Colors.green;
      icon = Icons.check_circle;
      break;
    case 'error':
      badgeColor = Colors.red;
      icon = Icons.error;
      break;
    case 'warning':
      badgeColor = Colors.orange;
      icon = Icons.warning;
      break;
    case 'task':
      badgeColor = Colors.purple;
      icon = Icons.task;
      break;
    default: // 'info'
      badgeColor = Colors.blue;
      icon = Icons.info;
  }
  
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: badgeColor.withOpacity(0.1),
      child: Icon(icon, color: badgeColor),
    ),
    title: Text(
      notification.title,
      style: TextStyle(
        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(notification.message),
        if (notification.metadata?['reason'] != null)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Raison: ${notification.metadata!['reason']}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ),
        SizedBox(height: 4),
        Text(
          _formatDate(notification.createdAt),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
    trailing: notification.isRead
        ? null
        : Icon(Icons.circle, color: Colors.blue, size: 8),
    onTap: () {
      _handleNotificationTap(notification);
    },
  );
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays == 0) {
    if (difference.inHours == 0) {
      return 'Il y a ${difference.inMinutes} min';
    }
    return 'Il y a ${difference.inHours} h';
  } else if (difference.inDays == 1) {
    return 'Hier';
  } else if (difference.inDays < 7) {
    return 'Il y a ${difference.inDays} jours';
  } else {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
```

### 5. Navigation vers l'Entité

```dart
void handleNotificationTap(Notification notification) {
  // Marquer comme lue
  notificationProvider.markAsRead(notification.id);
  
  // Naviguer vers l'entité
  switch (notification.entityType) {
    case 'expense':
      Navigator.pushNamed(context, '/expenses/${notification.entityId}');
      break;
    case 'leave_request':
      Navigator.pushNamed(context, '/leave-requests/${notification.entityId}');
      break;
    case 'attendance':
      Navigator.pushNamed(context, '/attendances/${notification.entityId}');
      break;
    case 'contract':
      Navigator.pushNamed(context, '/contracts/${notification.entityId}');
      break;
    case 'payment':
      Navigator.pushNamed(context, '/payments/${notification.entityId}');
      break;
    case 'client':
      Navigator.pushNamed(context, '/clients/${notification.entityId}');
      break;
    case 'devis':
      Navigator.pushNamed(context, '/devis/${notification.entityId}');
      break;
    case 'bordereau':
      Navigator.pushNamed(context, '/bordereaux/${notification.entityId}');
      break;
    case 'bon_commande':
      Navigator.pushNamed(context, '/bons-de-commande/${notification.entityId}');
      break;
    case 'invoice':
      Navigator.pushNamed(context, '/invoices/${notification.entityId}');
      break;
    case 'salary':
      Navigator.pushNamed(context, '/salaries/${notification.entityId}');
      break;
    case 'tax':
      Navigator.pushNamed(context, '/taxes/${notification.entityId}');
      break;
    case 'supplier':
      Navigator.pushNamed(context, '/fournisseurs/${notification.entityId}');
      break;
    case 'intervention':
      Navigator.pushNamed(context, '/interventions/${notification.entityId}');
      break;
    case 'recruitment':
      Navigator.pushNamed(context, '/recruitment-requests/${notification.entityId}');
      break;
    case 'stock':
      Navigator.pushNamed(context, '/stocks/${notification.entityId}');
      break;
    case 'reporting':
      Navigator.pushNamed(context, '/user-reportings/${notification.entityId}');
      break;
    default:
      // Route par défaut ou afficher un message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Type d\'entité non reconnu: ${notification.entityType}')),
      );
      break;
  }
}
```

### 6. Badge de Compteur

```dart
StreamBuilder<int>(
  stream: notificationProvider.unreadCountStream,
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    if (count == 0) return SizedBox.shrink();
    
    return Badge(
      label: Text('$count'),
      child: IconButton(
        icon: Icon(Icons.notifications),
        onPressed: () => Navigator.pushNamed(context, '/notifications'),
      ),
    );
  },
)
```

### 7. Page de Liste des Notifications

```dart
class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationProvider _provider = NotificationProvider();
  bool _unreadOnly = false;
  
  @override
  void initState() {
    super.initState();
    _provider.loadNotifications();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(_unreadOnly ? Icons.filter_list : Icons.filter_list_off),
            onPressed: () {
              setState(() {
                _unreadOnly = !_unreadOnly;
                _provider.loadNotifications(unreadOnly: _unreadOnly);
              });
            },
          ),
          if (_provider.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await _provider.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Toutes les notifications ont été marquées comme lues')),
                );
              },
              child: Text('Tout marquer comme lu'),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _provider,
        builder: (context, _) {
          if (_provider.notifications.isEmpty) {
            return Center(
              child: Text('Aucune notification'),
            );
          }
          
          return ListView.builder(
            itemCount: _provider.notifications.length,
            itemBuilder: (context, index) {
              final notification = _provider.notifications[index];
              return buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }
}
```

---

## Mapping des Types d'Entités

| entity_type | Route Frontend | Page/Écran |
|-------------|---------------|------------|
| `expense` | `/expenses/{id}` | Détails dépense |
| `leave_request` | `/leave-requests/{id}` | Détails demande congé |
| `attendance` | `/attendances/{id}` | Détails pointage |
| `contract` | `/contracts/{id}` | Détails contrat |
| `payment` | `/payments/{id}` | Détails paiement |
| `client` | `/clients/{id}` | Détails client |
| `devis` | `/devis/{id}` | Détails devis |
| `bordereau` | `/bordereaux/{id}` | Détails bordereau |
| `bon_commande` | `/bons-de-commande/{id}` | Détails bon de commande |
| `invoice` | `/invoices/{id}` | Détails facture |
| `salary` | `/salaries/{id}` | Détails salaire |
| `tax` | `/taxes/{id}` | Détails taxe |
| `supplier` | `/fournisseurs/{id}` | Détails fournisseur |
| `intervention` | `/interventions/{id}` | Détails intervention |
| `recruitment` | `/recruitment-requests/{id}` | Détails demande recrutement |
| `stock` | `/stocks/{id}` | Détails stock |
| `reporting` | `/user-reportings/{id}` | Détails reporting |

---

## Exemples de Messages par Type

### Info (Soumission)
- "Dépense #EXP-2024-0001 a été soumise pour validation"
- "Demande de Congé #123 a été soumise pour validation"
- "Contrat #CT-2024-001 a été soumis pour validation"

### Success (Approbation)
- "Votre Dépense #EXP-2024-0001 a été approuvée"
- "Votre Demande de Congé #123 a été approuvée"
- "Votre Pointage du 15/01/2024 a été approuvé"

### Error (Rejet)
- "Votre Dépense #EXP-2024-0001 a été rejetée. Raison: Justificatif manquant"
- "Votre Demande de Congé #123 a été rejetée. Raison: Conflit avec un autre congé"
- "Votre Pointage du 15/01/2024 a été rejeté. Raison: Photo invalide"

---

## Bonnes Pratiques

1. **Toujours afficher le badge de compteur** pour les notifications non lues
2. **Marquer comme lue** automatiquement quand l'utilisateur clique dessus
3. **Naviguer directement** vers l'entité concernée via `action_route`
4. **Afficher la raison** du rejet depuis `metadata.reason` si disponible
5. **Grouper par type** dans l'interface si nécessaire
6. **Actualiser périodiquement** (polling toutes les 30-60 secondes)
7. **Gérer les erreurs** gracieusement si l'entité n'existe plus
8. **Afficher la date relative** (il y a X minutes/heures/jours)
9. **Permettre de filtrer** par type et par état (lues/non lues)
10. **Offrir une action "Tout marquer comme lu"**

---

## Notes Importantes

1. **Les notifications sont asynchrones** : Elles peuvent arriver avec un léger délai
2. **Le polling est recommandé** : Pas de WebSockets actuellement
3. **Les notifications sont persistantes** : Stockées en base de données
4. **Chaque utilisateur voit seulement ses notifications** : Filtrage automatique par `user_id`
5. **Les notifications peuvent être archivées** : Utiliser l'endpoint `/archive` si disponible
6. **Les routes d'action** sont relatives et doivent être adaptées selon votre structure de routes frontend

---

## Conclusion

Le système de notifications est **standardisé** et **bidirectionnel** pour toutes les entités. Le frontend doit :

1. ✅ Récupérer les notifications via l'API
2. ✅ Afficher un badge avec le compteur de non lues
3. ✅ Naviguer vers l'entité concernée au clic
4. ✅ Marquer comme lue automatiquement
5. ✅ Gérer les différents types visuellement
6. ✅ Afficher la raison du rejet si disponible
7. ✅ Implémenter le polling pour les mises à jour en temps réel

