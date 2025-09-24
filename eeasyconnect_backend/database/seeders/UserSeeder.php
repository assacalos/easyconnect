<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('users')->insert([
            [
                'nom' => 'Carlos',
                'prenom' => 'Assa',
                'email' => 'admin@example.com',
                'password' => Hash::make('password'),
                'role' => 1,
            ],
            [
                'nom' => 'Fabrice',
                'prenom' => 'Vagba',
                'email' => 'commercial@example.com',
                'password' => Hash::make('password'),
                'role' => 2,
            ],
            [
                'nom' => 'Paul',
                'prenom' => 'Pierre',
                'email' => 'comptable@example.com',
                'password' => Hash::make('password'),
                'role' => 3,
            ],
            [
                'nom' => 'Brown',
                'prenom' => 'Charlie',
                'email' => 'rh@example.com',
                'password' => Hash::make('password'),
                'role' => 4,
            ],
            [
                'nom' => 'Davis',
                'prenom' => 'Junior',
                'email' => 'technicien@example.com',
                'password' => Hash::make('password'),
                'role' => 5,
            ],
            [
                'nom' => 'OUATTARA',
                'prenom' => 'Mr',
                'email' => 'patron@example.com',
                'password' => Hash::make('password'),
                'role' => 6,
            ],
        ]);

        //
    }
}
