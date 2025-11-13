<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Corriger le type de application_deadline de date à datetime
        Schema::table('recruitment_requests', function (Blueprint $table) {
            // Pour MySQL/MariaDB
            if (DB::getDriverName() === 'mysql') {
                DB::statement('ALTER TABLE recruitment_requests MODIFY application_deadline DATETIME NOT NULL');
            }
            // Pour PostgreSQL
            elseif (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN application_deadline TYPE TIMESTAMP WITHOUT TIME ZONE');
            }
            // Pour SQLite (nécessite une recréation de table)
            elseif (DB::getDriverName() === 'sqlite') {
                // SQLite ne supporte pas ALTER COLUMN, on doit recréer la table
                // Cette opération est complexe et peut être ignorée pour SQLite en développement
            }
        });

        // Ajouter les limites de taille pour les colonnes string
        Schema::table('recruitment_requests', function (Blueprint $table) {
            // Pour MySQL/MariaDB
            if (DB::getDriverName() === 'mysql') {
                DB::statement('ALTER TABLE recruitment_requests MODIFY department VARCHAR(100) NOT NULL');
                DB::statement('ALTER TABLE recruitment_requests MODIFY position VARCHAR(100) NOT NULL');
                DB::statement('ALTER TABLE recruitment_requests MODIFY salary_range VARCHAR(100) NOT NULL');
                DB::statement('ALTER TABLE recruitment_requests MODIFY location VARCHAR(255) NOT NULL');
            }
            // Pour PostgreSQL
            elseif (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN department TYPE VARCHAR(100)');
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN position TYPE VARCHAR(100)');
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN salary_range TYPE VARCHAR(100)');
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN location TYPE VARCHAR(255)');
            }
        });

        // Corriger candidate_phone dans recruitment_applications
        Schema::table('recruitment_applications', function (Blueprint $table) {
            // Pour MySQL/MariaDB
            if (DB::getDriverName() === 'mysql') {
                DB::statement('ALTER TABLE recruitment_applications MODIFY candidate_phone VARCHAR(50) NOT NULL');
            }
            // Pour PostgreSQL
            elseif (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE recruitment_applications ALTER COLUMN candidate_phone TYPE VARCHAR(50)');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revenir au type date pour application_deadline
        Schema::table('recruitment_requests', function (Blueprint $table) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement('ALTER TABLE recruitment_requests MODIFY application_deadline DATE NOT NULL');
            }
            elseif (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN application_deadline TYPE DATE');
            }
        });

        // Retirer les limites de taille (retour à VARCHAR sans limite ou taille par défaut)
        Schema::table('recruitment_requests', function (Blueprint $table) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement('ALTER TABLE recruitment_requests MODIFY department VARCHAR(255) NOT NULL');
                DB::statement('ALTER TABLE recruitment_requests MODIFY position VARCHAR(255) NOT NULL');
                DB::statement('ALTER TABLE recruitment_requests MODIFY salary_range VARCHAR(255) NOT NULL');
                DB::statement('ALTER TABLE recruitment_requests MODIFY location VARCHAR(255) NOT NULL');
            }
            elseif (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN department TYPE VARCHAR(255)');
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN position TYPE VARCHAR(255)');
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN salary_range TYPE VARCHAR(255)');
                DB::statement('ALTER TABLE recruitment_requests ALTER COLUMN location TYPE VARCHAR(255)');
            }
        });

        // Retirer la limite pour candidate_phone
        Schema::table('recruitment_applications', function (Blueprint $table) {
            if (DB::getDriverName() === 'mysql') {
                DB::statement('ALTER TABLE recruitment_applications MODIFY candidate_phone VARCHAR(255) NOT NULL');
            }
            elseif (DB::getDriverName() === 'pgsql') {
                DB::statement('ALTER TABLE recruitment_applications ALTER COLUMN candidate_phone TYPE VARCHAR(255)');
            }
        });
    }
};

