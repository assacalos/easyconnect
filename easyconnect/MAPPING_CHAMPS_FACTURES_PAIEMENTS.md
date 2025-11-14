# Mapping des Champs Base de Données ↔ Frontend

## Problème

Les modèles frontend (`InvoiceModel` et `PaymentModel`) attendaient des noms de champs en anglais, alors que la base de données utilise des noms en français.

## Solution

Les modèles ont été mis à jour pour accepter les deux formats (français et anglais) pour une compatibilité maximale.

---

## Mapping Factures

### Champs Principaux

| Base de Données (FR) | Frontend (EN) | Supporté |
|---------------------|---------------|----------|
| `numero_facture` | `invoice_number` | ✅ Les deux |
| `date_facture` | `invoice_date` | ✅ Les deux |
| `date_echeance` | `due_date` | ✅ Les deux |
| `montant_ht` | `subtotal` | ✅ Les deux |
| `tva` | `tax_rate` / `tax_amount` | ✅ Les deux |
| `montant_ttc` | `total_amount` | ✅ Les deux |
| `client_id` | `client_id` | ✅ Identique |
| `user_id` | `commercial_id` (via `user_id`) | ✅ |
| `status` | `status` | ✅ Identique |
| `notes` | `notes` | ✅ Identique |
| `terms` | `terms` | ✅ Identique |
| `created_at` | `created_at` | ✅ Identique |
| `updated_at` | `updated_at` | ✅ Identique |

### Champs Items de Facture

| Base de Données (FR) | Frontend (EN) | Supporté |
|---------------------|---------------|----------|
| `facture_id` | `invoice_id` | ✅ |
| `description` | `description` | ✅ Identique |
| `quantity` | `quantity` | ✅ Identique |
| `unit_price` | `unit_price` | ✅ Identique |
| `total_price` | `total_price` | ✅ Identique |
| `unit` | `unit` | ✅ Identique |

---

## Mapping Paiements

### Champs Principaux

| Base de Données (FR) | Frontend (EN) | Supporté |
|---------------------|---------------|----------|
| `payment_number` | `payment_number` | ✅ Identique |
| `date_paiement` | `payment_date` | ✅ Les deux |
| `montant` | `amount` | ✅ Les deux |
| `type_paiement` | `payment_method` | ✅ Les deux |
| `client_id` | `client_id` | ✅ Identique |
| `client_name` | `client_name` | ✅ Identique |
| `client_email` | `client_email` | ✅ Identique |
| `client_address` | `client_address` | ✅ Identique |
| `comptable_id` | `comptable_id` | ✅ Identique |
| `comptable_name` | `comptable_name` | ✅ Identique |
| `status` | `status` | ✅ Identique |
| `description` / `commentaire` | `description` | ✅ Les deux |
| `reference` | `reference` | ✅ Identique |
| `validated_at` | `approved_at` | ✅ Les deux |
| `created_at` | `created_at` | ✅ Identique |
| `updated_at` | `updated_at` | ✅ Identique |

---

## Exemple de Données de la Base

### Facture

```json
{
  "id": 1,
  "client_id": 10,
  "numero_facture": "FAC-2025-0001",
  "date_facture": "2025-11-11",
  "date_echeance": "2025-12-11",
  "montant_ht": 200.00,
  "tva": 20.00,
  "montant_ttc": 240.00,
  "status": "en_attente",
  "type_paiement": null,
  "notes": null,
  "terms": null,
  "user_id": 3,
  "validated_by": null,
  "validated_at": null,
  "validation_comment": null,
  "rejected_by": null,
  "rejected_at": null,
  "rejection_reason": null,
  "rejection_comment": null,
  "created_at": "2025-11-11 14:56:36",
  "updated_at": "2025-11-11 14:56:36",
  "items": [
    {
      "id": 1,
      "facture_id": 1,
      "description": "A",
      "quantity": 1,
      "unit_price": 200.00,
      "total_price": 200.00,
      "unit": null
    }
  ]
}
```

### Paiement

```json
{
  "id": 1,
  "payment_number": "PAY202511110001",
  "type": "one_time",
  "facture_id": null,
  "client_id": 10,
  "client_name": "assa carlos",
  "client_email": "assaemmanuelcarlos@gmail.com",
  "client_address": "01BP20",
  "montant": 120.00,
  "currency": "FCFA",
  "date_paiement": "2025-11-11",
  "due_date": "2025-11-13",
  "type_paiement": "virement",
  "status": "draft",
  "reference": "aze12",
  "commentaire": null,
  "notes": null,
  "description": "aa",
  "user_id": 3,
  "comptable_id": 3,
  "comptable_name": "Miss",
  "validated_by": null,
  "validated_at": null,
  "validation_comment": null,
  "rejected_by": null,
  "rejected_at": null,
  "rejection_reason": null,
  "rejection_comment": null,
  "created_at": "2025-11-11 23:33:49",
  "updated_at": "2025-11-11 23:33:49",
  "submitted_at": null,
  "approved_at": null,
  "paid_at": null
}
```

---

## Format de Réponse Backend Attendu

### Pour `/api/factures-list`

Le backend doit retourner les factures avec leurs items inclus :

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "numero_facture": "FAC-2025-0001",
      "date_facture": "2025-11-11",
      "date_echeance": "2025-12-11",
      "montant_ht": 200.00,
      "tva": 20.00,
      "montant_ttc": 240.00,
      "status": "en_attente",
      "client_id": 10,
      "user_id": 3,
      "items": [
        {
          "id": 1,
          "facture_id": 1,
          "description": "A",
          "quantity": 1,
          "unit_price": 200.00,
          "total_price": 200.00
        }
      ],
      "created_at": "2025-11-11T14:56:36Z",
      "updated_at": "2025-11-11T14:56:36Z"
    }
  ],
  "message": "Liste des factures récupérée avec succès"
}
```

### Pour `/api/paiements-list`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "payment_number": "PAY202511110001",
      "type": "one_time",
      "client_id": 10,
      "client_name": "assa carlos",
      "client_email": "assaemmanuelcarlos@gmail.com",
      "client_address": "01BP20",
      "montant": 120.00,
      "currency": "FCFA",
      "date_paiement": "2025-11-11",
      "due_date": "2025-11-13",
      "type_paiement": "virement",
      "status": "draft",
      "reference": "aze12",
      "description": "aa",
      "comptable_id": 3,
      "comptable_name": "Miss",
      "created_at": "2025-11-11T23:33:49Z",
      "updated_at": "2025-11-11T23:33:49Z"
    }
  ],
  "message": "Liste des paiements récupérée avec succès"
}
```

---

## Modifications Frontend Effectuées

### InvoiceModel

- ✅ Support de `numero_facture` en plus de `invoice_number`
- ✅ Support de `date_facture` en plus de `invoice_date`
- ✅ Support de `date_echeance` en plus de `due_date`
- ✅ Support de `montant_ht` en plus de `subtotal`
- ✅ Support de `tva` en plus de `tax_rate` / `tax_amount`
- ✅ Support de `montant_ttc` en plus de `total_amount`
- ✅ Devise par défaut changée de `EUR` à `FCFA`

### PaymentModel

- ✅ Support de `date_paiement` en plus de `payment_date`
- ✅ Support de `montant` en plus de `amount`
- ✅ Support de `type_paiement` en plus de `payment_method`
- ✅ Support de `commentaire` en plus de `description`
- ✅ Support de `validated_at` en plus de `approved_at`

---

## Vérifications à Faire Côté Backend

1. **Inclure les items dans les factures** : La méthode `index` de `FactureController` doit charger les items avec `with('items')` ou équivalent.

2. **Format de dates** : Les dates doivent être retournées en format ISO 8601 (`2025-11-11T14:56:36Z`) ou au format standard (`2025-11-11`).

3. **Relations** : Inclure les relations nécessaires :
   - Pour les factures : `client`, `commercial` (via `user_id`), `items`
   - Pour les paiements : `client`, `comptable` (via `comptable_id`), `facture` (si `facture_id` est présent)

---

## Test de Compatibilité

Après les modifications, tester avec :

```bash
# Test Factures
curl -X GET "http://localhost:8000/api/factures-list" \
  -H "Authorization: Bearer {token}"

# Test Paiements
curl -X GET "http://localhost:8000/api/paiements-list" \
  -H "Authorization: Bearer {token}"
```

Les données devraient maintenant s'afficher correctement dans les pages de validation du Patron.


