# Implémentation Backend - Système de Pointage

## Vue d'ensemble

Le système de pointage avec géolocalisation et photos a été entièrement implémenté côté backend Laravel.

## Modifications apportées

### 🗄️ **Base de données**

#### Migration de la table `attendances`
- **Structure complète** : Géolocalisation, photos, validation
- **Colonnes ajoutées** :
  - `type` : 'check_in' ou 'check_out'
  - `timestamp` : Horodatage du pointage
  - `latitude` / `longitude` : Position GPS
  - `address` : Adresse textuelle
  - `accuracy` : Précision GPS
  - `photo_path` : Chemin de la photo
  - `notes` : Notes de l'employé
  - `status` : 'pending', 'approved', 'rejected'
  - `rejection_reason` : Raison du rejet
  - `approved_by` : ID de l'approbateur
  - `approved_at` : Date d'approbation

#### Index de performance
- `user_id + timestamp` : Recherche par utilisateur et date
- `status` : Filtrage par statut

### 🔧 **Contrôleur API**

#### Endpoints implémentés
- `POST /api/attendance/punch` : Enregistrer un pointage
- `GET /api/attendance/can-punch` : Vérifier si on peut pointer
- `GET /api/attendances` : Liste des pointages
- `GET /api/attendances/pending` : Pointages en attente
- `POST /api/attendances/{id}/approve` : Approuver un pointage
- `POST /api/attendances/{id}/reject` : Rejeter un pointage

#### Fonctionnalités
- **Upload de photos** : Stockage sécurisé dans `storage/app/public/attendances/`
- **Validation des données** : Coordonnées GPS, format photo, taille
- **Gestion des permissions** : Vérification des rôles pour validation
- **Logique métier** : Empêcher les pointages en double

### 📁 **Stockage des fichiers**

#### Configuration
- **Lien symbolique** : `php artisan storage:link`
- **Dossier** : `storage/app/public/attendances/{user_id}/`
- **Formats acceptés** : JPEG, PNG, JPG
- **Taille maximale** : 2MB

#### Sécurité
- **Noms uniques** : UUID pour éviter les conflits
- **Validation** : Vérification du type et de la taille
- **Permissions** : Accès restreint aux fichiers

### 🧪 **Données de test**

#### Utilisateur de test
- **Email** : `test@example.com`
- **Mot de passe** : `password`
- **Rôle** : Commercial (ID: 2)
- **ID** : 7

#### Pointages de test
- **4 pointages créés** : 2 approuvés, 2 en attente
- **Géolocalisation** : Paris, France (48.8566, 2.3522)
- **Photos** : Chemins de test configurés
- **Statuts** : Mélange d'approuvés et en attente

## API Endpoints

### 🔐 **Authentification requise**
Tous les endpoints nécessitent un token Bearer dans les headers :
```
Authorization: Bearer {token}
```

### 📝 **Enregistrer un pointage**
```http
POST /api/attendance/punch
Content-Type: multipart/form-data

type: check_in|check_out
latitude: 48.8566
longitude: 2.3522
address: Paris, France
accuracy: 10.0
photo: [fichier image]
notes: Notes optionnelles
```

**Réponse :**
```json
{
  "success": true,
  "message": "Pointage enregistré avec succès",
  "data": {
    "id": 1,
    "user_id": 7,
    "type": "check_in",
    "timestamp": "2025-09-27T08:00:00.000000Z",
    "latitude": 48.8566,
    "longitude": 2.3522,
    "address": "Paris, France",
    "accuracy": 10.0,
    "photo_path": "attendances/7/uuid.jpg",
    "notes": "Notes optionnelles",
    "status": "pending"
  }
}
```

### ✅ **Vérifier si on peut pointer**
```http
GET /api/attendance/can-punch?type=check_in
```

**Réponse :**
```json
{
  "success": true,
  "can_punch": true,
  "message": "Vous pouvez pointer"
}
```

### 📋 **Liste des pointages**
```http
GET /api/attendances
GET /api/attendances?status=pending
GET /api/attendances?type=check_in
GET /api/attendances?user_id=7
```

### ⏳ **Pointages en attente**
```http
GET /api/attendances/pending
```

### ✅ **Approuver un pointage**
```http
POST /api/attendances/{id}/approve
```

### ❌ **Rejeter un pointage**
```http
POST /api/attendances/{id}/reject
Content-Type: application/json

{
  "reason": "Raison du rejet"
}
```

## Modèle de données

### 📊 **Attendance Model**
```php
class Attendance extends Model
{
    protected $fillable = [
        'user_id', 'type', 'timestamp', 'latitude', 'longitude',
        'address', 'accuracy', 'photo_path', 'notes', 'status',
        'rejection_reason', 'approved_by', 'approved_at'
    ];

    // Relations
    public function user(): BelongsTo
    public function approver(): BelongsTo
    
    // Scopes
    public function scopePending($query)
    public function scopeApproved($query)
    public function scopeRejected($query)
    
    // Méthodes
    public function approve(User $approver): bool
    public function reject(User $approver, string $reason): bool
}
```

## Tests et validation

### ✅ **Tests effectués**
- **Migration** : Table créée avec succès
- **Stockage** : Lien symbolique configuré
- **API** : Endpoints répondent correctement
- **Données** : 4 pointages de test créés

### 🔍 **Vérifications**
- **Structure DB** : Toutes les colonnes présentes
- **Index** : Performance optimisée
- **Permissions** : Rôles respectés
- **Upload** : Photos stockées correctement

## Déploiement

### 🚀 **Étapes de déploiement**
1. **Migration** : `php artisan migrate`
2. **Stockage** : `php artisan storage:link`
3. **Permissions** : Vérifier les droits d'écriture
4. **Test** : Vérifier les endpoints API

### 🔧 **Configuration requise**
- **PHP** : 8.1+
- **Laravel** : 10.x
- **MySQL** : 8.0+
- **Extensions** : GD, Fileinfo
- **Stockage** : 100MB+ pour les photos

## Support

### 📚 **Documentation**
- Routes API : `php artisan route:list --path=attendance`
- Modèles : `app/Models/Attendance.php`
- Contrôleur : `app/Http/Controllers/API/AttendanceController.php`

### 🆘 **Dépannage**
- **Erreurs de migration** : Vérifier la structure DB
- **Upload échoué** : Vérifier les permissions de stockage
- **API non accessible** : Vérifier les routes et middleware

## Prochaines étapes

1. **Tests frontend** : Intégration avec Flutter
2. **Notifications** : Alertes pour les validations
3. **Rapports** : Statistiques et exports
4. **Sécurité** : Audit des accès et logs
