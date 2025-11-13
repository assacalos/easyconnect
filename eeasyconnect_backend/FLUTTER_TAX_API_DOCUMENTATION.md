# Documentation API Taxes et Impôts - Format Flutter

## 📋 Champs Requis pour Créer une Taxe/Impôt

Flutter doit envoyer les données suivantes à l'endpoint `POST /api/taxes-create` :

### ✅ Champs OBLIGATOIRES (Minimum requis)

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `category` | string | - | Nom de la catégorie de taxe (sélection depuis la liste) | `"TVA"`, `"Impôt sur le Revenu"` |
| `baseAmount` | double/float | - | Montant de base pour le calcul de la taxe (en FCFA) | `1000000.0` |
| `period` | string | "YYYY-MM" | Période de la taxe | `"2024-01"` |
| `periodStart` | string | "YYYY-MM-DD" | Date de début de la période | `"2024-01-01"` |
| `periodEnd` | string | "YYYY-MM-DD" | Date de fin de la période | `"2024-01-31"` |
| `dueDate` | string | "YYYY-MM-DD" | Date d'échéance de paiement | `"2024-02-15"` |

### ⚪ Champs OPTIONNELS

| Champ Flutter | Type | Format | Description | Exemple |
|--------------|------|--------|-------------|---------|
| `reference` | string | - | Référence unique (générée automatiquement si non fournie) | `"TVA-2024-01-001"` |
| `description` | string | - | Description de la taxe | `"TVA janvier 2024"` |
| `notes` | string | - | Notes internes | `"Notes importantes"` |
| `taxRate` | double/float | - | Taux de taxe (sera utilisé si différent de la catégorie) | `20.0` |
| `taxAmount` | double/float | - | Montant de la taxe (sera calculé si non fourni) | `200000.0` |
| `totalAmount` | double/float | - | Montant total (sera calculé si non fourni) | `1200000.0` |

---

## 📤 Format JSON à Envoyer (Exemple)

### Format Minimal (Requis uniquement)

```json
{
  "category": "TVA",
  "baseAmount": 1000000.0,
  "period": "2024-01",
  "periodStart": "2024-01-01",
  "periodEnd": "2024-01-31",
  "dueDate": "2024-02-15"
}
```

### Format Complet (Avec tous les champs)

```json
{
  "category": "TVA",
  "comptableId": 2,
  "reference": "TVA-2024-01-001",
  "period": "2024-01",
  "periodStart": "2024-01-01",
  "periodEnd": "2024-01-31",
  "dueDate": "2024-02-15",
  "baseAmount": 1000000.0,
  "taxRate": 20.0,
  "taxAmount": 200000.0,
  "totalAmount": 1200000.0,
  "description": "TVA janvier 2024 sur les ventes",
  "notes": "Taxe calculée sur les factures du mois de janvier"
}
```

### Format Simplifié avec Month/Year (Alternative - si supporté par le backend)

Si le backend génère automatiquement les dates depuis `month` et `year` :

```json
{
  "category": "TVA",
  "baseAmount": 1000000.0,
  "month": "01",
  "year": 2024,
  "dueDate": "2024-02-15"
}
```

---

## 🔄 Normalisation Automatique du Backend

Le backend convertit automatiquement les champs camelCase vers snake_case :

- `category` → `category` (déjà en snake_case)
- `comptableId` → `comptable_id`
- `baseAmount` → `base_amount`
- `taxRate` → `tax_rate`
- `taxAmount` → `tax_amount`
- `totalAmount` → `total_amount`
- `periodStart` → `period_start`
- `periodEnd` → `period_end`
- `dueDate` → `due_date`

**Note :** Vous pouvez aussi envoyer les champs en snake_case (`tax_category_id`, etc.), les deux formats sont acceptés.

---

## 📥 Format de Réponse (Success)

### Status Code : `201 Created`

```json
{
  "success": true,
  "message": "Taxe créée avec succès",
  "data": {
    "id": 1,
    "category": "TVA",
    "comptable_id": 2,
    "comptable": {
      "id": 2,
      "nom": "Dupont",
      "prenom": "Jean"
    },
    "reference": "TVA-2024-01-001",
    "period": "2024-01",
    "period_start": "2024-01-01",
    "period_end": "2024-01-31",
    "due_date": "2024-02-15",
    "base_amount": 1000000.0,
    "tax_rate": 20.0,
    "tax_amount": 200000.0,
    "total_amount": 1200000.0,
    "status": "en_attente",
    "description": "TVA janvier 2024",
    "notes": null,
    "calculation_details": null,
    "declared_at": null,
    "paid_at": null,
    "validated_by": null,
    "validated_at": null,
    "validation_comment": null,
    "rejected_by": null,
    "rejected_at": null,
    "rejection_reason": null,
    "rejection_comment": null,
    "created_at": "2024-11-02 14:00:00",
    "updated_at": "2024-11-02 14:00:00"
  }
}
```

---

## 📊 Statuts des Taxes

Les statuts possibles pour une taxe sont **UNIQUEMENT** les 4 suivants :

| Status Backend | Status Flutter (Recommandé) | Description |
|----------------|----------------------------|-------------|
| `en_attente` | `pending` ou `en_attente` | En attente de validation (statut par défaut à la création) |
| `valide` | `approved` ou `validated` | Validée par le patron/admin |
| `rejete` | `rejected` ou `rejete` | Rejetée |
| `paye` | `paid` ou `paye` | Payée |

**Note importante :** Une taxe ne peut être payée que si elle est validée (`valide`).

---

## 🔍 Validation des Champs

### `category`
- **Requis** : Oui
- **Type** : String
- **Valeur** : Nom de la catégorie (ex: "TVA", "Impôt sur le Revenu")
- **Exemple** : `"TVA"`, `"Impôt sur le Revenu"`
- **Note** : Utilisez `/api/tax-categories` pour obtenir la liste des catégories disponibles et sélectionner le `name`

### `baseAmount` / `base_amount`
- **Requis** : Oui
- **Type** : Nombre (double/float)
- **Min** : 0
- **Description** : Montant de base sur lequel la taxe sera calculée
- **Exemple** : `1000000.0`

### `period` / `periodStart` + `periodEnd`
- **Requis** : Oui (`period` OU `periodStart` + `periodEnd`)
- **Type** : String (dates)
- **Format `period`** : "YYYY-MM" (ex: "2024-01")
- **Format `periodStart`** : "YYYY-MM-DD" (ex: "2024-01-01")
- **Format `periodEnd`** : "YYYY-MM-DD" (ex: "2024-01-31")

### `dueDate`
- **Requis** : Oui
- **Type** : String (date)
- **Format** : "YYYY-MM-DD"
- **Description** : Date d'échéance de paiement de la taxe
- **Exemple** : `"2024-02-15"`

### `reference`
- **Requis** : Non (générée automatiquement)
- **Type** : String
- **Format** : Généré depuis la catégorie et la période (ex: "TVA-2024-01-001")
- **Note** : Si fournie, doit être unique

### `taxRate` / `tax_rate`
- **Requis** : Non
- **Type** : Nombre (double/float)
- **Description** : Taux de taxe (si différent de celui de la catégorie)
- **Exemple** : `20.0` pour 20%

### `taxAmount` / `tax_amount`
- **Requis** : Non (calculé automatiquement)
- **Type** : Nombre (double/float)
- **Description** : Montant de la taxe calculé
- **Note** : Sera recalculé lors de l'appel à `/taxes/{id}/calculate`

### `totalAmount` / `total_amount`
- **Requis** : Non (calculé automatiquement)
- **Type** : Nombre (double/float)
- **Description** : Montant total (base_amount + tax_amount)

### `description`
- **Requis** : Non
- **Type** : String
- **Max** : 255 caractères
- **Exemple** : `"TVA janvier 2024 sur les ventes"`

### `notes`
- **Requis** : Non
- **Type** : String (TEXT)
- **Description** : Notes internes
- **Exemple** : `"Notes importantes sur cette taxe"`

---

## 📝 Exemples de Code Flutter

### Exemple 1 : Création Simple

```dart
final tax = Tax(
  category: "TVA",
  baseAmount: 1000000.0,
  period: "2024-01",
  periodStart: "2024-01-01",
  periodEnd: "2024-01-31",
  dueDate: "2024-02-15",
);

final result = await taxService.createTax(tax);
```

### Exemple 2 : Création avec Tous les Champs

```dart
final tax = Tax(
  category: "TVA",
  comptableId: 2,
  baseAmount: 1000000.0,
  taxRate: 20.0,
  period: "2024-01",
  periodStart: "2024-01-01",
  periodEnd: "2024-01-31",
  dueDate: "2024-02-15",
  description: "TVA janvier 2024",
  notes: "Taxe sur les ventes du mois de janvier",
);

final result = await taxService.createTax(tax);
```

### Exemple 3 : Envoi Direct via HTTP

```dart
final response = await http.post(
  Uri.parse('$baseUrl/taxes-create'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: json.encode({
    'category': 'TVA',
    'baseAmount': 1000000.0,
    'period': '2024-01',
    'periodStart': '2024-01-01',
    'periodEnd': '2024-01-31',
    'dueDate': '2024-02-15',
    'description': 'TVA janvier 2024',
  }),
);
```

---

## 🔗 Endpoints Disponibles

### CRUD de Base

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/taxes-list` | Liste des taxes (avec pagination et filtres) |
| `GET` | `/api/taxes-show/{id}` | Détails d'une taxe |
| `POST` | `/api/taxes-create` | Créer une nouvelle taxe |
| `PUT` | `/api/taxes-update/{id}` | Mettre à jour une taxe |
| `DELETE` | `/api/taxes-destroy/{id}` | Supprimer une taxe |

### Actions sur les Taxes

| Méthode | Endpoint | Description | Body Requis |
|---------|----------|-------------|-------------|
| `POST` | `/api/taxes/{id}/calculate` | Calculer la taxe (met à jour les montants sans changer le statut) | `{}` |
| `POST` | `/api/taxes/{id}/mark-paid` | Marquer comme payée (seulement si status = `valide`) | `{}` |
| `POST` | `/api/taxes-validate/{id}` | Valider une taxe | `{"validation_comment": "..."}` (optionnel) |
| `POST` | `/api/taxes-reject/{id}` | Rejeter une taxe | `{"rejection_reason": "...", "rejection_comment": "..."}` |

### Utilitaires

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/taxes-statistics` | Statistiques des taxes |
| `GET` | `/api/tax-categories` | Liste des catégories de taxes |

---

## 📊 Format de Réponse - Liste des Taxes

### GET `/api/taxes-list`

```json
{
  "success": true,
  "message": "Taxes récupérées avec succès",
  "data": [
    {
      "id": 1,
      "category": "TVA",
      "comptable_id": 2,
      "comptable": {
        "id": 2,
        "nom": "Dupont",
        "prenom": "Jean"
      },
      "reference": "TVA-2024-01-001",
      "period": "2024-01",
      "period_start": "2024-01-01",
      "period_end": "2024-01-31",
      "due_date": "2024-02-15",
      "base_amount": 1000000.0,
      "tax_rate": 20.0,
      "tax_amount": 200000.0,
      "total_amount": 1200000.0,
      "status": "en_attente",
      "status_libelle": "En attente",
      "description": "TVA janvier 2024",
      "notes": null,
      "days_until_due": 15,
      "is_overdue": false,
      "total_paid": 0.0,
      "remaining_amount": 1200000.0,
      "created_at": "2024-11-02 14:00:00",
      "updated_at": "2024-11-02 14:00:00"
    }
  ],
  "pagination": {
    "current_page": 1,
    "last_page": 10,
    "per_page": 15,
    "total": 150,
    "from": 1,
    "to": 15
  },
  "stats": {
    "en_attente": 50,
    "valide": 80,
    "rejete": 10,
    "total": 150
  }
}
```

### Filtres Disponibles

| Paramètre | Type | Description | Exemple |
|-----------|------|-------------|---------|
| `status` | string | Filtrer par statut | `?status=en_attente` |
| `search` | string | Recherche dans référence, période, description | `?search=TVA` |
| `sort_by` | string | Champ de tri | `?sort_by=due_date` |
| `sort_order` | string | Ordre (asc/desc) | `?sort_order=asc` |
| `per_page` | int | Nombre d'éléments par page | `?per_page=20` |

---

## 📊 Format de Réponse - Statistiques

### GET `/api/taxes-statistics`

```json
{
  "success": true,
  "statistics": {
    "en_attente": 50,
    "valide": 80,
    "rejete": 10,
    "paye": 60,
    "total": 200,
    "montant_total_en_attente": 5000000.0,
    "montant_total_valide": 8000000.0,
    "montant_total_rejete": 1000000.0,
    "montant_total_paye": 6000000.0
  },
  "message": "Statistiques récupérées avec succès"
}
```

---

## 📊 Format de Réponse - Catégories de Taxes

### GET `/api/tax-categories`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "TVA",
      "code": "TVA",
      "description": "Taxe sur la valeur ajoutée",
      "default_rate": 20.0,
      "type": "percentage",
      "type_libelle": "Pourcentage",
      "frequency": "monthly",
      "frequency_libelle": "Mensuelle",
      "is_active": true,
      "applicable_to": ["factures", "ventes"],
      "formatted_rate": "20%"
    },
    {
      "id": 2,
      "name": "Impôt sur le Revenu",
      "code": "IR",
      "description": "Impôt sur le revenu des personnes",
      "default_rate": 15.0,
      "type": "percentage",
      "frequency": "yearly",
      "is_active": true,
      "formatted_rate": "15%"
    }
  ],
  "message": "Catégories récupérées avec succès"
}
```

---

## 🔄 Workflow d'une Taxe

### États et Transitions

```
1. en_attente (En attente) - Statut par défaut à la création
   ↓ validate() OU reject()
2a. valide (Validée)  OU  2b. rejete (Rejetée)
   ↓ (si valide) markAsPaid()
3. paye (Payée)
```

### Actions Disponibles

| Action | Endpoint | Status Requis | Status Résultant |
|--------|----------|--------------|------------------|
| Créer | `POST /taxes-create` | - | `en_attente` |
| Calculer | `POST /taxes/{id}/calculate` | `en_attente` | `en_attente` (met à jour les montants uniquement) |
| Valider | `POST /taxes-validate/{id}` | `en_attente` | `valide` |
| Rejeter | `POST /taxes-reject/{id}` | `en_attente` | `rejete` |
| Marquer payée | `POST /taxes/{id}/mark-paid` | `valide` | `paye` |

---

## ❌ Format de Réponse (Erreur)

### Status Code : `422 Validation Error`

```json
{
  "success": false,
  "message": "Erreur de validation",
  "errors": {
    "tax_category_id": ["The tax category id field is required."],
    "base_amount": ["The base amount field is required."],
    "period": ["The period field is required."]
  }
}
```

### Status Code : `400 Bad Request`

```json
{
  "success": false,
  "message": "Cette taxe ne peut pas être validée dans son état actuel"
}
```

### Status Code : `500 Server Error`

```json
{
  "success": false,
  "message": "Erreur lors de la création de la taxe: [détails de l'erreur]"
}
```

---

## ⚠️ Notes Importantes

1. **Catégorie de Taxe** : 
   - Récupérez d'abord les catégories via `/api/tax-categories`
   - Utilisez le `name` de la catégorie dans `category` (ex: "TVA", "Impôt sur le Revenu")

2. **Calcul Automatique** :
   - Le montant de la taxe (`tax_amount`) est calculé automatiquement depuis la catégorie
   - Vous pouvez forcer un taux différent en fournissant `taxRate`

3. **Référence** :
   - Générée automatiquement si non fournie (format: `CODE-PERIOD-NUM`, ex: "TVA-2024-01-001")
   - Basée sur le code de la catégorie et la période

4. **Période** :
   - Format recommandé : "YYYY-MM" (ex: "2024-01")
   - Ou fournir `periodStart` et `periodEnd` séparément

5. **Dates** :
   - Format : "YYYY-MM-DD"
   - `dueDate` doit être après `periodEnd`

6. **Status** :
   - Les taxes sont créées avec le status `en_attente` (par défaut)
   - Utilisez les endpoints d'action pour changer le status
   - Seules 4 valeurs sont possibles : `en_attente`, `valide`, `rejete`, `paye`

---

## ✅ Checklist pour Flutter

Avant d'envoyer la requête, vérifiez :

- [ ] `category` est une chaîne valide (nom d'une catégorie existante)
- [ ] `baseAmount` est un nombre positif
- [ ] `period` est au format "YYYY-MM" OU `periodStart` et `periodEnd` sont fournis
- [ ] `dueDate` est après `periodEnd`
- [ ] Token d'authentification est présent dans les headers
- [ ] Headers `Content-Type: application/json` et `Accept: application/json`

---

## 📋 Modèle TaxCategory (Référence)

### Structure d'une Catégorie de Taxe

```json
{
  "id": 1,
  "name": "TVA",
  "code": "TVA",
  "description": "Taxe sur la valeur ajoutée",
  "default_rate": 20.0,
  "type": "percentage",  // "percentage" ou "fixed"
  "frequency": "monthly", // "monthly", "quarterly", "yearly"
  "is_active": true,
  "applicable_to": ["factures", "ventes"], // Array JSON
  "created_at": "2024-01-01 00:00:00",
  "updated_at": "2024-01-01 00:00:00"
}
```

---

## 🔄 Mapping des Status (Compatibilité Flutter)

Le backend retourne exactement 4 statuts. Voici le mapping recommandé pour Flutter :

| Status Backend | Status Flutter | Description |
|----------------|----------------|-------------|
| `en_attente` | `pending` ou `en_attente` | En attente de validation (statut par défaut) |
| `valide` | `approved` ou `validated` | Validée |
| `rejete` | `rejected` ou `rejete` | Rejetée |
| `paye` | `paid` ou `paye` | Payée |

**Important :** Le backend utilise exactement ces 4 statuts. Pas d'autres statuts possibles.

---

## 📝 Exemples d'Utilisation Complète

### 1. Créer une Taxe

```dart
// Étape 1 : Récupérer les catégories
final categories = await taxService.getTaxCategories();

// Étape 2 : Créer la taxe
final tax = Tax(
  category: categories[0].name, // Nom de la première catégorie (ex: "TVA")
  baseAmount: 1000000.0,
  period: "2024-01",
  periodStart: "2024-01-01",
  periodEnd: "2024-01-31",
  dueDate: "2024-02-15",
  description: "TVA janvier 2024",
);

final createdTax = await taxService.createTax(tax);
```

### 2. Calculer une Taxe (Optionnel)

```dart
// Après création, calculer/mettre à jour les montants de la taxe
final calculatedTax = await taxService.calculateTax(createdTax.id);
// Le status reste 'en_attente', mais les montants sont mis à jour
```

### 3. Valider une Taxe

```dart
// Valider une taxe en attente
final validatedTax = await taxService.validateTax(
  createdTax.id,
  validationComment: "Taxe validée par le patron"
);
// Status passe de 'en_attente' à 'valide'
```

### 4. Marquer comme Payée

```dart
// Marquer une taxe comme payée (seulement si validée)
final paidTax = await taxService.markAsPaid(validatedTax.id);
// Status passe de 'valide' à 'paye'
```

### 5. Rejeter une Taxe (Alternative)

```dart
// Rejeter une taxe en attente
final rejectedTax = await taxService.rejectTax(
  createdTax.id,
  rejectionReason: "Erreur dans les données",
  rejectionComment: "Les montants sont incorrects"
);
// Status passe de 'en_attente' à 'rejete'
```

---

## 🎯 Résumé Rapide

### Champs Minimaux Requis pour Créer une Taxe :

```json
{
  "category": "TVA",
  "baseAmount": 1000000.0,
  "period": "2024-01",
  "periodStart": "2024-01-01",
  "periodEnd": "2024-01-31",
  "dueDate": "2024-02-15"
}
```

### Workflow Minimal :

1. **Créer** : `POST /taxes-create` → status `en_attente`
2. **Calculer** (Optionnel) : `POST /taxes/{id}/calculate` → status reste `en_attente` (met à jour les montants)
3. **Valider** : `POST /taxes-validate/{id}` → status `valide`
4. **Payer** : `POST /taxes/{id}/mark-paid` → status `paye`

**Alternative si rejetée :**
- **Rejeter** : `POST /taxes-reject/{id}` → status `rejete`

---

Cette documentation contient toutes les informations nécessaires pour intégrer les taxes et impôts dans Flutter sans problèmes de concordance avec le backend.

