<?php 

// database/seeders/DevisSeeder.php
namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\Devis;
use App\Models\DevisItem;
use App\Models\Client;
use App\Models\User;
use Faker\Factory as Faker;

class DevisSeeder extends Seeder
{
    public function run(): void
    {
        $faker = Faker::create();

        $clients = Client::all();
        $users = User::where('role', 2)->get(); // commerciaux

        foreach (range(1, 10) as $i) {
            $client = $clients->random();
            $user = $users->random();

            $devis = Devis::create([
                'client_id' => $client->id,
                'reference' => 'DV-' . strtoupper($faker->bothify('????-#####')),
                'date_creation' => $faker->date(),
                'date_validite' => $faker->optional()->date(),
                'notes' => $faker->sentence(),
                'status' => $faker->numberBetween(0, 3),
                'remise_globale' => $faker->optional()->randomFloat(2, 0, 20),
                'tva' => $faker->optional()->randomFloat(2, 0, 20),
                'conditions' => $faker->optional()->sentence(),
                'commentaire' => $faker->optional()->sentence(),
                'user_id' => $user->id,
            ]);

            foreach (range(1, rand(2, 5)) as $j) {
                DevisItem::create([
                    'devis_id' => $devis->id,
                    'designation' => $faker->words(3, true),
                    'quantite' => $faker->numberBetween(1, 10),
                    'prix_unitaire' => $faker->randomFloat(2, 50, 500),
                    'remise' => $faker->optional()->randomFloat(2, 0, 15),
                ]);
            }
        }
    }
}

