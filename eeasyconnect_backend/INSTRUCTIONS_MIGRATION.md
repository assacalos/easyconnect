# Instructions pour appliquer la migration salaries

## ⚠️ ATTENTION IMPORTANTE
Cette migration **supprime et recrée** les tables suivantes :
- `salaries`
- `salary_items`
- `salary_components`
- `payrolls`
- `payroll_settings`

**Toutes les données existantes dans ces tables seront perdues !**

## Option 1 : Via Artisan (Recommandé)

### Si vous avez des données à sauvegarder :
1. **Sauvegardez vos données** dans phpMyAdmin :
   - Exportez les tables concernées
   - Ou faites une sauvegarde complète de la base de données

2. **Exécutez la migration** :
```bash
php artisan migrate:refresh --path=database/migrations/2024_01_01_004700_consolidate_salaries_table.php
```

### Si vous n'avez pas de données importantes :
```bash
php artisan migrate:fresh --path=database/migrations/2024_01_01_004700_consolidate_salaries_table.php
```

### Ou simplement :
```bash
php artisan migrate
```

## Option 2 : Via phpMyAdmin (Manuel)

### Étape 1 : Sauvegarder les données existantes
1. Ouvrez phpMyAdmin
2. Sélectionnez votre base de données
3. Exportez les tables : `salaries`, `salary_items`, `salary_components`, `payrolls`, `payroll_settings`

### Étape 2 : Supprimer les anciennes tables
Exécutez ce SQL dans phpMyAdmin :
```sql
DROP TABLE IF EXISTS `payroll_settings`;
DROP TABLE IF EXISTS `payrolls`;
DROP TABLE IF EXISTS `salary_items`;
DROP TABLE IF EXISTS `salaries`;
DROP TABLE IF EXISTS `salary_components`;
```

### Étape 3 : Créer les nouvelles tables
Exécutez ce SQL dans phpMyAdmin (remplacez `votre_base_de_donnees` par le nom de votre base) :

```sql
-- Créer la table salary_components
CREATE TABLE `salary_components` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `type` enum('addition','deduction') NOT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `status` enum('en_attente','valide','rejete') NOT NULL DEFAULT 'en_attente',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Créer la table salaries
CREATE TABLE `salaries` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `salary_number` varchar(255) DEFAULT NULL,
  `employee_id` bigint(20) UNSIGNED NOT NULL,
  `period` varchar(255) DEFAULT NULL,
  `period_start` date DEFAULT NULL,
  `period_end` date DEFAULT NULL,
  `base_salary` decimal(10,2) NOT NULL,
  `gross_salary` decimal(10,2) NOT NULL DEFAULT 0.00,
  `net_salary` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_allowances` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_deductions` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_taxes` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_social_security` decimal(10,2) NOT NULL DEFAULT 0.00,
  `salary_date` date NOT NULL,
  `status` varchar(50) NOT NULL DEFAULT 'draft',
  `notes` text DEFAULT NULL,
  `justificatif` json DEFAULT NULL,
  `salary_breakdown` json DEFAULT NULL,
  `components` json DEFAULT NULL,
  `calculated_at` timestamp NULL DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `approved_by` bigint(20) UNSIGNED DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `paid_by` bigint(20) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `salaries_salary_number_unique` (`salary_number`),
  KEY `salaries_employee_id_foreign` (`employee_id`),
  KEY `salaries_approved_by_foreign` (`approved_by`),
  KEY `salaries_paid_by_foreign` (`paid_by`),
  CONSTRAINT `salaries_employee_id_foreign` FOREIGN KEY (`employee_id`) REFERENCES `employees` (`id`) ON DELETE CASCADE,
  CONSTRAINT `salaries_approved_by_foreign` FOREIGN KEY (`approved_by`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `salaries_paid_by_foreign` FOREIGN KEY (`paid_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Créer la table salary_items
CREATE TABLE `salary_items` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `salary_id` bigint(20) UNSIGNED NOT NULL,
  `component_id` bigint(20) UNSIGNED NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `salary_items_salary_id_foreign` (`salary_id`),
  KEY `salary_items_component_id_foreign` (`component_id`),
  CONSTRAINT `salary_items_salary_id_foreign` FOREIGN KEY (`salary_id`) REFERENCES `salaries` (`id`) ON DELETE CASCADE,
  CONSTRAINT `salary_items_component_id_foreign` FOREIGN KEY (`component_id`) REFERENCES `salary_components` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Créer la table payrolls
CREATE TABLE `payrolls` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `payroll_number` varchar(255) NOT NULL,
  `payroll_date` date NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `status` enum('en_attente','valide','rejete') NOT NULL DEFAULT 'en_attente',
  `user_id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payrolls_payroll_number_unique` (`payroll_number`),
  KEY `payrolls_user_id_foreign` (`user_id`),
  CONSTRAINT `payrolls_user_id_foreign` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Créer la table payroll_settings
CREATE TABLE `payroll_settings` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `setting_name` varchar(255) NOT NULL,
  `setting_value` text NOT NULL,
  `status` enum('en_attente','valide','rejete') NOT NULL DEFAULT 'en_attente',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Étape 4 : Migrer les données (si nécessaire)
Si vous aviez des données dans l'ancienne table `salaries` avec `hr_id`, vous devrez les migrer vers `employee_id`.

**Important** : Assurez-vous que la table `employees` existe et contient les employés correspondants avant d'exécuter cette migration.

## Vérification

Après avoir appliqué la migration, vérifiez que :
1. La table `salaries` a bien la colonne `employee_id` (et non `hr_id`)
2. La clé étrangère pointe vers `employees.id`
3. Les relations fonctionnent correctement

## En cas de problème

Si vous rencontrez des erreurs :
1. Vérifiez que la table `employees` existe
2. Vérifiez que les employés existent dans la table `employees`
3. Vérifiez les logs Laravel : `storage/logs/laravel.log`

