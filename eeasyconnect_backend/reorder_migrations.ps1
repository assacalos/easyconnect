# Script PowerShell pour réorganiser les migrations dans le bon ordre
# Ce script renomme les fichiers de migration pour respecter l'ordre des dépendances

Write-Host "🔄 Réorganisation des migrations..." -ForegroundColor Yellow

# Sauvegarde des migrations existantes
$migrationsDir = "database\migrations"
$backupDir = "database\migrations_backup"

if (Test-Path $backupDir) {
    Remove-Item $backupDir -Recurse -Force
}
New-Item -ItemType Directory -Path $backupDir
Copy-Item "$migrationsDir\*" $backupDir -Recurse

Write-Host "✅ Sauvegarde créée dans $backupDir" -ForegroundColor Green

# Ordre correct des migrations (sans les timestamps Laravel de base)
$correctOrder = @(
    "2025_09_20_234900_create_fournisseurs_table.php",
    "2025_09_20_221851_create_clients_table.php", 
    "2025_01_20_000001_create_conges_table.php",
    "2025_01_20_000002_create_evaluations_table.php",
    "2025_01_20_000003_create_notifications_table.php",
    "2025_09_20_230152_create_pointages_table.php",
    "2025_09_23_090855_create_devis_table.php",
    "2025_09_20_225641_create_bon_de_commandes_table.php",
    "2025_09_20_234719_create_factures_table.php",
    "2025_09_20_234737_create_paiements_table.php",
    "2025_09_20_224918_create_bordereaus_table.php",
    "2025_09_23_105654_create_bordereau_items_table.php",
    "2025_09_20_225910_create_reportings_table.php"
)

# Nouveaux timestamps dans l'ordre correct
$newTimestamps = @(
    "2025_01_21_000001",
    "2025_01_21_000002", 
    "2025_01_21_000003",
    "2025_01_21_000004",
    "2025_01_21_000005",
    "2025_01_21_000006",
    "2025_01_21_000007",
    "2025_01_21_000008",
    "2025_01_21_000009",
    "2025_01_21_000010",
    "2025_01_21_000011",
    "2025_01_21_000012",
    "2025_01_21_000013"
)

Write-Host "🔄 Renommage des migrations..." -ForegroundColor Yellow

for ($i = 0; $i -lt $correctOrder.Length; $i++) {
    $oldFile = "$migrationsDir\$($correctOrder[$i])"
    $newFile = "$migrationsDir\$($newTimestamps[$i])_$($correctOrder[$i].Split('_', 2)[1])"
    
    if (Test-Path $oldFile) {
        Rename-Item $oldFile $newFile
        Write-Host "✅ Renommé: $($correctOrder[$i]) -> $($newTimestamps[$i])_$($correctOrder[$i].Split('_', 2)[1])" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Fichier non trouvé: $oldFile" -ForegroundColor Red
    }
}

Write-Host "🎉 Réorganisation terminée!" -ForegroundColor Green
Write-Host "📋 Vérifiez l'ordre avec: php artisan migrate:status" -ForegroundColor Cyan
Write-Host "🧪 Testez avec: php artisan migrate:reset && php artisan migrate" -ForegroundColor Cyan
