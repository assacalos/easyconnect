<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\Conge;
use App\Models\User;
use App\Models\Notification;
use App\Http\Resources\CongeResource;
use Carbon\Carbon;

class CongeController extends Controller
{
    /**
     * Liste des congés
     * Accessible par RH, Patron et Admin
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json([
                    'success' => false,
                    'message' => 'Utilisateur non authentifié'
                ], 401);
            }
            
            $query = Conge::with(['user', 'approbateur']);
        
        // Filtrage par statut si fourni
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        // Filtrage par type si fourni
        if ($request->has('type_conge')) {
            $query->where('type_conge', $request->type_conge);
        }
        
        // Filtrage par période si fourni
        if ($request->has('date_debut')) {
            $query->where('date_debut', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_fin', '<=', $request->date_fin);
        }
        
        // Filtrage par utilisateur si fourni
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
        // Filtrage par urgent si fourni
        if ($request->has('urgent')) {
            $query->where('urgent', $request->urgent);
        }
        
        // Si technicien → filtre ses propres congés
        if ($user->isTechnicien()) {
            $query->where('user_id', $user->id);
        }
        
        $perPage = $request->get('per_page', 15);
        $conges = $query->orderBy('created_at', 'desc')->paginate($perPage);
        
        return response()->json([
            'success' => true,
            'data' => CongeResource::collection($conges->items()),
            'pagination' => [
                'current_page' => $conges->currentPage(),
                'last_page' => $conges->lastPage(),
                'per_page' => $conges->perPage(),
                'total' => $conges->total(),
            ],
            'message' => 'Liste des congés récupérée avec succès'
        ], 200);
        
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur lors de la récupération des congés: ' . $e->getMessage()
            ], 500);
        }
        
        return response()->json([
            'success' => true,
            'data' => CongeResource::collection($conges->items()),
            'pagination' => [
                'current_page' => $conges->currentPage(),
                'last_page' => $conges->lastPage(),
                'per_page' => $conges->perPage(),
                'total' => $conges->total(),
            ],
            'message' => 'Liste des congés récupérée avec succès'
        ]);
    }

    /**
     * Détails d'un congé
     * Accessible par RH, Patron et Admin
     */
    public function show($id)
    {
        $conge = Conge::with(['user', 'approbateur'])->findOrFail($id);
        
        // Vérification des permissions pour les techniciens
        if (auth()->user()->isTechnicien() && $conge->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce congé'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'data' => new CongeResource($conge),
            'message' => 'Congé récupéré avec succès'
        ]);
    }

    /**
     * Créer un congé
     * Accessible par tous les utilisateurs authentifiés
     */
    public function store(Request $request)
    {
        $request->validate([
            'type_conge' => 'required|in:annuel,maladie,maternite,paternite,formation,personnel,exceptionnel',
            'date_debut' => 'required|date|after_or_equal:today',
            'date_fin' => 'required|date|after:date_debut',
            'motif' => 'required|string|max:1000',
            'urgent' => 'boolean',
            'piece_jointe' => 'nullable|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:2048'
        ]);

        // Calculer le nombre de jours
        $dateDebut = Carbon::parse($request->date_debut);
        $dateFin = Carbon::parse($request->date_fin);
        $nombreJours = $dateDebut->diffInDays($dateFin) + 1;

        // Vérifier les conflits de congés
        $conflit = Conge::where('user_id', auth()->id())
            ->where('statut', '!=', 'rejete')
            ->where(function($q) use ($dateDebut, $dateFin) {
                $q->whereBetween('date_debut', [$dateDebut, $dateFin])
                  ->orWhereBetween('date_fin', [$dateDebut, $dateFin])
                  ->orWhere(function($q2) use ($dateDebut, $dateFin) {
                      $q2->where('date_debut', '<=', $dateDebut)
                         ->where('date_fin', '>=', $dateFin);
                  });
            })->first();

        if ($conflit) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà un congé sur cette période'
            ], 400);
        }

        $conge = Conge::create([
            'user_id' => auth()->id(),
            'type_conge' => $request->type_conge,
            'date_debut' => $request->date_debut,
            'date_fin' => $request->date_fin,
            'nombre_jours' => $nombreJours,
            'motif' => $request->motif,
            'urgent' => $request->urgent ?? false,
            'piece_jointe' => $request->file('piece_jointe') ? $request->file('piece_jointe')->store('conges') : null
        ]);

        // Créer une notification pour les RH
        $this->creerNotificationRH($conge);

        return response()->json([
            'success' => true,
            'conge' => $conge,
            'message' => 'Demande de congé créée avec succès'
        ], 201);
    }

    /**
     * Modifier un congé
     * Accessible par l'employé (si en attente) et RH/Admin
     */
    public function update(Request $request, $id)
    {
        $conge = Conge::findOrFail($id);
        
        // Vérifier les permissions
        if (auth()->user()->isTechnicien() && $conge->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce congé'
            ], 403);
        }
        
        // Vérifier que le congé peut être modifié
        if ($conge->statut !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un congé déjà traité'
            ], 400);
        }

        $request->validate([
            'type_conge' => 'required|in:annuel,maladie,maternite,paternite,formation,personnel,exceptionnel',
            'date_debut' => 'required|date',
            'date_fin' => 'required|date|after:date_debut',
            'motif' => 'required|string|max:1000',
            'urgent' => 'boolean'
        ]);

        // Recalculer le nombre de jours
        $dateDebut = Carbon::parse($request->date_debut);
        $dateFin = Carbon::parse($request->date_fin);
        $nombreJours = $dateDebut->diffInDays($dateFin) + 1;

        $conge->update([
            'type_conge' => $request->type_conge,
            'date_debut' => $request->date_debut,
            'date_fin' => $request->date_fin,
            'nombre_jours' => $nombreJours,
            'motif' => $request->motif,
            'urgent' => $request->urgent ?? false
        ]);

        return response()->json([
            'success' => true,
            'conge' => $conge,
            'message' => 'Congé modifié avec succès'
        ]);
    }

    /**
     * Approuver un congé
     * Accessible par RH, Patron et Admin
     */
    public function approve(Request $request, $id)
    {
        $request->validate([
            'commentaire_rh' => 'nullable|string|max:1000'
        ]);

        $conge = Conge::findOrFail($id);
        
        if ($conge->statut !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Ce congé a déjà été traité'
            ], 400);
        }
        
        $conge->update([
            'statut' => 'approuve',
            'commentaire_rh' => $request->commentaire_rh,
            'approuve_par' => auth()->id(),
            'date_approbation' => Carbon::now()
        ]);

        // Créer une notification pour l'employé
        $this->creerNotificationEmploye($conge, 'approuve');

        return response()->json([
            'success' => true,
            'conge' => $conge,
            'message' => 'Congé approuvé avec succès'
        ]);
    }

    /**
     * Rejeter un congé
     * Accessible par RH, Patron et Admin
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'raison_rejet' => 'required|string|max:1000'
        ]);

        $conge = Conge::findOrFail($id);
        
        if ($conge->statut !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Ce congé a déjà été traité'
            ], 400);
        }
        
        $conge->update([
            'statut' => 'rejete',
            'raison_rejet' => $request->raison_rejet,
            'approuve_par' => auth()->id(),
            'date_approbation' => Carbon::now()
        ]);

        // Créer une notification pour l'employé
        $this->creerNotificationEmploye($conge, 'rejete');

        return response()->json([
            'success' => true,
            'conge' => $conge,
            'message' => 'Congé rejeté avec succès'
        ]);
    }

    /**
     * Supprimer un congé
     * Accessible par l'employé (si en attente) et Admin
     */
    public function destroy($id)
    {
        $conge = Conge::findOrFail($id);
        
        // Vérifier les permissions
        if (auth()->user()->isTechnicien() && $conge->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce congé'
            ], 403);
        }
        
        // Vérifier que le congé peut être supprimé
        if ($conge->statut !== 'en_attente') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un congé déjà traité'
            ], 400);
        }
        
        $conge->delete();

        return response()->json([
            'success' => true,
            'message' => 'Congé supprimé avec succès'
        ]);
    }

    /**
     * Statistiques des congés
     * Accessible par RH, Patron et Admin
     */
    public function statistics(Request $request)
    {
        $dateDebut = $request->get('date_debut', Carbon::now()->startOfYear());
        $dateFin = $request->get('date_fin', Carbon::now()->endOfYear());
        
        $query = Conge::whereBetween('date_debut', [$dateDebut, $dateFin]);
        
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
        $conges = $query->get();
        
        $statistiques = [
            'periode' => [
                'debut' => $dateDebut,
                'fin' => $dateFin
            ],
            'total_conges' => $conges->count(),
            'conges_en_attente' => $conges->where('statut', 'en_attente')->count(),
            'conges_approuves' => $conges->where('statut', 'approuve')->count(),
            'conges_rejetes' => $conges->where('statut', 'rejete')->count(),
            'total_jours_demandes' => $conges->sum('nombre_jours'),
            'total_jours_approuves' => $conges->where('statut', 'approuve')->sum('nombre_jours'),
            'conges_urgents' => $conges->where('urgent', true)->count(),
            'par_type' => $conges->groupBy('type_conge')->map(function($group) {
                return [
                    'type' => $group->first()->getTypeLibelle(),
                    'count' => $group->count(),
                    'jours' => $group->sum('nombre_jours')
                ];
            }),
            'par_utilisateur' => $conges->groupBy('user_id')->map(function($group, $userId) {
                $user = User::find($userId);
                return [
                    'utilisateur' => $user ? $user->nom . ' ' . $user->prenom : 'Inconnu',
                    'total_conges' => $group->count(),
                    'jours_demandes' => $group->sum('nombre_jours'),
                    'jours_approuves' => $group->where('statut', 'approuve')->sum('nombre_jours')
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'statistiques' => $statistiques,
            'message' => 'Statistiques des congés récupérées avec succès'
        ]);
    }

    /**
     * Créer une notification pour les RH
     */
    private function creerNotificationRH($conge)
    {
        $rhUsers = User::whereIn('role', [1, 4, 6])->get();
        
        foreach ($rhUsers as $rhUser) {
            \App\Jobs\SendNotificationJob::dispatch([
                'user_id' => $rhUser->id,
                'type' => 'conge',
                'titre' => 'Nouvelle demande de congé',
                'message' => "{$conge->user->nom} {$conge->user->prenom} a demandé un congé du {$conge->date_debut->format('d/m/Y')} au {$conge->date_fin->format('d/m/Y')}",
                'data' => [
                    'conge_id' => $conge->id,
                    'user_id' => $conge->user_id,
                    'type_conge' => $conge->type_conge,
                    'urgent' => $conge->urgent
                ],
                'priorite' => $conge->urgent ? 'urgente' : 'normale'
            ]);
        }
    }

    /**
     * Créer une notification pour l'employé
     */
    private function creerNotificationEmploye($conge, $action)
    {
        $message = $action === 'approuve' 
            ? "Votre demande de congé a été approuvée"
            : "Votre demande de congé a été rejetée";
            
        \App\Jobs\SendNotificationJob::dispatch([
            'user_id' => $conge->user_id,
            'type' => 'conge',
            'titre' => $action === 'approuve' ? 'Congé approuvé' : 'Congé rejeté',
            'message' => $message,
            'data' => [
                'conge_id' => $conge->id,
                'action' => $action,
                'commentaire' => $action === 'approuve' ? $conge->commentaire_rh : $conge->raison_rejet
            ],
            'priorite' => 'normale'
        ]);
    }
}
