<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Evaluation;
use App\Models\User;

class EvaluationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::all();
        $evaluateurs = User::whereIn('role', [1, 4, 6])->get(); // Admin, RH, Patron

        if ($users->isEmpty() || $evaluateurs->isEmpty()) {
            $this->command->warn('Utilisateurs ou évaluateurs manquants.');
            return;
        }

        $typesEvaluation = ['annuelle', 'semestrielle', 'trimestrielle', 'exceptionnelle'];
        $statuts = ['en_cours', 'finalisee', 'signee_employe', 'signee_evaluateur'];

        for ($i = 1; $i <= 20; $i++) {
            $employe = $users->where('role', '!=', 1)->random(); // Pas d'admin comme employé
            $evaluateur = $evaluateurs->random();
            $typeEvaluation = $typesEvaluation[array_rand($typesEvaluation)];
            $statut = $statuts[array_rand($statuts)];
            
            $dateEvaluation = now()->subDays(rand(1, 90));
            
            $noteGlobale = rand(8, 20);
            
            Evaluation::create([
                'user_id' => $employe->id,
                'evaluateur_id' => $evaluateur->id,
                'type_evaluation' => $typeEvaluation,
                'date_evaluation' => $dateEvaluation->toDateString(),
                'periode_debut' => $dateEvaluation->copy()->subMonths(6)->toDateString(),
                'periode_fin' => $dateEvaluation->toDateString(),
                'criteres_evaluation' => json_encode([
                    'competences_techniques' => rand(1, 5),
                    'competences_relationnelles' => rand(1, 5),
                    'ponctualite' => rand(1, 5),
                    'assiduite' => rand(1, 5)
                ]),
                'note_globale' => $noteGlobale,
                'commentaires_evaluateur' => $this->getCommentaireEvaluateur($noteGlobale),
                'commentaires_employe' => $statut === 'finalisee' ? 'Merci pour cette évaluation constructive' : null,
                'statut' => $statut,
                'date_signature_employe' => $statut === 'finalisee' ? $dateEvaluation->toDateString() : null,
                'date_signature_evaluateur' => $statut === 'finalisee' ? $dateEvaluation->toDateString() : null
            ]);
        }

        $this->command->info('20 évaluations créées avec succès.');
    }

    private function getCommentaireEvaluateur($note)
    {
        if ($note < 10) {
            return 'Performance insuffisante, amélioration nécessaire';
        } elseif ($note < 12) {
            return 'Performance en dessous des attentes, efforts à fournir';
        } elseif ($note < 14) {
            return 'Performance correcte, quelques points à améliorer';
        } elseif ($note < 16) {
            return 'Bonne performance, continuez ainsi';
        } else {
            return 'Excellente performance, félicitations !';
        }
    }
}