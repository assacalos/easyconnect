<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Supprimer les utilisateurs existants
        User::truncate();

        // Créer les utilisateurs avec des mots de passe hashés
        $users = [
            [
                'nom' => 'Vagba',
                'prenom' => 'Fabrice',
                'email' => 'com@com.com',
                'password' => Hash::make('password'),
                'role_id' => 1,
            ],
            [
                'nom' => 'Miss',
                'prenom' => 'Lorette',
                'email' => 'comp@comp.com',
                'password' => Hash::make('password'),
                'role_id' => 2,
            ],
            [
                'nom' => 'Patterne',
                'prenom' => 'Junior',
                'email' => 'tech@tech.com',
                'password' => Hash::make('password'),
                'role_id' => 5,
            ],
            [
                'nom' => 'Mr',
                'prenom' => 'Ouattara',
                'email' => 'boss@boss.com',
                'password' => Hash::make('password'),
                'role_id' => 6,
            ],
            [
                'nom' => 'Mr',
                'prenom' => 'Inconnu',
                'email' => 'rh@rh.com',
                'password' => Hash::make('password'),
                'role_id' => 4,
            ],
        ];

        foreach ($users as $user) {
            User::create($user);
        }
    }
}
