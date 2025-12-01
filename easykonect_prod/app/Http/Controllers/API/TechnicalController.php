<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Pointage;
use App\Models\User;
use Carbon\Carbon;

class TechnicalController extends Controller
{
    /**
     * Tableau de bord technique
     * Accessible par Technicien et Admin
     */
    public function dashboard(Request $request)
    {
        $userId = auth()->id();
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        
        // Pointages de l'utilisateur
        $pointages = Pointage::where('user_id', $userId)
            ->whereBetween('date_pointage', [$dateDebut, $dateFin])
            ->get();
        
        // Pointages d'aujourd'hui
        $pointagesAujourdhui = Pointage::where('user_id', $userId)
            ->where('date_pointage', Carbon::today())
            ->orderBy('created_at', 'asc')
            ->get();
        
        // Statistiques
        $statistiques = [
            'total_pointages' => $pointages->count(),
            'pointages_valides' => $pointages->where('statut', 'valide')->count(),
            'pointages_en_attente' => $pointages->where('statut', 'en_attente')->count(),
            'pointages_rejetes' => $pointages->where('statut', 'rejete')->count(),
            'pointages_aujourdhui' => $pointagesAujourdhui->count(),
            'derniere_activite' => $pointages->sortByDesc('created_at')->first(),
            'taux_presence' => $pointages->count() > 0 ? round(($pointages->where('statut', 'valide')->count() / $pointages->count()) * 100, 2) : 0
        ];
        
        $dashboard = [
            'periode' => [
                'debut' => $dateDebut,
                'fin' => $dateFin
            ],
            'pointages_aujourdhui' => $pointagesAujourdhui,
            'statistiques' => $statistiques
        ];
        
        return response()->json([
            'success' => true,
            'dashboard' => $dashboard,
            'message' => 'Tableau de bord technique récupéré avec succès'
        ]);
    }

    /**
     * Historique des pointages
     * Accessible par Technicien et Admin
     */
    public function pointageHistory(Request $request)
    {
        $userId = auth()->id();
        $query = Pointage::where('user_id', $userId);
        
        // Filtrage par date si fourni
        if ($request->has('date_debut')) {
            $query->where('date_pointage', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_pointage', '<=', $request->date_fin);
        }
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        // Filtrage par type si fourni
        if ($request->has('type_pointage')) {
            $query->where('type_pointage', $request->type_pointage);
        }
        
        $pointages = $query->orderBy('date_pointage', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();
        
        return response()->json([
            'success' => true,
            'pointages' => $pointages,
            'message' => 'Historique des pointages récupéré avec succès'
        ]);
    }

    /**
     * Statistiques personnelles
     * Accessible par Technicien et Admin
     */
    public function personalStatistics(Request $request)
    {
        $userId = auth()->id();
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        
        $pointages = Pointage::where('user_id', $userId)
            ->whereBetween('date_pointage', [$dateDebut, $dateFin])
            ->get();
        
        // Calcul des heures travaillées (approximation)
        $heuresTravaillees = $this->calculerHeuresTravaillees($pointages);
        
        // Pointages par jour de la semaine
        $pointagesParJour = $pointages->groupBy(function($pointage) {
            return Carbon::parse($pointage->date_pointage)->format('l');
        })->map(function($group) {
            return $group->count();
        });
        
        // Pointages par type
        $pointagesParType = $pointages->groupBy('type_pointage')->map(function($group) {
            return [
                'count' => $group->count(),
                'valides' => $group->where('statut', 'valide')->count()
            ];
        });
        
        $statistiques = [
            'periode' => [
                'debut' => $dateDebut,
                'fin' => $dateFin
            ],
            'total_pointages' => $pointages->count(),
            'pointages_valides' => $pointages->where('statut', 'valide')->count(),
            'pointages_en_attente' => $pointages->where('statut', 'en_attente')->count(),
            'pointages_rejetes' => $pointages->where('statut', 'rejete')->count(),
            'heures_travaillees' => $heuresTravaillees,
            'taux_presence' => $pointages->count() > 0 ? round(($pointages->where('statut', 'valide')->count() / $pointages->count()) * 100, 2) : 0,
            'pointages_par_jour' => $pointagesParJour,
            'pointages_par_type' => $pointagesParType,
            'moyenne_par_jour' => $pointages->count() > 0 ? round($pointages->count() / $dateDebut->diffInDays($dateFin), 2) : 0
        ];
        
        return response()->json([
            'success' => true,
            'statistiques' => $statistiques,
            'message' => 'Statistiques personnelles récupérées avec succès'
        ]);
    }

    /**
     * Pointage rapide
     * Accessible par Technicien et Admin
     */
    public function quickPointage(Request $request)
    {
        $request->validate([
            'type' => 'required|in:arrivee,depart,pause_debut,pause_fin',
            'lieu' => 'nullable|string|max:255',
            'commentaire' => 'nullable|string'
        ]);

        $userId = auth()->id();
        $aujourdhui = Carbon::today();
        
        // Vérifier s'il y a déjà un pointage du même type aujourd'hui
        $pointageExistant = Pointage::where('user_id', $userId)
            ->where('date_pointage', $aujourdhui)
            ->where('type_pointage', $request->type)
            ->where('statut', '!=', 'rejete')
            ->first();

        if ($pointageExistant) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà pointé ce type aujourd\'hui'
            ], 400);
        }

        $pointage = Pointage::create([
            'user_id' => $userId,
            'date_pointage' => $aujourdhui,
            'heure_arrivee' => $request->type === 'arrivee' ? Carbon::now()->format('H:i') : null,
            'heure_depart' => $request->type === 'depart' ? Carbon::now()->format('H:i') : null,
            'type_pointage' => $request->type,
            'statut' => 'en_attente',
            'commentaire' => $request->commentaire,
            'lieu' => $request->lieu,
            'created_by' => $userId
        ]);

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Pointage enregistré avec succès'
        ], 201);
    }

    /**
     * Gestion des pauses
     * Accessible par Technicien et Admin
     */
    public function pauseManagement(Request $request)
    {
        $userId = auth()->id();
        $aujourdhui = Carbon::today();
        
        // Récupérer les pointages d'aujourd'hui
        $pointagesAujourdhui = Pointage::where('user_id', $userId)
            ->where('date_pointage', $aujourdhui)
            ->orderBy('created_at', 'asc')
            ->get();
        
        $pauses = $pointagesAujourdhui->whereIn('type_pointage', ['pause_debut', 'pause_fin']);
        
        return response()->json([
            'success' => true,
            'pauses' => $pauses,
            'message' => 'Gestion des pauses récupérée avec succès'
        ]);
    }

    /**
     * Rapports techniques
     * Accessible par Technicien et Admin
     */
    public function technicalReports(Request $request)
    {
        $userId = auth()->id();
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfMonth());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfMonth());
        
        $pointages = Pointage::where('user_id', $userId)
            ->whereBetween('date_pointage', [$dateDebut, $dateFin])
            ->get();
        
        $rapport = [
            'periode' => [
                'debut' => $dateDebut,
                'fin' => $dateFin
            ],
            'total_pointages' => $pointages->count(),
            'pointages_valides' => $pointages->where('statut', 'valide')->count(),
            'pointages_en_attente' => $pointages->where('statut', 'en_attente')->count(),
            'pointages_rejetes' => $pointages->where('statut', 'rejete')->count(),
            'heures_travaillees' => $this->calculerHeuresTravaillees($pointages),
            'par_type' => $pointages->groupBy('type_pointage')->map(function($group) {
                return [
                    'type' => $group->first()->type_pointage,
                    'count' => $group->count(),
                    'valides' => $group->where('statut', 'valide')->count()
                ];
            }),
            'par_lieu' => $pointages->whereNotNull('lieu')->groupBy('lieu')->map(function($group) {
                return [
                    'lieu' => $group->first()->lieu,
                    'count' => $group->count()
                ];
            }),
            'evolution_hebdomadaire' => $this->getEvolutionHebdomadaire($pointages, $dateDebut, $dateFin)
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport technique généré avec succès'
        ]);
    }

    /**
     * Calculer les heures travaillées
     */
    private function calculerHeuresTravaillees($pointages)
    {
        $heures = 0;
        $pointagesParJour = $pointages->groupBy('date_pointage');
        
        foreach ($pointagesParJour as $pointagesJour) {
            $arrivee = $pointagesJour->where('type_pointage', 'arrivee')->where('statut', 'valide')->first();
            $depart = $pointagesJour->where('type_pointage', 'depart')->where('statut', 'valide')->first();
            
            if ($arrivee && $depart) {
                $heureArrivee = Carbon::parse($arrivee->date_pointage . ' ' . $arrivee->heure_arrivee);
                $heureDepart = Carbon::parse($depart->date_pointage . ' ' . $depart->heure_depart);
                $heures += $heureArrivee->diffInHours($heureDepart);
            }
        }
        
        return $heures;
    }

    /**
     * Obtenir l'évolution hebdomadaire
     */
    private function getEvolutionHebdomadaire($pointages, $dateDebut, $dateFin)
    {
        $evolution = [];
        $current = Carbon::parse($dateDebut);
        $end = Carbon::parse($dateFin);
        
        while ($current->lte($end)) {
            $weekStart = $current->copy()->startOfWeek();
            $weekEnd = $current->copy()->endOfWeek();
            
            $pointagesSemaine = $pointages->whereBetween('date_pointage', [$weekStart, $weekEnd]);
            
            $evolution[] = [
                'semaine' => $weekStart->format('Y-W'),
                'total_pointages' => $pointagesSemaine->count(),
                'pointages_valides' => $pointagesSemaine->where('statut', 'valide')->count(),
                'heures_travaillees' => $this->calculerHeuresTravaillees($pointagesSemaine)
            ];
            
            $current->addWeek();
        }
        
        return $evolution;
    }
}
