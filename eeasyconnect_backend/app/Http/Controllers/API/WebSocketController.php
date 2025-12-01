<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\API\Controller;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class WebSocketController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Tester l'envoi de notification en temps réel
     */
    public function testNotification(Request $request)
    {
        $user = Auth::user();
        
        $this->notificationService->createAndBroadcast(
            $user->id,
            'test',
            'Test de notification',
            'Ceci est un test de notification en temps réel',
            ['test' => true],
            'normale'
        );

        return response()->json([
            'message' => 'Notification de test envoyée',
            'user_id' => $user->id
        ]);
    }

    /**
     * Envoyer une notification à tous les RH
     */
    public function notifyRH(Request $request)
    {
        $request->validate([
            'titre' => 'required|string',
            'message' => 'required|string'
        ]);

        $this->notificationService->broadcastToRH(
            'rh',
            $request->titre,
            $request->message,
            $request->data ?? [],
            $request->priorite ?? 'normale'
        );

        return response()->json([
            'message' => 'Notification RH envoyée'
        ]);
    }

    /**
     * Envoyer une notification à tous les admins
     */
    public function notifyAdmins(Request $request)
    {
        $request->validate([
            'titre' => 'required|string',
            'message' => 'required|string'
        ]);

        $this->notificationService->broadcastToAdmins(
            'admin',
            $request->titre,
            $request->message,
            $request->data ?? [],
            $request->priorite ?? 'normale'
        );

        return response()->json([
            'message' => 'Notification admin envoyée'
        ]);
    }

    /**
     * Obtenir les informations de connexion WebSocket
     */
    public function getWebSocketInfo()
    {
        return response()->json([
            'pusher_key' => config('broadcasting.connections.pusher.key'),
            'pusher_cluster' => config('broadcasting.connections.pusher.options.cluster'),
            'pusher_host' => config('broadcasting.connections.pusher.options.host'),
            'pusher_port' => config('broadcasting.connections.pusher.options.port'),
            'pusher_scheme' => config('broadcasting.connections.pusher.options.scheme'),
            'user_channel' => 'user.' . Auth::id(),
            'hr_channel' => 'hr-notifications',
            'admin_channel' => 'notifications'
        ]);
    }
}
