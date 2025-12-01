<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use Illuminate\Http\Request;
use App\Models\Notification;
use Carbon\Carbon;

class NotificationController extends Controller
{
    /**
     * Liste des notifications
     * Accessible par tous les utilisateurs authentifiés
     * Compatible avec la nouvelle structure de la documentation
     */
    public function index(Request $request)
    {
        $user = auth()->user();
        
        $query = Notification::where('user_id', $user->id)
            ->orderBy('created_at', 'desc');
        
        // Filtrage par type si fourni (nouveau format: info, success, warning, error, task)
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        
        // Filtrer les non lues si demandé
        if ($request->boolean('unread_only')) {
            $query->where(function($q) {
                $q->where('is_read', false)
                  ->orWhere('statut', 'non_lue');
            });
        }
        
        // Filtrage par statut si fourni (ancien système)
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        
        // Filtrage par priorité si fourni
        if ($request->has('priorite')) {
            $query->where('priorite', $request->priorite);
        }
        
        // Filtrage par canal si fourni
        if ($request->has('canal')) {
            $query->where('canal', $request->canal);
        }
        
        // Filtrage par période si fourni
        if ($request->has('date_debut')) {
            $query->where('created_at', '>=', $request->date_debut);
        }
        
        if ($request->has('date_fin')) {
            $query->where('created_at', '<=', $request->date_fin);
        }
        
        // Pagination
        $perPage = $request->get('per_page', 20);
        $notifications = $query->paginate($perPage);
        
        // Compter les notifications non lues
        $unreadCount = Notification::where('user_id', $user->id)
            ->where(function($q) {
                $q->where('is_read', false)
                  ->orWhere('statut', 'non_lue');
            })
            ->count();
        
        // Formater les notifications selon la nouvelle structure
        $formattedNotifications = $notifications->map(function($notification) {
            return [
                'id' => (string) $notification->id,
                'title' => $notification->title ?? $notification->titre ?? '',
                'message' => $notification->message,
                'type' => $notification->type,
                'entity_type' => $notification->entity_type,
                'entity_id' => $notification->entity_id ? (string) $notification->entity_id : null,
                'is_read' => $notification->is_read !== null ? (bool) $notification->is_read : ($notification->statut === 'lue'),
                'created_at' => $notification->created_at->toIso8601String(),
                'action_route' => $notification->action_route,
            ];
        });
        
        return response()->json([
            'success' => true,
            'data' => $formattedNotifications,
            'unread_count' => $unreadCount,
            'pagination' => [
                'current_page' => $notifications->currentPage(),
                'last_page' => $notifications->lastPage(),
                'per_page' => $notifications->perPage(),
                'total' => $notifications->total(),
            ],
        ]);
    }

    /**
     * Détails d'une notification
     * Accessible par tous les utilisateurs authentifiés
     */
    public function show($id)
    {
        $notification = Notification::where('user_id', auth()->id())->findOrFail($id);
        
        // Marquer comme lue si ce n'est pas déjà fait
        if ($notification->statut === 'non_lue') {
            $notification->marquerCommeLue();
        }
        
        return response()->json([
            'success' => true,
            'notification' => $notification,
            'message' => 'Notification récupérée avec succès'
        ]);
    }

    /**
     * Marquer une notification comme lue
     * Accessible par tous les utilisateurs authentifiés
     * Compatible avec la nouvelle structure de la documentation
     */
    public function markAsRead($id)
    {
        $notification = Notification::where('user_id', auth()->id())->findOrFail($id);
        
        if ($notification->is_read || $notification->statut === 'lue') {
            return response()->json([
                'success' => false,
                'message' => 'Cette notification est déjà marquée comme lue'
            ], 400);
        }
        
        $notification->marquerCommeLue();
        
        return response()->json([
            'success' => true,
            'message' => 'Notification marquée comme lue'
        ]);
    }

    /**
     * Marquer toutes les notifications comme lues
     * Accessible par tous les utilisateurs authentifiés
     * Compatible avec la nouvelle structure de la documentation
     */
    public function markAllAsRead()
    {
        $count = Notification::where('user_id', auth()->id())
            ->where(function($q) {
                $q->where('is_read', false)
                  ->orWhere('statut', 'non_lue');
            })
            ->update([
                'statut' => 'lue',
                'is_read' => true,
                'date_lecture' => Carbon::now()
            ]);
        
        return response()->json([
            'success' => true,
            'message' => 'Toutes les notifications ont été marquées comme lues'
        ]);
    }

    /**
     * Archiver une notification
     * Accessible par tous les utilisateurs authentifiés
     */
    public function archive($id)
    {
        $notification = Notification::where('user_id', auth()->id())->findOrFail($id);
        
        $notification->archiver();
        
        return response()->json([
            'success' => true,
            'notification' => $notification,
            'message' => 'Notification archivée'
        ]);
    }

    /**
     * Archiver toutes les notifications lues
     * Accessible par tous les utilisateurs authentifiés
     */
    public function archiveAllRead()
    {
        $count = Notification::where('user_id', auth()->id())
            ->where('statut', 'lue')
            ->update(['statut' => 'archivee']);
        
        return response()->json([
            'success' => true,
            'count' => $count,
            'message' => "$count notifications archivées"
        ]);
    }

    /**
     * Supprimer une notification
     * Accessible par tous les utilisateurs authentifiés
     * Compatible avec la nouvelle structure de la documentation
     */
    public function destroy($id)
    {
        $notification = Notification::where('user_id', auth()->id())->findOrFail($id);
        
        $notification->delete();
        
        return response()->json([
            'success' => true,
            'message' => 'Notification supprimée'
        ]);
    }

    /**
     * Supprimer toutes les notifications archivées
     * Accessible par tous les utilisateurs authentifiés
     */
    public function destroyArchived()
    {
        $count = Notification::where('user_id', auth()->id())
            ->where('statut', 'archivee')
            ->delete();
        
        return response()->json([
            'success' => true,
            'count' => $count,
            'message' => "$count notifications archivées supprimées"
        ]);
    }

    /**
     * Statistiques des notifications
     * Accessible par tous les utilisateurs authentifiés
     */
    public function statistics()
    {
        $userId = auth()->id();
        
        $total = Notification::where('user_id', $userId)->count();
        $nonLues = Notification::where('user_id', $userId)->where('statut', 'non_lue')->count();
        $lues = Notification::where('user_id', $userId)->where('statut', 'lue')->count();
        $archivees = Notification::where('user_id', $userId)->where('statut', 'archivee')->count();
        $urgentes = Notification::where('user_id', $userId)->where('priorite', 'urgente')->where('statut', 'non_lue')->count();
        
        $parType = Notification::where('user_id', $userId)
            ->selectRaw('type, count(*) as count')
            ->groupBy('type')
            ->get()
            ->map(function($item) {
                return [
                    'type' => $item->type,
                    'libelle' => $item->getTypeLibelle(),
                    'count' => $item->count
                ];
            });
        
        $parPriorite = Notification::where('user_id', $userId)
            ->selectRaw('priorite, count(*) as count')
            ->groupBy('priorite')
            ->get()
            ->map(function($item) {
                return [
                    'priorite' => $item->priorite,
                    'libelle' => $item->getPrioriteLibelle(),
                    'count' => $item->count
                ];
            });
        
        $recentes = Notification::where('user_id', $userId)
            ->where('created_at', '>=', Carbon::now()->subDays(7))
            ->count();
        
        $statistiques = [
            'total' => $total,
            'non_lues' => $nonLues,
            'lues' => $lues,
            'archivees' => $archivees,
            'urgentes' => $urgentes,
            'recentes' => $recentes,
            'par_type' => $parType,
            'par_priorite' => $parPriorite
        ];
        
        return response()->json([
            'success' => true,
            'statistiques' => $statistiques,
            'message' => 'Statistiques des notifications récupérées avec succès'
        ]);
    }

    /**
     * Notifications non lues
     * Accessible par tous les utilisateurs authentifiés
     */
    public function unread()
    {
        $notifications = Notification::where('user_id', auth()->id())
            ->where('statut', 'non_lue')
            ->orderBy('created_at', 'desc')
            ->get();
        
        return response()->json([
            'success' => true,
            'notifications' => $notifications,
            'count' => $notifications->count(),
            'message' => 'Notifications non lues récupérées avec succès'
        ]);
    }

    /**
     * Notifications urgentes
     * Accessible par tous les utilisateurs authentifiés
     */
    public function urgent()
    {
        $notifications = Notification::where('user_id', auth()->id())
            ->where('priorite', 'urgente')
            ->where('statut', 'non_lue')
            ->orderBy('created_at', 'desc')
            ->get();
        
        return response()->json([
            'success' => true,
            'notifications' => $notifications,
            'count' => $notifications->count(),
            'message' => 'Notifications urgentes récupérées avec succès'
        ]);
    }

    /**
     * Créer une notification
     * Accessible par Admin uniquement
     */
    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'type' => 'required|string|max:50',
            'titre' => 'required|string|max:255',
            'message' => 'required|string|max:1000',
            'data' => 'nullable|array',
            'priorite' => 'required|in:basse,normale,haute,urgente',
            'canal' => 'required|in:app,email,sms,push',
            'date_expiration' => 'nullable|date|after:now'
        ]);

        $notification = Notification::create([
            'user_id' => $request->user_id,
            'type' => $request->type,
            'titre' => $request->titre,
            'message' => $request->message,
            'data' => $request->data,
            'priorite' => $request->priorite,
            'canal' => $request->canal,
            'date_expiration' => $request->date_expiration
        ]);

        return response()->json([
            'success' => true,
            'notification' => $notification,
            'message' => 'Notification créée avec succès'
        ], 201);
    }

    /**
     * Nettoyer les notifications expirées
     * Accessible par Admin uniquement
     */
    public function cleanup()
    {
        $count = Notification::where('date_expiration', '<', Carbon::now())
            ->delete();
        
        return response()->json([
            'success' => true,
            'count' => $count,
            'message' => "$count notifications expirées supprimées"
        ]);
    }
}
