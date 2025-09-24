# Architecture des Rôles - Application CRM

## Vue d'ensemble
L'application CRM utilise un système de rôles hiérarchique avec 6 rôles différents, chacun ayant des permissions spécifiques.

## Rôles et Permissions

### 1. Admin (Role: 1)
- **Accès complet** à toutes les fonctionnalités
- Peut gérer tous les utilisateurs
- Peut accéder à toutes les données
- Peut approuver/rejeter les clients
- Peut créer, modifier, supprimer des clients

### 2. Commercial (Role: 2)
- Peut créer de nouveaux clients
- Peut modifier ses propres clients (si statut = 'en_attente')
- Peut voir la liste des clients
- Peut voir les détails d'un client
- Ne peut pas approuver/rejeter les clients

### 3. Comptable (Role: 3)
- Accès aux données financières
- Peut gérer les factures et paiements
- Peut voir les rapports financiers
- Ne peut pas modifier les clients

### 4. RH (Role: 4)
- Gestion des ressources humaines
- Peut gérer les pointages
- Peut voir les rapports RH
- Accès limité aux données clients

### 5. Technicien (Role: 5)
- Gestion technique
- Peut gérer les interventions
- Peut voir les rapports techniques
- Accès limité aux données clients

### 6. Patron (Role: 6)
- Peut approuver/rejeter les clients
- Peut voir tous les rapports
- Peut gérer les validations importantes
- Accès en lecture à toutes les données

## Structure des Routes API

### Routes Publiques
- `POST /api/login` - Connexion utilisateur

### Routes Authentifiées (tous les rôles)
- `GET /api/me` - Informations utilisateur connecté
- `POST /api/logout` - Déconnexion
- `GET /api/list-clients` - Liste des clients
- `GET /api/clients-show/{id}` - Détails d'un client
- `GET /api/clients` - Liste filtrée des clients

### Routes Commercial + Admin
- `POST /api/clients` - Créer un client
- `POST /api/clients-update/{id}` - Modifier un client
- `GET /api/clients-destroy/{id}` - Supprimer un client

### Routes Patron + Admin
- `POST /api/clients/{id}/approve` - Approuver un client
- `POST /api/clients/{id}/reject` - Rejeter un client

### Routes Comptable + Admin
- Routes financières (à définir selon les besoins)

### Routes RH + Admin
- Routes RH (à définir selon les besoins)

### Routes Technicien + Admin
- Routes techniques (à définir selon les besoins)

### Routes Admin uniquement
- Routes d'administration (à définir selon les besoins)

## Middleware de Sécurité

### RoleMiddleware
- Vérifie l'authentification de l'utilisateur
- Contrôle l'accès basé sur le rôle
- Retourne des erreurs appropriées (401, 403)

### Utilisation
```php
Route::middleware(['role:1,2'])->group(function () {
    // Routes accessibles aux Admin et Commercial
});
```

## Modèle de Données

### Table Users
- `id` - Identifiant unique
- `nom` - Nom de famille
- `prenom` - Prénom
- `email` - Email (unique)
- `password` - Mot de passe hashé
- `role` - Rôle utilisateur (1-6)

### Table Clients
- `id` - Identifiant unique
- `user_id` - ID du commercial qui a créé le client
- `nom` - Nom du client
- `prenom` - Prénom du client
- `email` - Email du client
- `contact` - Numéro de téléphone
- `adresse` - Adresse du client
- `situation_geographique` - Localisation
- `nom_entreprise` - Nom de l'entreprise
- `statut` - Statut du client (en_attente, approved, rejected)
- `commentaire_rejet` - Commentaire en cas de rejet

## Sécurité

1. **Authentification** : Toutes les routes (sauf login) nécessitent un token valide
2. **Autorisation** : Contrôle d'accès basé sur les rôles
3. **Validation** : Validation des données d'entrée
4. **Tokens** : Utilisation de Laravel Sanctum pour les tokens API

## Exemples d'Utilisation

### Connexion
```bash
POST /api/login
{
    "email": "commercial@example.com",
    "password": "password"
}
```

### Création d'un client (Commercial)
```bash
POST /api/clients
Authorization: Bearer {token}
{
    "nom": "Dupont",
    "prenom": "Jean",
    "email": "jean.dupont@example.com",
    "contact": "0123456789",
    "adresse": "123 Rue de la Paix",
    "nom_entreprise": "Entreprise ABC",
    "situation_geographique": "Paris",
    "statut": "en_attente"
}
```

### Approbation d'un client (Patron)
```bash
POST /api/clients/1/approve
Authorization: Bearer {token}
```

### Rejet d'un client (Patron)
```bash
POST /api/clients/1/reject
Authorization: Bearer {token}
{
    "commentaire": "Informations incomplètes"
}
```
