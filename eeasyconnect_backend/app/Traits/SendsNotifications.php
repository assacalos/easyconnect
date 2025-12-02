<?php

namespace App\Traits;

use App\Models\Notification;
use App\Jobs\SendNotificationJob;

trait SendsNotifications
{
    /**
     * Créer une notification (via queue job pour performance)
     * 
     * @param array $data
     * @param bool $sync Si true, crée la notification de manière synchrone (pour les cas critiques)
     * @return Notification|null
     */
    protected function createNotification(array $data, bool $sync = false)
    {
        if ($sync) {
            // Création synchrone pour les cas critiques
            return $this->createNotificationSync($data);
        }

        // Dispatch le job en arrière-plan pour améliorer les performances
        SendNotificationJob::dispatch($data);

        // Retourner null car la notification sera créée de manière asynchrone
        return null;
    }

    /**
     * Créer une notification de manière synchrone (pour les cas critiques)
     * 
     * @param array $data
     * @return Notification
     */
    protected function createNotificationSync(array $data)
    {
        // Préparer les données pour la création
        $notificationData = [
            'user_id' => $data['user_id'],
            'title' => $data['title'] ?? null,
            'titre' => $data['title'] ?? $data['titre'] ?? null, // Compatibilité avec l'ancien système
            'message' => $data['message'],
            'type' => $data['type'] ?? 'info',
            'entity_type' => $data['entity_type'] ?? null,
            'entity_id' => $data['entity_id'] ?? null,
            'action_route' => $data['action_route'] ?? null,
            'is_read' => false,
            'statut' => 'non_lue', // Compatibilité avec l'ancien système
            'priorite' => $data['priorite'] ?? 'normale',
        ];

        // Gérer metadata et data pour compatibilité
        if (isset($data['metadata'])) {
            $notificationData['metadata'] = $data['metadata'];
            $notificationData['data'] = $data['metadata']; // Pour compatibilité
        } elseif (isset($data['data'])) {
            $notificationData['data'] = $data['data'];
            $notificationData['metadata'] = $data['data']; // Pour la nouvelle structure
        }

        return Notification::create($notificationData);
    }

    /**
     * Envoyer une notification push (optionnel)
     * 
     * @param int $userId
     * @param array $data
     * @return void
     */
    protected function sendPushNotification($userId, array $data)
    {
        // Implémenter l'envoi de notifications push (Firebase, OneSignal, etc.)
        // Cette méthode est optionnelle et peut être étendue selon les besoins
        \Log::info("Push notification pour l'utilisateur {$userId}: " . ($data['title'] ?? 'Notification'));
    }
}

