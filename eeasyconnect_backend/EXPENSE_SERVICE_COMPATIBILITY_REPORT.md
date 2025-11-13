# Rapport de Compatibilité - ExpenseService Flutter vs Backend Laravel

## ❌ INCOHÉRENCES IDENTIFIÉES

### 1. Champs du Modèle Expense

| Frontend (Flutter) | Backend (Laravel) | Statut | Notes |
|-------------------|-------------------|--------|-------|
| `id` | `id` | ✅ Compatible | |
| `title` | **Aucun champ équivalent** | ❌ Incompatible | Backend utilise `description` uniquement |
| `description` | `description` | ✅ Compatible | |
| `amount` | `amount` | ✅ Compatible | |
| `category` (string) | `expense_category_id` (int) | ❌ Incompatible | Backend attend l'ID de la catégorie |
| `status` ('pending') | `status` ('draft') | ⚠️ Partiellement | Frontend utilise 'pending', backend 'draft' par défaut |
| `expenseDate` | `expense_date` | ❌ Format | Snake_case vs camelCase |
| `receiptPath` | `receipt_path` | ❌ Format | Snake_case vs camelCase |
| `notes` | `justification` | ❌ Nom différent | Backend utilise `justification` |
| `createdAt` | `created_at` | ❌ Format | Snake_case vs camelCase (automatique Laravel) |
| `updatedAt` | `updated_at` | ❌ Format | Snake_case vs camelCase (automatique Laravel) |
| `createdBy` | `employee_id` | ❌ Nom différent | Backend utilise `employee_id` |
| `approvedBy` | `approved_by` | ❌ Format | Snake_case vs camelCase |
| `rejectionReason` | `rejection_reason` | ❌ Format | Snake_case vs camelCase |
| `approvedAt` (string) | `approved_at` (datetime) | ❌ Format | Type et nom différents |
| **Manquant** | `currency` | ❌ **Requis** | Backend requiert ce champ |
| **Manquant** | `expense_number` | ⚠️ Auto-généré | Généré automatiquement par le backend |

### 2. Statuts

| Frontend | Backend | Compatibilité |
|---------|---------|-------------|
| 'pending' | 'draft' | ❌ Incompatible |
| 'pending' | 'submitted' | ❌ Incompatible |
| 'pending' | 'under_review' | ❌ Incompatible |
| 'approved' | 'approved' | ✅ Compatible |
| 'rejected' | 'rejected' | ✅ Compatible |

**Problème**: Le frontend utilise 'pending' pour les dépenses en attente, mais le backend a plusieurs statuts ('draft', 'submitted', 'under_review').

### 3. Catégories

| Frontend | Backend | Compatibilité |
|---------|---------|-------------|
| 'office_supplies' (string) | ID de catégorie (int) | ❌ Incompatible |
| Les catégories sont des strings | Les catégories sont des relations | ❌ Incompatible |

**Problème**: Le frontend envoie des strings de catégories, mais le backend attend un `expense_category_id`.

### 4. Routes API

| Frontend Service | Backend Route | Statut |
|-----------------|---------------|--------|
| `GET /expenses-list` | `GET /expenses-list` | ✅ Compatible |
| `GET /expenses-show/{id}` | `GET /expenses-show/{id}` | ✅ Compatible |
| `POST /expenses-create` | `POST /expenses-create` | ✅ Compatible |
| `PUT /expenses-update/{id}` | `PUT /expenses-update/{id}` | ✅ Compatible |
| `DELETE /expenses-destroy/{id}` | `DELETE /expenses-destroy/{id}` | ✅ Compatible |
| `POST /expenses-submit/{id}` | `POST /expenses-submit/{id}` | ✅ Compatible |
| `POST /expenses-validate/{id}` | `POST /expenses-validate/{id}` | ✅ Compatible |
| `POST /expenses-reject/{id}` | `POST /expenses-reject/{id}` | ✅ Compatible |
| `GET /expenses-statistics` | `GET /expenses-statistics` | ✅ Compatible |
| `GET /expense-categories` | `GET /expense-categories` | ✅ Compatible |

✅ **Toutes les routes sont compatibles.**

## ✅ CORRECTIONS IMPLÉMENTÉES

### Modifications du Backend

1. ✅ **Méthode `formatExpenseForFrontend()`** ajoutée pour formater les réponses en camelCase
2. ✅ **Support des formats frontend et backend** dans `store()` :
   - Accepte `category` (string) et convertit en `expense_category_id`
   - Accepte `expenseDate` en plus de `expense_date`
   - Accepte `title` et l'utilise comme `description`
   - Accepte `notes` en plus de `justification`
   - Accepte `receiptPath` en plus de `receipt`
3. ✅ **Currency supporte 4 caractères** (pour "FCFA")
4. ✅ **Formatage automatique des statuts** : 'draft', 'submitted', 'under_review' → 'pending' pour le frontend
5. ✅ **Conversion automatique des catégories** : Si une catégorie string est fournie, recherche ou création automatique
6. ✅ **Toutes les méthodes retournent des données formatées** (index, show, update, store)

### Points Importants pour le Frontend

- ✅ Le frontend peut continuer à utiliser `category` (string) - le backend fera la conversion
- ✅ Le frontend peut continuer à utiliser `notes` - sera mappé vers `justification`
- ✅ Le frontend peut continuer à utiliser `title` - sera mappé vers `description`
- ⚠️ **IMPORTANT** : Le frontend doit **ajouter `currency`** dans les données de création (requis, par défaut "FCFA")
- ⚠️ Le frontend doit gérer les statuts backend : 'draft', 'submitted', 'under_review' sont convertis en 'pending'

### 5. Paramètres de Requête

| Frontend | Backend | Compatibilité |
|----------|---------|---------------|
| `status` | `status` | ✅ Compatible |
| `category` | Pas de filtre direct | ⚠️ À vérifier |
| `search` | Pas implémenté | ❌ Manquant |

## 📋 CORRECTIONS NÉCESSAIRES

### Corrections Backend Recommandées

1. **Ajouter un mapping de formatage pour le frontend** dans le contrôleur
2. **Accepter `category` (string) en plus de `expense_category_id`** et faire la conversion
3. **Accepter `notes` en plus de `justification`**
4. **Accepter `title` et le mapper vers `description`** si nécessaire
5. **Supporter `currency` avec 4 caractères** (comme pour les paiements)
6. **Retourner les données formatées pour le frontend** (camelCase)

### Corrections Frontend Recommandées

1. **Utiliser `expense_category_id` au lieu de `category` (string)**
2. **Envoyer `justification` au lieu de `notes`**
3. **Ajouter le champ `currency`** (requis)
4. **Gérer les statuts backend** ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'paid')
5. **Utiliser `expense_date` au lieu de `expenseDate`** dans toJson() OU adapter le mapping
6. **Adapter le modèle pour accepter `expense_category`** au lieu de `category` (string)

