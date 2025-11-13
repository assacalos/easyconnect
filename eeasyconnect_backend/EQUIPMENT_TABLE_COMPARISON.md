# Comparaison des tables Equipment

## ⚠️ Problème identifié

Vous regardez la table `equipment` dans phpMyAdmin, mais le modèle `EquipmentNew` utilise la table `equipment_new` qui n'existe pas encore dans votre base de données.

## 📊 Comparaison des tables

### Table `equipment` (celle que vous voyez actuellement)
```
id
category_id          ← Relation avec equipment_categories
name
serial_number
description
status               ← Enum: 'en_attente', 'valide', 'rejete'
purchase_date
purchase_price
location
created_at
updated_at
```

**Champs manquants pour le modèle Flutter :**
- ❌ `condition` (excellent, good, fair, poor, critical)
- ❌ `category` (string au lieu de category_id)
- ❌ `model`
- ❌ `brand`
- ❌ `department`
- ❌ `assigned_to`
- ❌ `warranty_expiry`
- ❌ `last_maintenance`
- ❌ `next_maintenance`
- ❌ `current_value`
- ❌ `supplier`
- ❌ `notes`
- ❌ `attachments`
- ❌ `created_by`
- ❌ `updated_by`

### Table `equipment_new` (celle nécessaire pour le modèle Flutter)
```
id
name
description
category              ← String (pas de relation)
status                ← Enum: 'active', 'inactive', 'maintenance', 'broken', 'retired'
condition             ← Enum: 'excellent', 'good', 'fair', 'poor', 'critical'
serial_number
model
brand
location
department
assigned_to
purchase_date
warranty_expiry
last_maintenance
next_maintenance
purchase_price
current_value
supplier
notes
attachments           ← JSON
created_by            ← Foreign key vers users
updated_by            ← Foreign key vers users
created_at
updated_at
```

## ✅ Solution

Une migration a été créée : `2025_11_12_000001_create_equipment_new_table.php`

### Pour appliquer la migration :

```bash
php artisan migrate
```

Cette migration va créer la table `equipment_new` avec tous les champs nécessaires pour correspondre au modèle Flutter.

## 🔄 Différences importantes

| Aspect | Table `equipment` | Table `equipment_new` |
|--------|-------------------|----------------------|
| **Catégorie** | `category_id` (FK) | `category` (string) |
| **Statut** | `'en_attente', 'valide', 'rejete'` | `'active', 'inactive', 'maintenance', 'broken', 'retired'` |
| **Condition** | ❌ N'existe pas | ✅ `'excellent', 'good', 'fair', 'poor', 'critical'` |
| **Champs** | 11 champs | 23 champs |
| **Relations** | Via `category_id` | Via `category` (string) |

## 📝 Notes

1. **Deux tables différentes** : `equipment` et `equipment_new` sont deux tables distinctes
2. **Le modèle `EquipmentNew`** utilise `equipment_new` (pas `equipment`)
3. **Le contrôleur `EquipmentController`** utilise `EquipmentNew`, donc il a besoin de `equipment_new`
4. **Migration créée** : La migration pour créer `equipment_new` est prête à être exécutée

## 🎯 Action requise

Exécutez la migration pour créer la table `equipment_new` :

```bash
php artisan migrate
```

Après cela, vous devriez voir la table `equipment_new` dans phpMyAdmin avec tous les champs nécessaires.


