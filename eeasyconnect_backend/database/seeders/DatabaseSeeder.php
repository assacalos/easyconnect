<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Database\Seeders\UserSeeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // \App\Models\User::factory(10)->create();

        // \App\Models\User::factory()->create([
        //     'name' => 'Test User',
        //     'email' => 'test@example.com',
        // ]);

        // Désactiver temporairement les contraintes de clés étrangères
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        $this->call([
            UserSeeder::class,
            FournisseurSeeder::class,
            ClientSeeder::class,
            FactureSeeder::class,
            PaiementSeeder::class,
            PointageSeeder::class,
            CongeSeeder::class,
            EvaluationSeeder::class,
            NotificationSeeder::class,
            DevisSeeder::class,
            BordereauSeeder::class,
            BonDeCommandeSeeder::class,
            ReportingSeeder::class,
            AttendanceSeeder::class,
            InvoiceSeeder::class,
            PaymentSeeder::class,
            // Add other seeders here as needed
        ]);

        // Réactiver les contraintes de clés étrangères
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

    }
}
