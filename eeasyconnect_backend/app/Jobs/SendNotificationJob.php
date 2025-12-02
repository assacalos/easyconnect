<?php

namespace App\Jobs;

use App\Models\Notification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendNotificationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /**
     * Le nombre de fois que le job peut être tenté.
     *
     * @var int
     */
    public $tries = 3;

    /**
     * Le nombre de secondes à attendre avant de réessayer le job.
     *
     * @var int
     */
    public $backoff = [10, 30, 60];

    /**
     * Données de la notification
     *
     * @var array
     */
    protected $notificationData;

    /**
     * Créer une nouvelle instance du job.
     *
     * @param array $notificationData
     */
    public function __construct(array $notificationData)
    {
        $this->notificationData = $notificationData;
    }

    /**
     * Exécuter le job.
     *
     * @return void
     */
    public function handle()
    {
        try {
            // Préparer les données pour la création
            $data = [
                'user_id' => $this->notificationData['user_id'],
                'title' => $this->notificationData['title'] ?? null,
                'titre' => $this->notificationData['title'] ?? $this->notificationData['titre'] ?? null,
                'message' => $this->notificationData['message'],
                'type' => $this->notificationData['type'] ?? 'info',
                'entity_type' => $this->notificationData['entity_type'] ?? null,
                'entity_id' => $this->notificationData['entity_id'] ?? null,
                'action_route' => $this->notificationData['action_route'] ?? null,
                'is_read' => false,
                'statut' => 'non_lue',
                'priorite' => $this->notificationData['priorite'] ?? 'normale',
            ];

            // Gérer metadata et data pour compatibilité
            if (isset($this->notificationData['metadata'])) {
                $data['metadata'] = $this->notificationData['metadata'];
                $data['data'] = $this->notificationData['metadata'];
            } elseif (isset($this->notificationData['data'])) {
                $data['data'] = $this->notificationData['data'];
                $data['metadata'] = $this->notificationData['data'];
            }

            // Créer la notification
            $notification = Notification::create($data);

            // Si un service de broadcast est disponible, l'utiliser
            if (class_exists(\App\Services\NotificationService::class)) {
                try {
                    $notificationService = app(\App\Services\NotificationService::class);
                    if (method_exists($notificationService, 'broadcastNotification')) {
                        $notificationService->broadcastNotification($notification);
                    }
                } catch (\Exception $e) {
                    Log::warning('Impossible de broadcaster la notification: ' . $e->getMessage());
                }
            }

            Log::info("Notification créée avec succès", ['notification_id' => $notification->id]);

        } catch (\Exception $e) {
            Log::error('Erreur lors de la création de la notification', [
                'error' => $e->getMessage(),
                'data' => $this->notificationData
            ]);
            throw $e;
        }
    }

    /**
     * Gérer l'échec du job.
     *
     * @param \Throwable $exception
     * @return void
     */
    public function failed(\Throwable $exception)
    {
        Log::error('Échec de la création de notification', [
            'error' => $exception->getMessage(),
            'data' => $this->notificationData
        ]);
    }
}
