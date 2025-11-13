# Structure de la Table `salaries` - Après Migration

## 📊 Colonnes de la Table `salaries`

Après l'exécution des migrations, la table `salaries` aura la structure suivante :

### Colonnes Principales

| Colonne | Type | Nullable | Description |
|---------|------|----------|-------------|
| `id` | BIGINT UNSIGNED | ❌ | Clé primaire auto-incrémentée |
| `hr_id` | BIGINT UNSIGNED | ❌ | ID de l'employé qui reçoit le salaire (FK vers `users.id`) |
| `salary_number` | VARCHAR(255) | ✅ | Numéro unique du salaire (ex: "SAL-2024-0001") |
| `period` | VARCHAR(255) | ✅ | Période du salaire (format "YYYY-MM", ex: "2024-01") |
| `period_start` | DATE | ✅ | Date de début de la période |
| `period_end` | DATE | ✅ | Date de fin de la période |
| `salary_date` | DATE | ✅ | Date de paiement prévue |
| `base_salary` | DECIMAL(10,2) | ❌ | Salaire de base |
| `gross_salary` | DECIMAL(10,2) | ✅ | Salaire brut (calculé) |
| `net_salary` | DECIMAL(10,2) | ✅ | Salaire net (calculé) |
| `total_allowances` | DECIMAL(10,2) | ✅ | Total des indemnités/primes |
| `total_deductions` | DECIMAL(10,2) | ✅ | Total des déductions |
| `total_taxes` | DECIMAL(10,2) | ✅ | Total des impôts |
| `total_social_security` | DECIMAL(10,2) | ✅ | Total des charges sociales |
| `status` | VARCHAR(50) | ✅ | Statut du salaire (`draft`, `calculated`, `approved`, `paid`, `cancelled`) |
| `notes` | TEXT | ✅ | Notes internes |
| `salary_breakdown` | JSON | ✅ | Détails du calcul du salaire |
| `components` | JSON | ✅ | Composants utilisés pour le calcul |
| `calculated_at` | TIMESTAMP | ✅ | Date/heure du calcul |
| `approved_at` | TIMESTAMP | ✅ | Date/heure d'approbation |
| `approved_by` | BIGINT UNSIGNED | ✅ | ID de l'utilisateur qui a approuvé (FK vers `users.id`) |
| `paid_at` | TIMESTAMP | ✅ | Date/heure du paiement |
| `paid_by` | BIGINT UNSIGNED | ✅ | ID de l'utilisateur qui a marqué comme payé (FK vers `users.id`) |
| `created_at` | TIMESTAMP | ✅ | Date de création |
| `updated_at` | TIMESTAMP | ✅ | Date de modification |

---

## 🔄 Changements par Rapport à la Structure Actuelle

### Colonnes Supprimées
- ❌ `user_id` → Remplacé par `hr_id`
- ❌ `employee_id` → Supprimé (remplacé par `hr_id`)
- ❌ `total_salary` → Remplacé par `gross_salary` et `net_salary`

### Colonnes Ajoutées
- ✅ `salary_number` : Numéro unique du salaire
- ✅ `period`, `period_start`, `period_end` : Gestion de la période
- ✅ `gross_salary`, `net_salary` : Séparation salaire brut/net
- ✅ `total_allowances`, `total_deductions`, `total_taxes`, `total_social_security` : Détails financiers
- ✅ `notes` : Notes internes
- ✅ `salary_breakdown`, `components` : Détails JSON du calcul
- ✅ `calculated_at`, `approved_at`, `approved_by`, `paid_at`, `paid_by` : Workflow d'approbation

---

## 📝 Migration à Exécuter

Pour mettre à jour votre table, exécutez :

```bash
php artisan migrate
```

Cette commande exécutera :
1. `2025_11_02_135410_remove_employee_id_from_salaries_table.php` - Supprime `employee_id`
2. `2025_11_02_140000_update_salaries_table_structure.php` - Met à jour la structure complète

---

## ✅ Vérification après Migration

Après la migration, vérifiez dans phpMyAdmin que vous avez toutes ces colonnes :

```
id
hr_id                    ← Renommé depuis user_id
salary_number
period
period_start
period_end
salary_date
base_salary
gross_salary
net_salary
total_allowances
total_deductions
total_taxes
total_social_security
status
notes
salary_breakdown
components
calculated_at
approved_at
approved_by
paid_at
paid_by
created_at
updated_at
```

---

## ⚠️ Notes Importantes

1. **`hr_id` remplace `user_id`** : Tous les salaires existants verront leur `user_id` renommé en `hr_id`
2. **`total_salary` supprimé** : Si vous avez des données, elles seront perdues (pensez à les sauvegarder)
3. **Status changé** : Le type `ENUM` est remplacé par `VARCHAR` pour plus de flexibilité
4. **Clés étrangères** : Les clés étrangères sont recréées correctement pour `hr_id`, `approved_by`, `paid_by`

---

## 🔙 Rollback

Si vous devez annuler la migration :

```bash
php artisan migrate:rollback --step=2
```

Cela restaurera :
- `hr_id` → `user_id`
- Supprimera toutes les nouvelles colonnes
- Recréera `total_salary`

