# Documentation - Création de Bon de Commande Fournisseur

## Vue d'ensemble

Ce document décrit tous les prérequis et les champs nécessaires pour créer un bon de commande fournisseur via l'API backend.

## Route API

**Endpoint :** `POST /api/bons-de-commande-create`

**Authentification :** Requise (Bearer Token via Sanctum)

**Autorisations :** Accessible aux rôles suivants :
- Commercial (role: 2)
- Comptable (role: 3)
- Admin (role: 1)
- Patron (role: 6)

## Champs requis

### Champs obligatoires

| Champ | Type | Description | Validation |
|-------|------|-------------|------------|
| `fournisseur_id` | integer | ID du fournisseur | Doit exister dans la table `fournisseurs` |
| `numero_commande` | string | Numéro unique du bon de commande | Doit être unique dans la table `bon_de_commandes` |
| `date_commande` | date | Date de la commande | Format: `YYYY-MM-DD` |

### Champs optionnels

| Champ | Type | Description | Validation |
|-------|------|-------------|------------|
| `date_livraison_prevue` | date | Date de livraison prévue | Doit être après `date_commande` si fournie |
| `montant_total` | numeric | Montant total du bon de commande | ≥ 0 |
| `description` | string | Description générale du bon de commande | - |
| `statut` | string | Statut initial du bon de commande | Valeurs possibles : `en_attente`, `valide`, `en_cours`, `livre`, `annule` (défaut: `en_attente`) |
| `commentaire` | string | Commentaire additionnel | - |
| `conditions_paiement` | string | Conditions de paiement | - |
| `delai_livraison` | integer | Délai de livraison en jours | ≥ 1 |

### Items (optionnel)

Le champ `items` permet de définir les articles de la commande. Si fourni, le montant total sera calculé automatiquement.

| Champ | Type | Description | Validation |
|-------|------|-------------|------------|
| `items` | array | Tableau d'articles | - |
| `items[].designation` | string | Désignation de l'article | **Obligatoire** si `items` est fourni |
| `items[].quantite` | integer | Quantité commandée | **Obligatoire** si `items` est fourni, ≥ 1 |
| `items[].prix_unitaire` | numeric | Prix unitaire de l'article | **Obligatoire** si `items` est fourni, ≥ 0 |
| `items[].ref` | string | Référence de l'article | Optionnel |
| `items[].description` | string | Description de l'article | Optionnel |

## Règles de validation importantes

1. **Montant total :**
   - Si `items` est fourni, le `montant_total` est calculé automatiquement à partir des items
   - Si aucun `items` n'est fourni, `montant_total` doit être fourni explicitement
   - Au moins l'un des deux (`montant_total` ou `items`) doit être fourni

2. **Numéro de commande :**
   - Doit être unique dans la base de données
   - Format recommandé : `BC-YYYY-NNNN` (ex: `BC-2025-0001`)

3. **Date de livraison prévue :**
   - Si fournie, doit être postérieure à la date de commande

## Exemple de requête JSON

### Exemple 1 : Avec items (recommandé)

```json
{
  "fournisseur_id": 2,
  "numero_commande": "BC-2025-0001",
  "date_commande": "2025-01-15",
  "date_livraison_prevue": "2025-01-30",
  "description": "Commande de matériel informatique",
  "statut": "en_attente",
  "commentaire": "Commande urgente",
  "conditions_paiement": "Paiement à 30 jours",
  "delai_livraison": 15,
  "items": [
    {
      "ref": "ORD-001",
      "designation": "Ordinateur portable HP EliteBook",
      "quantite": 5,
      "prix_unitaire": 1200.00,
      "description": "Intel Core i7, 16GB RAM, 512GB SSD"
    },
    {
      "ref": "SOU-002",
      "designation": "Souris sans fil",
      "quantite": 10,
      "prix_unitaire": 25.50,
      "description": "Souris ergonomique Bluetooth"
    }
  ]
}
```

### Exemple 2 : Sans items (avec montant_total)

```json
{
  "fournisseur_id": 3,
  "numero_commande": "BC-2025-0002",
  "date_commande": "2025-01-16",
  "date_livraison_prevue": "2025-02-01",
  "montant_total": 5000.00,
  "description": "Commande de fournitures de bureau",
  "statut": "en_attente",
  "conditions_paiement": "Paiement comptant",
  "delai_livraison": 10
}
```

### Exemple 3 : Minimal (champs obligatoires uniquement)

```json
{
  "fournisseur_id": 1,
  "numero_commande": "BC-2025-0003",
  "date_commande": "2025-01-17",
  "montant_total": 1500.00
}
```

## Réponse de succès

**Code HTTP :** `201 Created`

```json
{
  "success": true,
  "bon_de_commande": {
    "id": 1,
    "fournisseur_id": 2,
    "numero_commande": "BC-2025-0001",
    "date_commande": "2025-01-15",
    "date_livraison_prevue": "2025-01-30",
    "montant_total": "6105.00",
    "description": "Commande de matériel informatique",
    "statut": "en_attente",
    "commentaire": "Commande urgente",
    "conditions_paiement": "Paiement à 30 jours",
    "delai_livraison": 15,
    "user_id": 1,
    "created_at": "2025-01-15T10:30:00.000000Z",
    "updated_at": "2025-01-15T10:30:00.000000Z",
    "fournisseur": {
      "id": 2,
      "nom": "Fournisseur Informatique SARL",
      "email": "contact@fournisseur-info.com",
      "telephone": "+33 1 23 45 67 89"
    },
    "createur": {
      "id": 1,
      "nom": "Dupont",
      "prenom": "Jean"
    },
    "items": [
      {
        "id": 1,
        "bon_de_commande_id": 1,
        "ref": "ORD-001",
        "designation": "Ordinateur portable HP EliteBook",
        "quantite": 5,
        "prix_unitaire": "1200.00",
        "description": "Intel Core i7, 16GB RAM, 512GB SSD"
      },
      {
        "id": 2,
        "bon_de_commande_id": 1,
        "ref": "SOU-002",
        "designation": "Souris sans fil",
        "quantite": 10,
        "prix_unitaire": "25.50",
        "description": "Souris ergonomique Bluetooth"
      }
    ]
  },
  "message": "Bon de commande créé avec succès"
}
```

## Réponses d'erreur

### Erreur de validation (422)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "fournisseur_id": [
      "The fournisseur id field is required."
    ],
    "numero_commande": [
      "The numero commande has already been taken."
    ]
  }
}
```

### Erreur : Montant total manquant (422)

```json
{
  "success": false,
  "message": "Le montant total est requis ou des items doivent être fournis"
}
```

### Erreur : Fournisseur inexistant (422)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "fournisseur_id": [
      "The selected fournisseur id is invalid."
    ]
  }
}
```

### Erreur : Date de livraison invalide (422)

```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "date_livraison_prevue": [
      "The date livraison prevue must be a date after date commande."
    ]
  }
}
```

## Prérequis backend

### 1. Tables de base de données

Le système nécessite que les tables suivantes existent :

- `fournisseurs` : Table des fournisseurs
- `bon_de_commandes` : Table principale des bons de commande
- `bon_de_commande_items` : Table des articles des bons de commande
- `users` : Table des utilisateurs (pour le créateur)

### 2. Relations

- Un bon de commande appartient à un **fournisseur** (`fournisseur_id`)
- Un bon de commande appartient à un **utilisateur créateur** (`user_id`)
- Un bon de commande peut avoir plusieurs **items** (`bon_de_commande_items`)

### 3. Structure de la table `bon_de_commandes`

```sql
- id (bigint, primary key)
- fournisseur_id (bigint, foreign key -> fournisseurs.id)
- numero_commande (string, unique)
- date_commande (date)
- date_livraison_prevue (date, nullable)
- date_livraison (date, nullable)
- montant_total (decimal 10,2)
- description (text, nullable)
- statut (enum: en_attente, valide, en_cours, livre, annule)
- commentaire (text, nullable)
- conditions_paiement (text, nullable)
- delai_livraison (integer, nullable)
- date_validation (date, nullable)
- date_debut_traitement (date, nullable)
- date_annulation (date, nullable)
- user_id (bigint, foreign key -> users.id)
- created_at (timestamp)
- updated_at (timestamp)
```

### 4. Structure de la table `bon_de_commande_items`

```sql
- id (bigint, primary key)
- bon_de_commande_id (bigint, foreign key -> bon_de_commandes.id)
- ref (string, nullable)
- designation (string)
- quantite (integer)
- prix_unitaire (decimal 10,2)
- description (text, nullable)
- created_at (timestamp)
- updated_at (timestamp)
```

## Statuts possibles

| Statut | Description | Transitions possibles |
|--------|-------------|----------------------|
| `en_attente` | Bon de commande créé, en attente de validation | → `valide`, `annule` |
| `valide` | Bon de commande validé | → `en_cours`, `annule` |
| `en_cours` | Bon de commande en cours de traitement | → `livre`, `annule` |
| `livre` | Bon de commande livré | Aucune transition |
| `annule` | Bon de commande annulé | Aucune transition |

## Calcul automatique du montant total

Si des `items` sont fournis, le système calcule automatiquement le montant total :

```php
$montantTotal = 0;
foreach ($items as $item) {
    $montantTotal += ($item['quantite'] * $item['prix_unitaire']);
}
```

**Note :** Si `items` est fourni, la valeur de `montant_total` dans la requête est ignorée et remplacée par le calcul automatique.

## Exemple cURL

```bash
curl -X POST http://localhost:8000/api/bons-de-commande-create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "fournisseur_id": 2,
    "numero_commande": "BC-2025-0001",
    "date_commande": "2025-01-15",
    "date_livraison_prevue": "2025-01-30",
    "description": "Commande de matériel informatique",
    "statut": "en_attente",
    "items": [
      {
        "ref": "ORD-001",
        "designation": "Ordinateur portable",
        "quantite": 5,
        "prix_unitaire": 1200.00
      }
    ]
  }'
```

## Notes importantes

1. **Authentification requise :** Toutes les requêtes doivent inclure un token Bearer valide dans les en-têtes.

2. **User ID automatique :** Le champ `user_id` est automatiquement rempli avec l'ID de l'utilisateur authentifié. Il n'est pas nécessaire de le fournir dans la requête.

3. **Transaction :** La création du bon de commande et de ses items se fait dans une transaction. Si une erreur survient, toutes les modifications sont annulées.

4. **Unicité du numéro :** Le `numero_commande` doit être unique. Il est recommandé d'utiliser un format standardisé pour éviter les conflits.

5. **Calcul du montant :** Si vous fournissez à la fois `montant_total` et `items`, le montant calculé à partir des items prendra priorité.

## Checklist avant envoi

- [ ] Token d'authentification valide dans les en-têtes
- [ ] `fournisseur_id` existe dans la base de données
- [ ] `numero_commande` est unique
- [ ] `date_commande` est au format date valide
- [ ] Si `date_livraison_prevue` est fournie, elle est postérieure à `date_commande`
- [ ] Soit `montant_total` est fourni, soit `items` est fourni avec au moins un article
- [ ] Si `items` est fourni, chaque item a `designation`, `quantite` et `prix_unitaire`
- [ ] Les quantités sont ≥ 1
- [ ] Les prix sont ≥ 0

## Support

Pour toute question ou problème, contactez l'équipe de développement backend.

