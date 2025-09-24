<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Client;

class ClientSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
         DB::table('clients')->insert([
            [
                'user_id' => 1,
                'nom' => 'Doe',
                'prenom' => 'John',
                'email' => 'john.doe@example.com',
                'contact' => '1234567890',
                'adresse' => '123 Main St',
                'situation_geographique' => 'New York, USA',
                'nom_entreprise' => 'Doe Enterprises',
                'commentaire' => 'Business',
                'status' => 1,
            ],
            [
                'user_id' => 2,
                'nom' => 'Smith',
                'prenom' => 'Jane',
                'email' => 'jane.smith@example.com',
                'contact' => '0987654321',
                'adresse' => '456 Elm St',
                'situation_geographique' => 'Los Angeles, USA',
                'nom_entreprise' => 'Smith LLC',
                'commentaire' => 'Personal',
                'status' => 0,
            ],
        ]);
        Client::factory()->count(10)->create([
            'user_id' => 2, // tu forces la valeur
        ]);

        //
    }
}
