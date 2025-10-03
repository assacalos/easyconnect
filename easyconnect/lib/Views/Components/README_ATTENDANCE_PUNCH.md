# Système de Pointage avec Géolocalisation et Photos

## Vue d'ensemble

Ce système de pointage permet aux employés d'enregistrer leur arrivée et départ avec :
- **Géolocalisation** : Position GPS précise
- **Photo obligatoire** : Preuve visuelle du pointage
- **Notes optionnelles** : Commentaires de l'employé
- **Validation par le patron** : Approbation/rejet des pointages

## Fonctionnalités

### Pour les Employés
- Pointage d'arrivée et de départ
- Prise de photo obligatoire
- Géolocalisation automatique
- Ajout de notes optionnelles
- Vérification du statut de pointage

### Pour le Patron/RH
- Liste des pointages en attente
- Visualisation des photos et localisations
- Approbation ou rejet des pointages
- Filtrage par type (arrivée/départ)
- Historique complet

## Architecture

### Backend (Laravel)
- **Migration** : Table `attendances` avec géolocalisation et photos
- **Modèle** : `Attendance` avec relations et méthodes
- **Contrôleur** : `AttendanceController` avec upload de fichiers
- **Routes** : API RESTful pour toutes les opérations

### Frontend (Flutter)
- **Modèles** : `AttendancePunchModel` pour les données
- **Services** : 
  - `LocationService` : Géolocalisation
  - `CameraService` : Prise de photos
  - `AttendancePunchService` : API calls
- **Interfaces** :
  - `AttendancePunchPage` : Pointage employé
  - `AttendanceValidationPage` : Validation patron

## Utilisation

### Pointage Employé
```dart
// Navigation vers la page de pointage
Get.toNamed('/attendance-punch');
```

### Validation Patron
```dart
// Navigation vers la validation
Get.toNamed('/attendance-validation');
```

## Permissions Requises

### Android
- `ACCESS_FINE_LOCATION` : Localisation précise
- `ACCESS_COARSE_LOCATION` : Localisation approximative
- `CAMERA` : Accès à la caméra
- `WRITE_EXTERNAL_STORAGE` : Stockage des photos
- `READ_EXTERNAL_STORAGE` : Lecture des photos

### Flutter Dependencies
- `geolocator` : Géolocalisation
- `geocoding` : Adresses
- `image_picker` : Photos
- `permission_handler` : Gestion des permissions

## API Endpoints

### Pointage
- `POST /api/attendance/punch` : Enregistrer un pointage
- `GET /api/attendance/can-punch` : Vérifier si on peut pointer

### Gestion
- `GET /api/attendances` : Liste des pointages
- `GET /api/attendances/pending` : Pointages en attente
- `POST /api/attendances/{id}/approve` : Approuver
- `POST /api/attendances/{id}/reject` : Rejeter

## Sécurité

- Authentification requise pour tous les endpoints
- Validation des permissions par rôle
- Upload sécurisé des photos
- Vérification de la géolocalisation

## Workflow

1. **Employé** : Prend une photo et pointe
2. **Système** : Enregistre avec géolocalisation
3. **Patron** : Reçoit notification de validation
4. **Patron** : Approuve ou rejette le pointage
5. **Employé** : Reçoit confirmation du statut

## Configuration

### Backend
1. Exécuter la migration : `php artisan migrate`
2. Configurer le stockage des photos
3. Définir les permissions par rôle

### Frontend
1. Ajouter les permissions Android
2. Installer les dépendances : `flutter pub get`
3. Configurer les services de localisation

## Dépannage

### Problèmes de Localisation
- Vérifier les permissions GPS
- Activer la localisation sur l'appareil
- Vérifier la précision requise

### Problèmes de Caméra
- Vérifier les permissions caméra
- Tester avec différents formats d'image
- Vérifier la taille des fichiers

### Problèmes de Réseau
- Vérifier la connectivité API
- Tester les timeouts
- Vérifier les headers d'authentification
