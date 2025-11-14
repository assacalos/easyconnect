# Routes API - Bons de Commande Fournisseur

## Vue d'ensemble

Toutes les routes pour la gestion des bons de commande fournisseur. Toutes les routes nécessitent une authentification via Sanctum (Bearer Token).

**Base URL :** `/api`

---

## Routes disponibles

### 1. Consultation d'un bon de commande

**Route :** `GET /api/bons-de-commande-show/{id}`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Récupère les détails d'un bon de commande spécifique avec ses relations (fournisseur, créateur, items).

**Paramètres :**
- `{id}` : ID du bon de commande

**Exemple de réponse :**
```json
{
  "success": true,
  "bon_de_commande": {
    "id": 1,
    "fournisseur_id": 2,
    "numero_commande": "BC-2025-0001",
    "date_commande": "2025-01-15",
    "montant_total": "6105.00",
    "statut": "en_attente",
    "fournisseur": {...},
    "createur": {...},
    "items": [...]
  },
  "message": "Bon de commande récupéré avec succès"
}
```

---

### 2. Création d'un bon de commande

**Route :** `POST /api/bons-de-commande-create`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Crée un nouveau bon de commande fournisseur.

**Corps de la requête :**
```json
{
  "fournisseur_id": 2,
  "numero_commande": "BC-2025-0001",
  "date_commande": "2025-01-15",
  "date_livraison_prevue": "2025-01-30",
  "description": "Commande de matériel",
  "statut": "en_attente",
  "items": [
    {
      "designation": "Article 1",
      "quantite": 5,
      "prix_unitaire": 100.00
    }
  ]
}
```

**Réponse :** `201 Created`

---

### 3. Modification d'un bon de commande

**Route :** `PUT /api/bons-de-commande-update/{id}`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Modifie un bon de commande existant. Ne peut être modifié que si le statut est `en_attente`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Corps de la requête :** (Tous les champs sont optionnels)
```json
{
  "numero_commande": "BC-2025-0001",
  "date_commande": "2025-01-15",
  "description": "Description mise à jour",
  "items": [...]
}
```

---

### 4. Validation d'un bon de commande

**Route :** `POST /api/bons-de-commande-validate/{id}`

**Autorisations :** 
- Commercial (2), Comptable (3), Admin (1), Patron (6) - pour valider
- Admin (1), Patron (6) - pour valider/rejeter (route dupliquée)

**Description :** Valide un bon de commande. Change le statut de `en_attente` à `valide`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Réponse :**
```json
{
  "success": true,
  "bon_de_commande": {...},
  "message": "Bon de commande validé avec succès"
}
```

---

### 5. Rejet d'un bon de commande

**Route :** `POST /api/bons-de-commande-reject/{id}`

**Autorisations :** Admin (1), Patron (6)

**Description :** Rejette un bon de commande.

**Paramètres :**
- `{id}` : ID du bon de commande

---

### 6. Marquer comme en cours

**Route :** `POST /api/mark-in-progress-bons-de-commande/{id}`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Marque un bon de commande comme étant en cours de traitement. Le statut doit être `valide` avant de pouvoir être marqué comme `en_cours`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Réponse :**
```json
{
  "success": true,
  "bon_de_commande": {...},
  "message": "Bon de commande marqué comme en cours"
}
```

---

### 7. Marquer comme livré

**Route :** `POST /api/bons-de-commande-mark-delivered/{id}`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Marque un bon de commande comme livré. Le statut doit être `en_cours` avant de pouvoir être marqué comme `livre`.

**Paramètres :**
- `{id}` : ID du bon de commande

**Réponse :**
```json
{
  "success": true,
  "bon_de_commande": {...},
  "message": "Bon de commande marqué comme livré"
}
```

---

### 8. Annuler un bon de commande

**Route :** `POST /api/bons-de-commande-cancel/{id}`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Annule un bon de commande. Ne peut pas être annulé si déjà livré ou déjà annulé.

**Paramètres :**
- `{id}` : ID du bon de commande

**Corps de la requête :**
```json
{
  "commentaire": "Raison de l'annulation"
}
```

**Réponse :**
```json
{
  "success": true,
  "bon_de_commande": {...},
  "message": "Bon de commande annulé avec succès"
}
```

---

### 9. Rapports des bons de commande

**Route :** `GET /api/bons-de-commande-reports`

**Autorisations :** Commercial (2), Comptable (3), Admin (1), Patron (6)

**Description :** Génère un rapport détaillé des bons de commande avec statistiques par statut et par fournisseur.

**Paramètres de requête (optionnels) :**
- `date_debut` : Date de début pour filtrer
- `date_fin` : Date de fin pour filtrer

**Exemple de réponse :**
```json
{
  "success": true,
  "rapport": {
    "total_bons": 50,
    "montant_total": 150000.00,
    "bons_en_attente": 10,
    "montant_en_attente": 30000.00,
    "bons_valides": 15,
    "montant_valide": 45000.00,
    "bons_en_cours": 20,
    "montant_en_cours": 60000.00,
    "bons_livres": 5,
    "montant_livre": 15000.00,
    "par_fournisseur": {...}
  },
  "message": "Rapport de bons de commande généré avec succès"
}
```

---

## Récapitulatif des routes

| Méthode | Route | Autorisations | Description |
|---------|-------|--------------|-------------|
| `GET` | `/api/bons-de-commande-show/{id}` | 1,2,3,6 | Consulter un bon de commande |
| `POST` | `/api/bons-de-commande-create` | 1,2,3,6 | Créer un bon de commande |
| `PUT` | `/api/bons-de-commande-update/{id}` | 1,2,3,6 | Modifier un bon de commande |
| `POST` | `/api/bons-de-commande-validate/{id}` | 1,2,3,6 | Valider un bon de commande |
| `POST` | `/api/bons-de-commande-reject/{id}` | 1,6 | Rejeter un bon de commande |
| `POST` | `/api/mark-in-progress-bons-de-commande/{id}` | 1,2,3,6 | Marquer comme en cours |
| `POST` | `/api/bons-de-commande-mark-delivered/{id}` | 1,2,3,6 | Marquer comme livré |
| `POST` | `/api/bons-de-commande-cancel/{id}` | 1,2,3,6 | Annuler un bon de commande |
| `GET` | `/api/bons-de-commande-reports` | 1,2,3,6 | Générer un rapport |

## Codes de rôles

- **1** : Admin
- **2** : Commercial
- **3** : Comptable
- **4** : RH
- **5** : Technicien
- **6** : Patron

## Statuts possibles

- `en_attente` : Bon de commande créé, en attente de validation
- `valide` : Bon de commande validé
- `en_cours` : Bon de commande en cours de traitement
- `livre` : Bon de commande livré
- `annule` : Bon de commande annulé

## Transitions de statut

```
en_attente → valide → en_cours → livre
     ↓           ↓         ↓
  annule     annule    annule
```

## Authentification

Toutes les routes nécessitent un token Bearer dans les en-têtes :

```
Authorization: Bearer {votre_token}
```

## Exemple d'utilisation avec cURL

### Créer un bon de commande

```bash
curl -X POST http://localhost:8000/api/bons-de-commande-create \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "fournisseur_id": 2,
    "numero_commande": "BC-2025-0001",
    "date_commande": "2025-01-15",
    "items": [
      {
        "designation": "Article 1",
        "quantite": 5,
        "prix_unitaire": 100.00
      }
    ]
  }'
```

### Consulter un bon de commande

```bash
curl -X GET http://localhost:8000/api/bons-de-commande-show/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Valider un bon de commande

```bash
curl -X POST http://localhost:8000/api/bons-de-commande-validate/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Marquer comme livré

```bash
curl -X POST http://localhost:8000/api/bons-de-commande-mark-delivered/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Notes importantes

1. **Modification :** Un bon de commande ne peut être modifié que si son statut est `en_attente`.

2. **Validation :** Un bon de commande doit être `valide` avant de pouvoir être marqué comme `en_cours`.

3. **Livraison :** Un bon de commande doit être `en_cours` avant de pouvoir être marqué comme `livre`.

4. **Annulation :** Un bon de commande ne peut pas être annulé s'il est déjà `livre` ou `annule`.

5. **User ID :** Le champ `user_id` (créateur) est automatiquement rempli avec l'ID de l'utilisateur authentifié lors de la création.

