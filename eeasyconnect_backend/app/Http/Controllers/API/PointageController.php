<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Traits\SendsNotifications;
use Illuminate\Http\Request;
use App\Models\Pointage;
use App\Models\User;
use Carbon\Carbon;

class PointageController extends Controller
{
    use SendsNotifications;
    /**
     * Liste des pointages
     * Accessible par RH, Patron et Admin
     */
    public function index(Request $request)
    {
        $query = Pointage::with('user');
        
        // Filtrage par utilisateur si fourni
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
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
        
        // Si RH → peut voir tous les pointages
        // Si Technicien → ne peut voir que ses propres pointages
        if (auth()->user()->isTechnicien()) {
            $query->where('user_id', auth()->id());
        }
        
        $pointages = $query->orderBy('date_pointage', 'desc')->get();
        
        return response()->json([
            'success' => true,
            'pointages' => $pointages,
            'message' => 'Liste des pointages récupérée avec succès'
        ]);
    }

    /**
     * Détails d'un pointage
     * Accessible par RH, Patron et Admin
     */
    public function show($id)
    {
        $pointage = Pointage::with('user')->findOrFail($id);
        
        // Vérification des permissions pour les techniciens
        if (auth()->user()->isTechnicien() && $pointage->user_id !== auth()->id()) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé à ce pointage'
            ], 403);
        }
        
        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Pointage récupéré avec succès'
        ]);
    }

    /**
     * Créer un pointage
     * Accessible par Technicien, RH et Admin
     */
    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'date_pointage' => 'required|date',
            'heure_arrivee' => 'required|date_format:H:i',
            'heure_depart' => 'nullable|date_format:H:i|after:heure_arrivee',
            'type_pointage' => 'required|in:arrivee,depart,pause_debut,pause_fin',
            'statut' => 'required|in:en_attente,valide,rejete',
            'commentaire' => 'nullable|string',
            'lieu' => 'nullable|string|max:255'
        ]);

        // Vérifier que l'utilisateur peut pointer pour lui-même ou si c'est un RH/Admin
        if ($request->user_id !== auth()->id() && !auth()->user()->isRH() && !auth()->user()->isAdmin()) {
            return response()->json([
                'success' => false,
                'message' => 'Vous ne pouvez pointer que pour vous-même'
            ], 403);
        }

        $pointage = Pointage::create([
            'user_id' => $request->user_id,
            'date_pointage' => $request->date_pointage,
            'heure_arrivee' => $request->heure_arrivee,
            'heure_depart' => $request->heure_depart,
            'type_pointage' => $request->type_pointage,
            'statut' => $request->statut,
            'commentaire' => $request->commentaire,
            'lieu' => $request->lieu,
            'created_by' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Pointage créé avec succès'
        ], 201);
    }

    /**
     * Pointer l'arrivée
     * Accessible par Technicien, RH et Admin
     */
    public function pointerArrivee(Request $request)
    {
        $request->validate([
            'lieu' => 'nullable|string|max:255',
            'commentaire' => 'nullable|string'
        ]);

        // Vérifier qu'il n'y a pas déjà un pointage d'arrivée aujourd'hui
        $pointageExistant = Pointage::where('user_id', auth()->id())
            ->where('date_pointage', Carbon::today())
            ->where('type_pointage', 'arrivee')
            ->where('statut', '!=', 'rejete')
            ->first();

        if ($pointageExistant) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà pointé votre arrivée aujourd\'hui'
            ], 400);
        }

        $pointage = Pointage::create([
            'user_id' => auth()->id(),
            'date_pointage' => Carbon::today(),
            'heure_arrivee' => Carbon::now()->format('H:i'),
            'type_pointage' => 'arrivee',
            'statut' => 'en_attente',
            'commentaire' => $request->commentaire,
            'lieu' => $request->lieu,
            'created_by' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Arrivée pointée avec succès'
        ], 201);
    }

    /**
     * Pointer le départ
     * Accessible par Technicien, RH et Admin
     */
    public function pointerDepart(Request $request)
    {
        $request->validate([
            'commentaire' => 'nullable|string'
        ]);

        // Vérifier qu'il y a un pointage d'arrivée aujourd'hui
        $pointageArrivee = Pointage::where('user_id', auth()->id())
            ->where('date_pointage', Carbon::today())
            ->where('type_pointage', 'arrivee')
            ->where('statut', 'valide')
            ->first();

        if (!$pointageArrivee) {
            return response()->json([
                'success' => false,
                'message' => 'Vous devez d\'abord pointer votre arrivée'
            ], 400);
        }

        // Vérifier qu'il n'y a pas déjà un pointage de départ aujourd'hui
        $pointageDepartExistant = Pointage::where('user_id', auth()->id())
            ->where('date_pointage', Carbon::today())
            ->where('type_pointage', 'depart')
            ->where('statut', '!=', 'rejete')
            ->first();

        if ($pointageDepartExistant) {
            return response()->json([
                'success' => false,
                'message' => 'Vous avez déjà pointé votre départ aujourd\'hui'
            ], 400);
        }

        $pointage = Pointage::create([
            'user_id' => auth()->id(),
            'date_pointage' => Carbon::today(),
            'heure_depart' => Carbon::now()->format('H:i'),
            'type_pointage' => 'depart',
            'statut' => 'en_attente',
            'commentaire' => $request->commentaire,
            'created_by' => auth()->id()
        ]);

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Départ pointé avec succès'
        ], 201);
    }

    /**
     * Modifier un pointage
     * Accessible par RH et Admin
     */
    public function update(Request $request, $id)
    {
        $pointage = Pointage::findOrFail($id);
        
        // Vérifier que le pointage peut être modifié
        if ($pointage->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de modifier un pointage validé'
            ], 400);
        }

        $request->validate([
            'date_pointage' => 'required|date',
            'heure_arrivee' => 'required|date_format:H:i',
            'heure_depart' => 'nullable|date_format:H:i|after:heure_arrivee',
            'type_pointage' => 'required|in:arrivee,depart,pause_debut,pause_fin',
            'statut' => 'required|in:en_attente,valide,rejete',
            'commentaire' => 'nullable|string',
            'lieu' => 'nullable|string|max:255'
        ]);

        $pointage->update($request->all());

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Pointage modifié avec succès'
        ]);
    }

    /**
     * Valider un pointage
     * Accessible par RH, Patron et Admin
     */
    public function validatePointage($id)
    {
        $pointage = Pointage::findOrFail($id);
        
        if ($pointage->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Ce pointage est déjà validé'
            ], 400);
        }
        
        $pointage->update([
            'statut' => 'valide',
            'date_validation' => now()
        ]);

        // Notifier l'utilisateur concerné
        if ($pointage->user_id) {
            $this->createNotification([
                'user_id' => $pointage->user_id,
                'title' => 'Validation Pointage',
                'message' => "Votre pointage du {$pointage->date_pointage} a été validé",
                'type' => 'success',
                'entity_type' => 'pointage',
                'entity_id' => $pointage->id,
                'action_route' => "/pointages/{$pointage->id}",
            ]);
        }

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Pointage validé avec succès'
        ]);
    }

    /**
     * Rejeter un pointage
     * Accessible par RH, Patron et Admin
     */
    public function reject(Request $request, $id)
    {
        $request->validate([
            'commentaire' => 'required|string'
        ]);

        $pointage = Pointage::findOrFail($id);
        
        $pointage->update([
            'statut' => 'rejete',
            'commentaire' => $request->commentaire
        ]);

        // Notifier l'utilisateur concerné
        if ($pointage->user_id) {
            $this->createNotification([
                'user_id' => $pointage->user_id,
                'title' => 'Rejet Pointage',
                'message' => "Votre pointage du {$pointage->date_pointage} a été rejeté. Raison: {$request->commentaire}",
                'type' => 'error',
                'entity_type' => 'pointage',
                'entity_id' => $pointage->id,
                'action_route' => "/pointages/{$pointage->id}",
                'metadata' => ['reason' => $request->commentaire],
            ]);
        }

        return response()->json([
            'success' => true,
            'pointage' => $pointage,
            'message' => 'Pointage rejeté avec succès'
        ]);
    }

    /**
     * Supprimer un pointage
     * Accessible par Admin uniquement
     */
    public function destroy($id)
    {
        $pointage = Pointage::findOrFail($id);
        
        // Vérifier que le pointage peut être supprimé
        if ($pointage->statut === 'valide') {
            return response()->json([
                'success' => false,
                'message' => 'Impossible de supprimer un pointage validé'
            ], 400);
        }
        
        $pointage->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pointage supprimé avec succès'
        ]);
    }

    /**
     * Rapports de pointages
     * Accessible par RH, Patron et Admin
     */
    public function reports(Request $request)
    {
        $query = Pointage::with('user');
        
        // Filtrage par période
        if ($request->has('date_debut')) {
            $query->where('date_pointage', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('date_pointage', '<=', $request->date_fin);
        }
        
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        
        $pointages = $query->get();
        
        $rapport = [
            'total_pointages' => $pointages->count(),
            'pointages_valides' => $pointages->where('statut', 'valide')->count(),
            'pointages_en_attente' => $pointages->where('statut', 'en_attente')->count(),
            'pointages_rejetes' => $pointages->where('statut', 'rejete')->count(),
            'par_utilisateur' => $pointages->groupBy('user_id')->map(function($group, $userId) {
                $user = User::find($userId);
                return [
                    'user' => $user ? $user->nom . ' ' . $user->prenom : 'Utilisateur inconnu',
                    'total_pointages' => $group->count(),
                    'pointages_valides' => $group->where('statut', 'valide')->count()
                ];
            }),
            'par_type' => $pointages->groupBy('type_pointage')->map(function($group) {
                return [
                    'count' => $group->count(),
                    'valides' => $group->where('statut', 'valide')->count()
                ];
            })
        ];
        
        return response()->json([
            'success' => true,
            'rapport' => $rapport,
            'message' => 'Rapport de pointages généré avec succès'
        ]);
    }

    /**
     * Pointages d'aujourd'hui pour l'utilisateur connecté
     * Accessible par tous les utilisateurs authentifiés
     */
    public function today()
    {
        $pointages = Pointage::where('user_id', auth()->id())
            ->where('date_pointage', Carbon::today())
            ->orderBy('created_at', 'asc')
            ->get();
        
        return response()->json([
            'success' => true,
            'pointages' => $pointages,
            'message' => 'Pointages d\'aujourd\'hui récupérés avec succès'
        ]);
    }
}
