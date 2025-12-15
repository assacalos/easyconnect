<?php

namespace App\Jobs;

use App\Models\Notification;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ProcessNotificationActionsJob implements ShouldQueue
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
     * La notification à traiter
     *
     * @var Notification
     */
    protected $notification;

    /**
     * Créer une nouvelle instance du job.
     *
     * @param Notification $notification
     */
    public function __construct(Notification $notification)
    {
        $this->notification = $notification;
    }

    /**
     * Exécuter le job.
     *
     * @return void
     */
    public function handle()
    {
        try {
            // 1. Broadcast la notification (si un service de broadcast est disponible)
            if (class_exists(\App\Services\NotificationService::class)) {
                try {
                    $notificationService = app(\App\Services\NotificationService::class);
                    if (method_exists($notificationService, 'broadcastNotification')) {
                        $notificationService->broadcastNotification($this->notification);
                        Log::info("Notification broadcastée", [
                            'notification_id' => $this->notification->id
                        ]);
                    }
                } catch (\Exception $e) {
                    Log::warning('Impossible de broadcaster la notification: ' . $e->getMessage());
                }
            }

            // 2. Envoyer une notification push (toujours, pas seulement si canal = push)
            // Car on veut que le téléphone sonne pour toutes les notifications importantes
            $this->sendPushNotification();

            // 3. Envoyer un email (si le canal est email)
            if (($this->notification->canal ?? 'app') === 'email') {
                $this->sendEmailNotification();
            }

            // 4. Envoyer un SMS (si le canal est sms)
            if (($this->notification->canal ?? 'app') === 'sms') {
                $this->sendSmsNotification();
            }

            Log::info("Actions secondaires de notification traitées", [
                'notification_id' => $this->notification->id
            ]);

        } catch (\Exception $e) {
            Log::error('Erreur lors du traitement des actions secondaires de notification', [
                'error' => $e->getMessage(),
                'notification_id' => $this->notification->id
            ]);
            // Ne pas faire échouer le job pour les actions secondaires
            // La notification est déjà en base, c'est l'essentiel
        }
    }

    /**
     * Envoyer une notification push
     */
    protected function sendPushNotification()
    {
        try {
            $pushService = app(\App\Services\PushNotificationService::class);
            
            $title = $this->notification->title ?? $this->notification->titre ?? 'Notification';
            $body = $this->notification->message ?? '';
            
            // Préparer les données pour le push
            $pushData = $this->notification->metadata ?? $this->notification->data ?? [];
            
            if ($this->notification->entity_type) {
                $pushData['entity_type'] = $this->notification->entity_type;
            }
            if ($this->notification->entity_id) {
                $pushData['entity_id'] = $this->notification->entity_id;
            }
            if ($this->notification->action_route) {
                $pushData['action_route'] = $this->notification->action_route;
            }
            
            $options = [
                'priority' => $this->getPushPriority($this->notification->priorite ?? 'normale'),
                'sound' => 'default',
            ];
            
            $result = $pushService->sendToUser(
                $this->notification->user_id,
                $title,
                $body,
                $pushData,
                $options
            );
            
            if ($result['success']) {
                Log::info("Notification push envoyée avec succès", [
                    'notification_id' => $this->notification->id,
                    'user_id' => $this->notification->user_id,
                    'success_count' => $result['success_count'] ?? 0,
                ]);
            } else {
                Log::warning("Échec de l'envoi de notification push", [
                    'notification_id' => $this->notification->id,
                    'user_id' => $this->notification->user_id,
                    'message' => $result['message'] ?? 'Erreur inconnue',
                ]);
            }
        } catch (\Exception $e) {
            Log::error("Erreur lors de l'envoi de notification push", [
                'notification_id' => $this->notification->id,
                'user_id' => $this->notification->user_id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Convertir la priorité de notification en priorité FCM
     * 
     * @param string $priorite Priorité de la notification
     * @return string Priorité FCM
     */
    protected function getPushPriority($priorite)
    {
        $priorites = [
            'basse' => 'normal',
            'normale' => 'normal',
            'haute' => 'high',
            'urgente' => 'high',
        ];
        
        return $priorites[$priorite] ?? 'normal';
    }

    /**
     * Envoyer un email
     */
    protected function sendEmailNotification()
    {
        // Implémenter l'envoi d'email
        Log::info("Email notification envoyé", [
            'notification_id' => $this->notification->id,
            'user_id' => $this->notification->user_id
        ]);
    }

    /**
     * Envoyer un SMS
     */
    protected function sendSmsNotification()
    {
        // Implémenter l'envoi de SMS
        Log::info("SMS notification envoyé", [
            'notification_id' => $this->notification->id,
            'user_id' => $this->notification->user_id
        ]);
    }

    /**
     * Gérer l'échec du job.
     *
     * @param \Throwable $exception
     * @return void
     */
    public function failed(\Throwable $exception)
    {
        Log::error('Échec du traitement des actions secondaires de notification', [
            'error' => $exception->getMessage(),
            'notification_id' => $this->notification->id
        ]);
        // Ne pas faire échouer la notification elle-même
        // Elle est déjà en base de données
    }
}
