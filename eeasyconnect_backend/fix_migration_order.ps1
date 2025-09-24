# Script pour corriger l'ordre des migrations
Write-Host "🔄 Correction de l'ordre des migrations..." -ForegroundColor Yellow

# Supprimer la migration fournisseurs actuelle
Remove-Item "database\migrations\2025_09_23_145135_create_fournisseurs_table.php" -Force

# Créer une nouvelle migration fournisseurs avec un timestamp antérieur
$newTimestamp = "2025_01_20_000004"
$newFileName = "${newTimestamp}_create_fournisseurs_table.php"

# Contenu de la migration fournisseurs
$migrationContent = @"
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('fournisseurs', function (Blueprint `$table) {
            `$table->id();
            `$table->string('nom');
            `$table->string('email')->unique();
            `$table->string('telephone');
            `$table->string('adresse');
            `$table->string('ville');
            `$table->string('pays')->default('Côte d\'Ivoire');
            `$table->string('contact_principal');
            `$table->text('description')->nullable();
            `$table->enum('statut', ['actif', 'inactif', 'suspendu'])->default('actif');
            `$table->decimal('note_evaluation', 3, 2)->nullable(); // Note de 0 à 5
            `$table->text('commentaires')->nullable();
            `$table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('fournisseurs');
    }
};
"@

# Créer le nouveau fichier
$newFilePath = "database\migrations\$newFileName"
Set-Content -Path $newFilePath -Value $migrationContent

Write-Host "✅ Migration fournisseurs créée avec timestamp: $newTimestamp" -ForegroundColor Green
Write-Host "📋 Ordre des migrations maintenant:" -ForegroundColor Cyan
Write-Host "   1. Users" -ForegroundColor White
Write-Host "   2. Password reset tokens" -ForegroundColor White
Write-Host "   3. Failed jobs" -ForegroundColor White
Write-Host "   4. Personal access tokens" -ForegroundColor White
Write-Host "   5. Conges" -ForegroundColor White
Write-Host "   6. Evaluations" -ForegroundColor White
Write-Host "   7. Notifications" -ForegroundColor White
Write-Host "   8. Clients" -ForegroundColor White
Write-Host "   9. Bordereaus" -ForegroundColor White
Write-Host "   10. Fournisseurs (NOUVEAU)" -ForegroundColor Green
Write-Host "   11. Bon de commandes" -ForegroundColor White
Write-Host "   12. Autres..." -ForegroundColor White

Write-Host "🧪 Testez maintenant avec: php artisan migrate:fresh" -ForegroundColor Cyan
