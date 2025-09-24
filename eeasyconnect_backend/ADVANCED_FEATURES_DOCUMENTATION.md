# Documentation des Fonctionnalités Avancées - Application CRM

## Vue d'ensemble
Cette documentation présente les nouvelles fonctionnalités avancées implémentées dans l'application CRM : gestion des congés, évaluations des employés, et notifications en temps réel.

---

## 1. Gestion des Congés

### Modèle Conge
**Fichier** : `app/Models/Conge.php`

#### Champs principaux :
- `user_id` : ID de l'employé
- `type_conge` : Type de congé (annuel, maladie, maternité, etc.)
- `date_debut` / `date_fin` : Période du congé
- `nombre_jours` : Nombre de jours calculé automatiquement
- `motif` : Motif du congé
- `status` : En attente, approuvé, rejeté
- `urgent` : Congé urgent ou non
- `piece_jointe` : Fichier joint (optionnel)

#### Relations :
- `user()` : Employé qui demande le congé
- `approbateur()` : RH/Admin qui a approuvé/rejeté

#### Méthodes utiles :
- `isEnCours()` : Vérifier si le congé est en cours
- `isPasse()` : Vérifier si le congé est passé
- `isFutur()` : Vérifier si le congé est futur
- `getStatutLibelle()` : Obtenir le statut en français
- `getTypeLibelle()` : Obtenir le type en français

### Contrôleur CongeController
**Fichier** : `app/Http/Controllers/API/CongeController.php`

#### Fonctionnalités :
- ✅ **CRUD complet** des congés
- ✅ **Validation des conflits** de dates
- ✅ **Approbation/Rejet** par les RH
- ✅ **Statistiques détaillées** des congés
- ✅ **Notifications automatiques** en temps réel
- ✅ **Gestion des pièces jointes**

#### Routes disponibles :
```php
// Routes pour tous les utilisateurs
GET    /api/my-conges              // Mes congés
POST   /api/my-conges              // Créer un congé
GET    /api/my-conges/{id}         // Détails d'un congé
PUT    /api/my-conges/{id}         // Modifier un congé
DELETE /api/my-conges/{id}         // Supprimer un congé

// Routes pour RH/Admin
GET    /api/conges                 // Liste des congés
GET    /api/conges/{id}            // Détails d'un congé
POST   /api/conges/{id}/approve    // Approuver un congé
POST   /api/conges/{id}/reject     // Rejeter un congé
GET    /api/conges-statistics      // Statistiques des congés
```

---

## 2. Évaluations des Employés

### Modèle Evaluation
**Fichier** : `app/Models/Evaluation.php`

#### Champs principaux :
- `user_id` : Employé évalué
- `evaluateur_id` : RH/Manager qui évalue
- `type_evaluation` : Type d'évaluation (annuelle, trimestrielle, etc.)
- `date_evaluation` : Date de l'évaluation
- `periode_debut` / `periode_fin` : Période évaluée
- `criteres_evaluation` : Critères d'évaluation (JSON)
- `note_globale` : Note sur 20
- `commentaires_evaluateur` : Commentaires de l'évaluateur
- `commentaires_employe` : Commentaires de l'employé
- `objectifs_futurs` : Objectifs futurs
- `status` : En cours, finalisée, archivée
- `date_signature_employe` : Date de signature employé
- `date_signature_evaluateur` : Date de signature évaluateur
- `confidentiel` : Évaluation confidentielle ou non

#### Relations :
- `user()` : Employé évalué
- `evaluateur()` : Évaluateur

#### Méthodes utiles :
- `getStatutLibelle()` : Obtenir le statut en français
- `getTypeLibelle()` : Obtenir le type en français
- `getNoteLettres()` : Obtenir la note en lettres
- `isSignee()` : Vérifier si l'évaluation est signée
- `isEnRetard()` : Vérifier si l'évaluation est en retard

### Contrôleur EvaluationController
**Fichier** : `app/Http/Controllers/API/EvaluationController.php`

#### Fonctionnalités :
- ✅ **CRUD complet** des évaluations
- ✅ **Système de signature** employé/évaluateur
- ✅ **Commentaires** des deux parties
- ✅ **Statistiques détaillées** des évaluations
- ✅ **Notifications automatiques** en temps réel
- ✅ **Gestion de la confidentialité**

#### Routes disponibles :
```php
// Routes pour tous les utilisateurs
GET    /api/my-evaluations                    // Mes évaluations
GET    /api/my-evaluations/{id}               // Détails d'une évaluation
POST   /api/my-evaluations/{id}/employee-comments  // Ajouter commentaires
POST   /api/my-evaluations/{id}/sign-employee     // Signer (employé)

// Routes pour RH/Admin
GET    /api/evaluations                       // Liste des évaluations
GET    /api/evaluations/{id}                  // Détails d'une évaluation
POST   /api/evaluations                       // Créer une évaluation
PUT    /api/evaluations/{id}                  // Modifier une évaluation
POST   /api/evaluations/{id}/sign-evaluator   // Signer (évaluateur)
POST   /api/evaluations/{id}/finalize         // Finaliser
GET    /api/evaluations-statistics            // Statistiques
```

---

## 3. Notifications en Temps Réel

### Modèle Notification
**Fichier** : `app/Models/Notification.php`

#### Champs principaux :
- `user_id` : Utilisateur destinataire
- `type` : Type de notification (pointage, congé, évaluation, etc.)
- `titre` : Titre de la notification
- `message` : Message de la notification
- `data` : Données supplémentaires (JSON)
- `status` : Non lue, lue, archivée
- `priorite` : Basse, normale, haute, urgente
- `canal` : App, email, SMS, push
- `date_lecture` : Date de lecture
- `date_expiration` : Date d'expiration
- `envoyee` : Notification envoyée ou non

#### Relations :
- `user()` : Utilisateur destinataire

#### Méthodes utiles :
- `getStatutLibelle()` : Obtenir le statut en français
- `getPrioriteLibelle()` : Obtenir la priorité en français
- `getTypeLibelle()` : Obtenir le type en français
- `isExpiree()` : Vérifier si la notification est expirée
- `marquerCommeLue()` : Marquer comme lue
- `archiver()` : Archiver la notification

### Contrôleur NotificationController
**Fichier** : `app/Http/Controllers/API/NotificationController.php`

#### Fonctionnalités :
- ✅ **Gestion complète** des notifications
- ✅ **Marquage comme lue** individuel et en masse
- ✅ **Archivage** des notifications
- ✅ **Statistiques détaillées** des notifications
- ✅ **Filtrage** par type, priorité, statut
- ✅ **Nettoyage automatique** des notifications expirées

#### Routes disponibles :
```php
// Routes pour tous les utilisateurs
GET    /api/notifications                     // Liste des notifications
GET    /api/notifications/{id}                // Détails d'une notification
POST   /api/notifications/{id}/mark-read      // Marquer comme lue
POST   /api/notifications/mark-all-read       // Marquer toutes comme lues
POST   /api/notifications/{id}/archive        // Archiver une notification
POST   /api/notifications/archive-all-read    // Archiver toutes les lues
GET    /api/notifications/unread              // Notifications non lues
GET    /api/notifications/urgent              // Notifications urgentes
GET    /api/notifications-statistics          // Statistiques
DELETE /api/notifications/{id}                // Supprimer une notification

// Routes pour Admin
POST   /api/notifications                     // Créer une notification
POST   /api/notifications/cleanup             // Nettoyer les expirées
DELETE /api/notifications/destroy-archived    // Supprimer les archivées
```

---

## 4. Service de Notifications en Temps Réel

### NotificationService
**Fichier** : `app/Services/NotificationService.php`

#### Fonctionnalités :
- ✅ **Création et diffusion** automatique des notifications
- ✅ **Diffusion par rôle** (RH, Admin, Patron, etc.)
- ✅ **Notifications spécialisées** par type d'événement
- ✅ **Intégration Pusher** pour le temps réel
- ✅ **Gestion des erreurs** et logs

#### Méthodes principales :
- `createAndBroadcast()` : Créer et diffuser une notification
- `broadcastToUser()` : Diffuser à un utilisateur spécifique
- `broadcastToRole()` : Diffuser à un rôle spécifique
- `broadcastToRH()` : Diffuser aux RH
- `broadcastToAdmins()` : Diffuser aux admins
- `broadcastToPatrons()` : Diffuser aux patrons

#### Notifications spécialisées :
- `notifyNewPointage()` : Nouveau pointage
- `notifyPointageValidated()` : Pointage validé
- `notifyPointageRejected()` : Pointage rejeté
- `notifyNewConge()` : Nouveau congé
- `notifyCongeApproved()` : Congé approuvé
- `notifyCongeRejected()` : Congé rejeté
- `notifyNewEvaluation()` : Nouvelle évaluation
- `notifyEvaluationFinalized()` : Évaluation finalisée
- `notifyNewClient()` : Nouveau client
- `notifyClientValidated()` : Client validé
- `notifyClientRejected()` : Client rejeté
- `notifyNewPayment()` : Nouveau paiement
- `notifyPaymentValidated()` : Paiement validé
- `notifySystem()` : Notification système
- `notifyMaintenance()` : Notification de maintenance

---

## 5. Configuration des Notifications

### Fichier de Configuration
**Fichier** : `config/notifications.php`

#### Configuration Pusher :
```php
'pusher' => [
    'app_id' => env('PUSHER_APP_ID'),
    'key' => env('PUSHER_APP_KEY'),
    'secret' => env('PUSHER_APP_SECRET'),
    'cluster' => env('PUSHER_APP_CLUSTER', 'mt1'),
    'useTLS' => true,
],
```

#### Canaux de diffusion :
```php
'channels' => [
    'user' => 'user.{user_id}',
    'role' => 'role.{role_id}',
    'admin' => 'admin',
    'rh' => 'rh',
    'commercial' => 'commercial',
    'comptable' => 'comptable',
    'technicien' => 'technicien',
    'patron' => 'patron',
],
```

#### Types de notifications :
```php
'types' => [
    'pointage' => 'Pointage',
    'conge' => 'Congé',
    'evaluation' => 'Évaluation',
    'client' => 'Client',
    'facture' => 'Facture',
    'paiement' => 'Paiement',
    'systeme' => 'Système',
    'rapport' => 'Rapport',
    'maintenance' => 'Maintenance',
],
```

---

## 6. Event de Notification

### NotificationReceived
**Fichier** : `app/Events/NotificationReceived.php`

#### Fonctionnalités :
- ✅ **Diffusion en temps réel** via Pusher
- ✅ **Canal privé** par utilisateur
- ✅ **Données structurées** pour le frontend
- ✅ **Timestamp** de réception

#### Configuration :
```php
public function broadcastOn(): array
{
    return [
        new PrivateChannel('user.' . $this->notification->user_id),
    ];
}

public function broadcastAs(): string
{
    return 'notification.received';
}
```

---

## 7. Middleware de Notification

### NotificationMiddleware
**Fichier** : `app/Http/Middleware/NotificationMiddleware.php`

#### Fonctionnalités :
- ✅ **Ajout automatique** du nombre de notifications non lues
- ✅ **Comptage des notifications urgentes**
- ✅ **Intégration transparente** dans les réponses API

#### Utilisation :
```php
// Dans Kernel.php
protected $middleware = [
    // ...
    \App\Http\Middleware\NotificationMiddleware::class,
];
```

---

## 8. Exemples d'Utilisation

### 1. Créer un Congé
```bash
# Connexion
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Créer un congé
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-05",
    "motif": "Vacances familiales",
    "urgent": false
  }'
```

### 2. Approuver un Congé (RH)
```bash
# Connexion RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

# Approuver un congé
curl -X POST http://localhost:8000/api/conges/1/approve \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "commentaire_rh": "Congé approuvé, bonnes vacances !"
  }'
```

### 3. Créer une Évaluation
```bash
# Connexion RH
RH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "rh@example.com", "password": "password"}' | jq -r '.token')

# Créer une évaluation
curl -X POST http://localhost:8000/api/evaluations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "user_id": 5,
    "type_evaluation": "annuelle",
    "date_evaluation": "2024-01-15",
    "periode_debut": "2023-01-01",
    "periode_fin": "2023-12-31",
    "criteres_evaluation": {
      "performance": 16,
      "ponctualite": 18,
      "collaboration": 15,
      "initiative": 17
    },
    "note_globale": 16.5,
    "commentaires_evaluateur": "Excellent travail cette année",
    "objectifs_futurs": "Continuer sur cette lancée",
    "confidentiel": true
  }'
```

### 4. Signer une Évaluation (Employé)
```bash
# Connexion Technicien
TECH_TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Signer une évaluation
curl -X POST http://localhost:8000/api/my-evaluations/1/sign-employee \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### 5. Gérer les Notifications
```bash
# Connexion
TOKEN=$(curl -s -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "technicien@example.com", "password": "password"}' | jq -r '.token')

# Liste des notifications
curl -X GET http://localhost:8000/api/notifications \
  -H "Authorization: Bearer $TOKEN"

# Notifications non lues
curl -X GET http://localhost:8000/api/notifications/unread \
  -H "Authorization: Bearer $TOKEN"

# Marquer comme lue
curl -X POST http://localhost:8000/api/notifications/1/mark-read \
  -H "Authorization: Bearer $TOKEN"

# Marquer toutes comme lues
curl -X POST http://localhost:8000/api/notifications/mark-all-read \
  -H "Authorization: Bearer $TOKEN"

# Statistiques des notifications
curl -X GET http://localhost:8000/api/notifications-statistics \
  -H "Authorization: Bearer $TOKEN"
```

---

## 9. Configuration Frontend (Flutter)

### Configuration Pusher
```dart
// pubspec.yaml
dependencies:
  pusher_channels_flutter: ^2.2.1

// main.dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class NotificationService {
  static PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  
  static Future<void> initialize() async {
    await pusher.init(
      apiKey: "YOUR_PUSHER_KEY",
      cluster: "mt1",
      onConnectionStateChange: (String currentState, String previousState) {
        print("Connection state changed: $previousState -> $currentState");
      },
      onError: (String message, int? code, dynamic e) {
        print("Error: $message (Code: $code)");
      },
    );
    
    await pusher.connect();
  }
  
  static void subscribeToUserNotifications(String userId) {
    pusher.subscribe(channelName: "private-user.$userId");
    pusher.on("notification.received", (event) {
      // Traiter la notification reçue
      print("Notification reçue: ${event.data}");
    });
  }
}
```

### Gestion des Notifications
```dart
class NotificationManager {
  static List<Notification> notifications = [];
  static int unreadCount = 0;
  static int urgentCount = 0;
  
  static void addNotification(Map<String, dynamic> data) {
    final notification = Notification.fromJson(data);
    notifications.insert(0, notification);
    
    if (notification.statut == 'non_lue') {
      unreadCount++;
      if (notification.priorite == 'urgente') {
        urgentCount++;
      }
    }
    
    // Mettre à jour l'UI
    notifyListeners();
  }
  
  static void markAsRead(int notificationId) {
    final notification = notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    
    if (notification.statut == 'non_lue') {
      notification.statut = 'lue';
      unreadCount--;
      if (notification.priorite == 'urgente') {
        urgentCount--;
      }
    }
    
    notifyListeners();
  }
}
```

---

## 10. Tests et Validation

### Tests des Congés
```bash
# Test de création de congé
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-05",
    "motif": "Test de congé"
  }'

# Test de validation des conflits
curl -X POST http://localhost:8000/api/my-conges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "type_conge": "annuel",
    "date_debut": "2024-02-01",
    "date_fin": "2024-02-05",
    "motif": "Test de conflit"
  }'
# Doit retourner une erreur de conflit
```

### Tests des Évaluations
```bash
# Test de création d'évaluation
curl -X POST http://localhost:8000/api/evaluations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RH_TOKEN" \
  -d '{
    "user_id": 5,
    "type_evaluation": "annuelle",
    "date_evaluation": "2024-01-15",
    "periode_debut": "2023-01-01",
    "periode_fin": "2023-12-31",
    "criteres_evaluation": {"performance": 16},
    "note_globale": 16.0,
    "commentaires_evaluateur": "Test d'\''évaluation"
  }'

# Test de signature
curl -X POST http://localhost:8000/api/my-evaluations/1/sign-employee \
  -H "Authorization: Bearer $TECH_TOKEN"
```

### Tests des Notifications
```bash
# Test de création de notification
curl -X POST http://localhost:8000/api/notifications \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "user_id": 5,
    "type": "systeme",
    "titre": "Test de notification",
    "message": "Ceci est un test",
    "priorite": "normale",
    "canal": "app"
  }'

# Test de marquage comme lue
curl -X POST http://localhost:8000/api/notifications/1/mark-read \
  -H "Authorization: Bearer $TOKEN"
```

---

## 11. Sécurité et Permissions

### Permissions par Rôle

#### Technicien (Role: 5)
- ✅ **Ses propres congés** (CRUD si en attente)
- ✅ **Ses propres évaluations** (lecture, commentaires, signature)
- ✅ **Ses propres notifications** (gestion complète)

#### RH (Role: 4)
- ✅ **Tous les congés** (CRUD, approbation/rejet)
- ✅ **Toutes les évaluations** (CRUD, signature)
- ✅ **Toutes les notifications** (gestion complète)

#### Patron (Role: 6)
- ✅ **Tous les congés** (lecture, approbation/rejet)
- ✅ **Toutes les évaluations** (lecture, signature)
- ✅ **Toutes les notifications** (lecture)

#### Admin (Role: 1)
- ✅ **Accès complet** à toutes les fonctionnalités
- ✅ **Gestion des notifications** système
- ✅ **Nettoyage** des données

---

## 12. Performance et Optimisation

### Optimisations Implémentées
- ✅ **Indexation** des champs de recherche
- ✅ **Relations** optimisées avec `with()`
- ✅ **Pagination** pour les listes importantes
- ✅ **Cache** pour les statistiques
- ✅ **Nettoyage automatique** des notifications expirées

### Recommandations
- 🔄 **Cache Redis** pour les notifications fréquentes
- 🔄 **Queue** pour les notifications en masse
- 🔄 **Compression** des données de notification
- 🔄 **CDN** pour les pièces jointes

---

## 13. Monitoring et Logs

### Logs Implémentés
- ✅ **Erreurs de diffusion** Pusher
- ✅ **Création de notifications** importantes
- ✅ **Actions de validation** (congés, évaluations)
- ✅ **Signatures** d'évaluations

### Métriques à Surveiller
- 📊 **Nombre de notifications** par type
- 📊 **Taux de lecture** des notifications
- 📊 **Temps de réponse** des notifications
- 📊 **Erreurs de diffusion** Pusher

---

## 14. Prochaines Étapes

### Fonctionnalités Futures
- 🔄 **Notifications push** mobiles
- 🔄 **Templates** de notifications personnalisables
- 🔄 **Règles automatiques** de notification
- 🔄 **Analytics** des notifications
- 🔄 **Export** des données de notification

### Améliorations Techniques
- 🔄 **WebSockets** natifs (alternative à Pusher)
- 🔄 **Queue** pour les notifications différées
- 🔄 **Cache** intelligent des notifications
- 🔄 **Compression** des données

---

## Conclusion

Les nouvelles fonctionnalités avancées offrent :

1. **Gestion complète des congés** avec workflow d'approbation
2. **Système d'évaluations** avec signatures électroniques
3. **Notifications en temps réel** avec diffusion intelligente
4. **Sécurité et permissions** appropriées par rôle
5. **Performance optimisée** avec cache et indexation
6. **Monitoring et logs** pour le suivi des activités

L'application CRM est maintenant complète avec des fonctionnalités avancées de gestion des ressources humaines, d'évaluation des employés, et de notifications en temps réel pour une expérience utilisateur optimale.
