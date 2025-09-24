# Documentation des Contrôleurs API - Application CRM

## Vue d'ensemble
Cette documentation présente tous les contrôleurs API créés pour l'application CRM avec leurs fonctionnalités et permissions par rôle.

## Contrôleurs Disponibles

### 1. UserController
**Gestion de l'authentification et des utilisateurs**

#### Routes
- `POST /api/login` - Connexion utilisateur
- `POST /api/logout` - Déconnexion (authentifié)
- `GET /api/me` - Informations utilisateur connecté (authentifié)

#### Fonctionnalités
- Authentification avec validation des données
- Génération de tokens API
- Gestion des sessions utilisateur
- Informations de profil utilisateur

---

### 2. ClientController
**Gestion des clients**

#### Routes
- `GET /api/list-clients` - Liste des clients (authentifié)
- `GET /api/clients-show/{id}` - Détails d'un client (authentifié)
- `GET /api/clients` - Liste filtrée des clients (authentifié)
- `POST /api/clients` - Créer un client (Commercial + Admin)
- `POST /api/clients-update/{id}` - Modifier un client (Commercial + Admin)
- `GET /api/clients-destroy/{id}` - Supprimer un client (Commercial + Admin)
- `POST /api/clients/{id}/approve` - Approuver un client (Patron + Admin)
- `POST /api/clients/{id}/reject` - Rejeter un client (Patron + Admin)

#### Fonctionnalités
- CRUD complet des clients
- Validation des statuts (en_attente, approved, rejected)
- Filtrage par commercial
- Workflow d'approbation

---

### 3. FactureController
**Gestion des factures**

#### Routes
- `GET /api/factures` - Liste des factures (Comptable + Admin)
- `GET /api/factures/{id}` - Détails d'une facture (Comptable + Admin)
- `POST /api/factures` - Créer une facture (Comptable + Admin)
- `PUT /api/factures/{id}` - Modifier une facture (Comptable + Admin)
- `POST /api/factures/{id}/mark-paid` - Marquer comme payée (Comptable + Admin)
- `DELETE /api/factures/{id}` - Supprimer une facture (Admin uniquement)
- `GET /api/factures-reports` - Rapports financiers (Comptable + Patron + Admin)

#### Fonctionnalités
- CRUD des factures
- Gestion des statuts (en_attente, payee, impayee)
- Rapports financiers détaillés
- Filtrage par période et statut

---

### 4. PaiementController
**Gestion des paiements**

#### Routes
- `GET /api/paiements` - Liste des paiements (Comptable + Admin)
- `GET /api/paiements/{id}` - Détails d'un paiement (Comptable + Admin)
- `POST /api/paiements` - Créer un paiement (Comptable + Admin)
- `PUT /api/paiements/{id}` - Modifier un paiement (Comptable + Admin)
- `POST /api/paiements/{id}/validate` - Valider un paiement (Comptable + Admin)
- `POST /api/paiements/{id}/reject` - Rejeter un paiement (Comptable + Admin)
- `DELETE /api/paiements/{id}` - Supprimer un paiement (Admin uniquement)
- `GET /api/paiements-reports` - Rapports de paiements (Comptable + Patron + Admin)

#### Fonctionnalités
- CRUD des paiements
- Validation/rejet des paiements
- Modes de paiement multiples (espèces, chèque, virement, carte)
- Rapports détaillés par mode de paiement

---

### 5. PointageController
**Gestion des pointages**

#### Routes
- `GET /api/pointages` - Liste des pointages (RH + Admin)
- `GET /api/pointages/{id}` - Détails d'un pointage (RH + Admin)
- `POST /api/pointages` - Créer un pointage (Technicien + RH + Admin)
- `PUT /api/pointages/{id}` - Modifier un pointage (RH + Admin)
- `POST /api/pointages/{id}/validate` - Valider un pointage (RH + Patron + Admin)
- `POST /api/pointages/{id}/reject` - Rejeter un pointage (RH + Patron + Admin)
- `DELETE /api/pointages/{id}` - Supprimer un pointage (Admin uniquement)
- `GET /api/pointages-reports` - Rapports de pointages (RH + Patron + Admin)
- `POST /api/pointages/arrivee` - Pointer l'arrivée (Technicien + Admin)
- `POST /api/pointages/depart` - Pointer le départ (Technicien + Admin)
- `GET /api/pointages/today` - Pointages d'aujourd'hui (authentifié)

#### Fonctionnalités
- Gestion des pointages d'arrivée/départ
- Types de pointage (arrivée, départ, pause)
- Validation/rejet par les RH
- Rapports de présence
- Pointage automatique avec validation

---

### 6. BordereauController
**Gestion des bordereaux**

#### Routes
- `GET /api/bordereaux` - Liste des bordereaux (Comptable + Admin)
- `GET /api/bordereaux/{id}` - Détails d'un bordereau (Comptable + Admin)
- `POST /api/bordereaux` - Créer un bordereau (Comptable + Admin)
- `PUT /api/bordereaux/{id}` - Modifier un bordereau (Comptable + Admin)
- `POST /api/bordereaux/{id}/validate` - Valider un bordereau (Comptable + Patron + Admin)
- `POST /api/bordereaux/{id}/reject` - Rejeter un bordereau (Comptable + Patron + Admin)
- `POST /api/bordereaux/{id}/add-facture` - Ajouter une facture (Comptable + Admin)
- `POST /api/bordereaux/{id}/remove-facture` - Retirer une facture (Comptable + Admin)
- `DELETE /api/bordereaux/{id}` - Supprimer un bordereau (Admin uniquement)
- `GET /api/bordereaux-reports` - Rapports de bordereaux (Comptable + Patron + Admin)

#### Fonctionnalités
- CRUD des bordereaux
- Gestion des factures associées
- Validation/rejet des bordereaux
- Calcul automatique des montants
- Rapports détaillés

---

### 7. BonDeCommandeController
**Gestion des bons de commande**

#### Routes
- `GET /api/bons-de-commande` - Liste des bons de commande (Commercial + Comptable + Admin)
- `GET /api/bons-de-commande/{id}` - Détails d'un bon de commande (Commercial + Comptable + Admin)
- `POST /api/bons-de-commande` - Créer un bon de commande (Commercial + Comptable + Admin)
- `PUT /api/bons-de-commande/{id}` - Modifier un bon de commande (Commercial + Comptable + Admin)
- `POST /api/bons-de-commande/{id}/validate` - Valider un bon de commande (Comptable + Patron + Admin)
- `POST /api/bons-de-commande/{id}/mark-in-progress` - Marquer en cours (Comptable + Patron + Admin)
- `POST /api/bons-de-commande/{id}/mark-delivered` - Marquer comme livré (Comptable + Patron + Admin)
- `POST /api/bons-de-commande/{id}/cancel` - Annuler un bon de commande (Comptable + Patron + Admin)
- `DELETE /api/bons-de-commande/{id}` - Supprimer un bon de commande (Admin uniquement)
- `GET /api/bons-de-commande-reports` - Rapports de bons de commande (Commercial + Comptable + Patron + Admin)

#### Fonctionnalités
- CRUD des bons de commande
- Workflow complet (en_attente → validé → en_cours → livré)
- Gestion des fournisseurs
- Conditions de paiement
- Rapports par client et fournisseur

---

### 8. FournisseurController
**Gestion des fournisseurs**

#### Routes
- `GET /api/fournisseurs` - Liste des fournisseurs (Comptable + Admin)
- `GET /api/fournisseurs/{id}` - Détails d'un fournisseur (Comptable + Admin)
- `POST /api/fournisseurs` - Créer un fournisseur (Comptable + Admin)
- `PUT /api/fournisseurs/{id}` - Modifier un fournisseur (Comptable + Admin)
- `POST /api/fournisseurs/{id}/activate` - Activer un fournisseur (Comptable + Patron + Admin)
- `POST /api/fournisseurs/{id}/deactivate` - Désactiver un fournisseur (Comptable + Patron + Admin)
- `POST /api/fournisseurs/{id}/suspend` - Suspendre un fournisseur (Patron + Admin)
- `GET /api/fournisseurs/{id}/statistics` - Statistiques d'un fournisseur (Comptable + Patron + Admin)
- `DELETE /api/fournisseurs/{id}` - Supprimer un fournisseur (Admin uniquement)
- `GET /api/fournisseurs-reports` - Rapports de fournisseurs (Comptable + Patron + Admin)

#### Fonctionnalités
- CRUD des fournisseurs
- Gestion des statuts (actif, inactif, suspendu)
- Informations de contact complètes
- Statistiques de commandes
- Rapports géographiques

---

### 9. ReportingController
**Rapports et tableaux de bord**

#### Routes
- `GET /api/dashboard` - Tableau de bord général (Patron + Admin)
- `GET /api/reports/financial` - Rapports financiers (Comptable + Patron + Admin)
- `GET /api/reports/hr` - Rapports RH (RH + Patron + Admin)
- `GET /api/reports/commercial` - Rapports commerciaux (Commercial + Patron + Admin)

#### Fonctionnalités
- Tableau de bord avec KPIs
- Rapports financiers détaillés
- Statistiques RH et pointages
- Analyses commerciales
- Évolutions temporelles

---

## Permissions par Rôle

### Admin (Role: 1)
- **Accès complet** à toutes les fonctionnalités
- Peut supprimer toutes les entités
- Accès à tous les rapports

### Commercial (Role: 2)
- Gestion des clients (CRUD)
- Gestion des bons de commande (CRUD)
- Rapports commerciaux
- Accès limité aux autres données

### Comptable (Role: 3)
- Gestion financière complète
- Factures, paiements, bordereaux
- Gestion des fournisseurs
- Rapports financiers
- Validation des bons de commande

### RH (Role: 4)
- Gestion des pointages
- Validation des pointages
- Rapports RH
- Accès limité aux autres données

### Technicien (Role: 5)
- Pointage personnel (arrivée/départ)
- Consultation de ses pointages
- Accès limité aux autres données

### Patron (Role: 6)
- Validation des clients
- Accès à tous les rapports
- Validation des pointages
- Gestion des fournisseurs
- Tableau de bord complet

---

## Exemples d'Utilisation

### Connexion et Authentification
```bash
# Connexion
curl -X POST http://localhost:8000/api/login \
  -H "Content-Type: application/json" \
  -d '{"email": "commercial@example.com", "password": "password"}'

# Informations utilisateur
curl -X GET http://localhost:8000/api/me \
  -H "Authorization: Bearer {token}"
```

### Gestion des Clients
```bash
# Créer un client
curl -X POST http://localhost:8000/api/clients \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{
    "nom": "Dupont",
    "prenom": "Jean",
    "email": "jean.dupont@example.com",
    "contact": "0123456789",
    "adresse": "123 Rue de la Paix",
    "nom_entreprise": "Entreprise ABC",
    "situation_geographique": "Paris",
    "statut": "en_attente"
  }'

# Approuver un client (Patron)
curl -X POST http://localhost:8000/api/clients/1/approve \
  -H "Authorization: Bearer {token}"
```

### Gestion des Pointages
```bash
# Pointer l'arrivée
curl -X POST http://localhost:8000/api/pointages/arrivee \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"lieu": "Bureau principal", "commentaire": "Arrivée normale"}'

# Pointer le départ
curl -X POST http://localhost:8000/api/pointages/depart \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {token}" \
  -d '{"commentaire": "Fin de journée"}'
```

### Rapports
```bash
# Tableau de bord
curl -X GET "http://localhost:8000/api/dashboard?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer {token}"

# Rapport financier
curl -X GET "http://localhost:8000/api/reports/financial?date_debut=2024-01-01&date_fin=2024-12-31" \
  -H "Authorization: Bearer {token}"
```

---

## Sécurité

### Authentification
- Toutes les routes (sauf login) nécessitent un token valide
- Utilisation de Laravel Sanctum pour les tokens API
- Gestion des sessions utilisateur

### Autorisation
- Contrôle d'accès basé sur les rôles
- Middleware de permissions personnalisé
- Validation des données d'entrée

### Validation
- Validation des données d'entrée sur tous les endpoints
- Messages d'erreur explicites
- Contrôles de cohérence métier

---

## Structure des Réponses

### Réponse de Succès
```json
{
  "success": true,
  "data": {...},
  "message": "Opération réussie"
}
```

### Réponse d'Erreur
```json
{
  "success": false,
  "message": "Message d'erreur",
  "errors": {...}
}
```

### Codes de Statut
- `200` - Succès
- `201` - Création réussie
- `400` - Erreur de validation
- `401` - Non authentifié
- `403` - Accès refusé
- `404` - Ressource non trouvée
- `500` - Erreur serveur
