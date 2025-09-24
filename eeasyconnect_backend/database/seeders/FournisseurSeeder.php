<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Fournisseur;

class FournisseurSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $fournisseurs = [
            [
                'nom' => 'Tech Solutions SARL',
                'email' => 'contact@techsolutions.ci',
                'telephone' => '+225 20 30 40 50',
                'adresse' => 'Cocody, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Jean Kouassi',
                'description' => 'Spécialisé dans les équipements informatiques et électroniques',
                'statut' => 'actif',
                'note_evaluation' => 4.5,
                'commentaires' => 'Fournisseur fiable et réactif'
            ],
            [
                'nom' => 'Bureau & Co',
                'email' => 'info@bureau-co.ci',
                'telephone' => '+225 20 25 35 45',
                'adresse' => 'Marcory, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Marie Traoré',
                'description' => 'Fournitures de bureau et matériel de travail',
                'statut' => 'actif',
                'note_evaluation' => 4.2,
                'commentaires' => 'Bon rapport qualité-prix'
            ],
            [
                'nom' => 'Securite Plus',
                'email' => 'contact@securiteplus.ci',
                'telephone' => '+225 20 22 33 44',
                'adresse' => 'Plateau, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Paul Assi',
                'description' => 'Équipements de sécurité et surveillance',
                'statut' => 'actif',
                'note_evaluation' => 4.8,
                'commentaires' => 'Excellente qualité, prix élevés'
            ],
            [
                'nom' => 'Materiaux Construction CI',
                'email' => 'vente@materiaux-ci.ci',
                'telephone' => '+225 20 24 34 44',
                'adresse' => 'Yopougon, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Kouadio N\'Guessan',
                'description' => 'Matériaux de construction et équipements',
                'statut' => 'actif',
                'note_evaluation' => 4.0,
                'commentaires' => 'Large gamme de produits'
            ],
            [
                'nom' => 'Transport Express',
                'email' => 'logistique@transport-express.ci',
                'telephone' => '+225 20 26 36 46',
                'adresse' => 'Port-Bouët, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Fatou Diallo',
                'description' => 'Services de transport et logistique',
                'statut' => 'actif',
                'note_evaluation' => 4.3,
                'commentaires' => 'Service rapide et efficace'
            ],
            [
                'nom' => 'Equipements Medical CI',
                'email' => 'medical@equipements-ci.ci',
                'telephone' => '+225 20 27 37 47',
                'adresse' => 'Cocody, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Dr. Aminata Koné',
                'description' => 'Équipements médicaux et pharmaceutiques',
                'statut' => 'actif',
                'note_evaluation' => 4.7,
                'commentaires' => 'Spécialisé dans le médical'
            ],
            [
                'nom' => 'Alimentation Pro',
                'email' => 'contact@alimentation-pro.ci',
                'telephone' => '+225 20 28 38 48',
                'adresse' => 'Adjamé, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Bakary Sissoko',
                'description' => 'Produits alimentaires et restauration',
                'statut' => 'actif',
                'note_evaluation' => 4.1,
                'commentaires' => 'Produits frais de qualité'
            ],
            [
                'nom' => 'Maintenance Services',
                'email' => 'service@maintenance-ci.ci',
                'telephone' => '+225 20 29 39 49',
                'adresse' => 'Marcory, Abidjan',
                'ville' => 'Abidjan',
                'pays' => 'Côte d\'Ivoire',
                'contact_principal' => 'Ibrahim Ouattara',
                'description' => 'Services de maintenance et réparation',
                'statut' => 'inactif',
                'note_evaluation' => 3.5,
                'commentaires' => 'Service temporairement suspendu'
            ]
        ];

        foreach ($fournisseurs as $fournisseur) {
            Fournisseur::create($fournisseur);
        }

        $this->command->info('8 fournisseurs créés avec succès.');
    }
}