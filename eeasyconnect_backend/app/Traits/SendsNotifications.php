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
     * APPROCHE HYBRIDE :
     * - Création synchrone en base (garantie de persistance)
     * - Actions secondaires (broadcast, push, email) en asynchrone
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
            'canal' => $data['canal'] ?? 'app', // Pour déterminer les actions secondaires
        ];

        // Gérer metadata et data pour compatibilité
        if (isset($data['metadata'])) {
            $notificationData['metadata'] = $data['metadata'];
            $notificationData['data'] = $data['metadata']; // Pour compatibilité
        } elseif (isset($data['data'])) {
            $notificationData['data'] = $data['data'];
            $notificationData['metadata'] = $data['data']; // Pour la nouvelle structure
        }

        // 1. CRÉER LA NOTIFICATION DE MANIÈRE SYNCHRONE (CRITIQUE)
        // Cela garantit que la notification est toujours en base, même si les workers sont arrêtés
        $notification = Notification::create($notificationData);

        // 2. ENVOYER LA NOTIFICATION PUSH IMMÉDIATEMENT (si l'utilisateur a des tokens)
        // On envoie le push de manière asynchrone via un job pour ne pas bloquer
        try {
            if (config('queue.default') !== 'sync') {
                \App\Jobs\ProcessNotificationActionsJob::dispatch($notification);
            } else {
                // Si les queues ne sont pas disponibles, traiter les actions secondaires de manière synchrone
                $this->processNotificationActionsSync($notification);
            }
        } catch (\Exception $e) {
            // Ne pas faire échouer la création de notification si les actions secondaires échouent
            \Log::warning("Impossible de dispatcher les actions secondaires de notification", [
                'notification_id' => $notification->id,
                'error' => $e->getMessage()
            ]);
        }

        return $notification;
    }

    /**
     * Traiter les actions secondaires de manière synchrone (fallback)
     * 
     * @param Notification $notification
     * @return void
     */
    protected function processNotificationActionsSync(Notification $notification)
    {
        // Broadcast si disponible
        if (class_exists(\App\Services\NotificationService::class)) {
            try {
                $notificationService = app(\App\Services\NotificationService::class);
                if (method_exists($notificationService, 'broadcastNotification')) {
                    $notificationService->broadcastNotification($notification);
                }
            } catch (\Exception $e) {
                \Log::warning('Impossible de broadcaster la notification: ' . $e->getMessage());
            }
        }

        // Envoyer la notification push
        $this->sendPushNotification($notification->user_id, [
            'title' => $notification->title ?? $notification->titre,
            'message' => $notification->message,
            'type' => $notification->type,
            'entity_type' => $notification->entity_type,
            'entity_id' => $notification->entity_id,
            'action_route' => $notification->action_route,
            'priorite' => $notification->priorite,
            'metadata' => $notification->metadata ?? $notification->data,
        ]);
    }

    /**
     * Envoyer une notification push
     * 
     * @param int $userId
     * @param array $data Contient 'title', 'message', et optionnellement 'data', 'options'
     * @return void
     */
    protected function sendPushNotification($userId, array $data)
    {
        try {
            $pushService = app(\App\Services\PushNotificationService::class);
            
            $title = $data['title'] ?? $data['titre'] ?? 'Notification';
            $body = $data['message'] ?? '';
            $pushData = $data['metadata'] ?? $data['data'] ?? [];
            
            // Ajouter les informations de l'entité si disponibles
            if (isset($data['entity_type'])) {
                $pushData['entity_type'] = $data['entity_type'];
            }
            if (isset($data['entity_id'])) {
                $pushData['entity_id'] = $data['entity_id'];
            }
            if (isset($data['action_route'])) {
                $pushData['action_route'] = $data['action_route'];
            }
            
            $options = [
                'priority' => $this->getPushPriority($data['priorite'] ?? 'normale'),
                'sound' => 'default',
            ];
            
            $result = $pushService->sendToUser($userId, $title, $body, $pushData, $options);
            
            if ($result['success']) {
                \Log::info("Notification push envoyée avec succès", [
                    'user_id' => $userId,
                    'success_count' => $result['success_count'] ?? 0,
                ]);
            } else {
                \Log::warning("Échec de l'envoi de notification push", [
                    'user_id' => $userId,
                    'message' => $result['message'] ?? 'Erreur inconnue',
                ]);
            }
        } catch (\Exception $e) {
            // Ne pas faire échouer la création de notification si le push échoue
            \Log::error("Erreur lors de l'envoi de notification push", [
                'user_id' => $userId,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
        }
    }

    /**
     * Convertir la priorité de notification en priorité FCM
     * 
     * @param string $priorite Priorité de la notification (basse, normale, haute, urgente)
     * @return string Priorité FCM (normal ou high)
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
     * Récupérer l'ID utilisateur depuis une entité
     * Gère les cas où l'ID pointe directement vers users ou via employees
     * 
     * @param mixed $entity
     * @param string $field Nom du champ (employee_id, user_id, etc.)
     * @return int|null
     */
    protected function getUserIdFromEntity($entity, $field = 'employee_id')
    {
        // Si le champ existe et pointe directement vers users
        if (isset($entity->$field) && $entity->$field) {
            return $entity->$field;
        }
        
        // Si le champ pointe vers employees, récupérer user_id
        if ($field === 'employee_id' && method_exists($entity, 'employee')) {
            $employee = $entity->employee;
            if ($employee && isset($employee->user_id)) {
                return $employee->user_id;
            }
        }
        
        // Si user_id existe directement
        if (isset($entity->user_id) && $entity->user_id) {
            return $entity->user_id;
        }
        
        return null;
    }

    /**
     * Notifier l'approbateur (patron/admin) lors de la soumission d'une entité
     * 
     * @param mixed $entity L'entité soumise
     * @param string $entityType Type d'entité (expense, leave_request, etc.)
     * @param string $entityName Nom affiché de l'entité (Dépense, Demande de Congé, etc.)
     * @param int|null $approverRoleId Rôle de l'approbateur (6 = patron par défaut)
     * @param string|null $entityIdentifier Identifiant de l'entité (id, reference, number, etc.)
     * @return void
     */
    protected function notifyApproverOnSubmission($entity, $entityType, $entityName, $approverRoleId = 6, $entityIdentifier = null)
    {
        $approver = \App\Models\User::where('role', $approverRoleId)->first();
        if (!$approver) {
            \Log::warning("Aucun approbateur trouvé pour le rôle {$approverRoleId}", [
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null
            ]);
            return;
        }

        $identifier = $entityIdentifier ?? $entity->id ?? $entity->reference ?? $entity->number ?? 'N/A';
        
        // Créer la notification de manière synchrone pour garantir sa création en base
        try {
            $notification = $this->createNotificationSync([
                'user_id' => $approver->id,
                'title' => "Soumission {$entityName}",
                'message' => "{$entityName} #{$identifier} a été soumise pour validation",
                'type' => 'info',
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'action_route' => "/{$entityType}s/{$entity->id}",
            ]);
            \Log::info("Notification de soumission créée pour le patron", [
                'approver_id' => $approver->id,
                'approver_email' => $approver->email ?? 'N/A',
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'notification_id' => $notification->id ?? null
            ]);
        } catch (\Exception $e) {
            \Log::error("Erreur lors de la création de la notification de soumission", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'approver_id' => $approver->id ?? null,
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null
            ]);
        }
    }

    /**
     * Notifier le soumetteur lors de l'approbation d'une entité
     * 
     * @param mixed $entity L'entité approuvée
     * @param string $entityType Type d'entité
     * @param string $entityName Nom affiché de l'entité
     * @param string $userIdField Champ contenant l'ID utilisateur (employee_id, user_id, etc.)
     * @param string|null $entityIdentifier Identifiant de l'entité
     * @return void
     */
    protected function notifySubmitterOnApproval($entity, $entityType, $entityName, $userIdField = 'employee_id', $entityIdentifier = null)
    {
        $userId = $this->getUserIdFromEntity($entity, $userIdField);
        if (!$userId) {
            \Log::warning("Impossible de trouver l'ID utilisateur pour la notification d'approbation", [
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'field' => $userIdField,
                'entity_data' => [
                    'user_id' => $entity->user_id ?? null,
                    'employee_id' => $entity->employee_id ?? null,
                    'created_by' => $entity->created_by ?? null,
                ]
            ]);
            return;
        }

        // Vérifier que l'utilisateur existe
        $user = \App\Models\User::find($userId);
        if (!$user) {
            \Log::warning("L'utilisateur trouvé n'existe pas dans la base de données", [
                'user_id' => $userId,
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null
            ]);
            return;
        }

        $identifier = $entityIdentifier ?? $entity->id ?? $entity->reference ?? $entity->number ?? 'N/A';
        
        // Créer la notification de manière synchrone pour garantir sa création en base
        try {
            $notification = $this->createNotificationSync([
                'user_id' => $userId,
                'title' => "Approbation {$entityName}",
                'message' => "Votre {$entityName} #{$identifier} a été approuvée",
                'type' => 'success',
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'action_route' => "/{$entityType}s/{$entity->id}",
            ]);
            \Log::info("Notification d'approbation créée pour l'utilisateur", [
                'user_id' => $userId,
                'user_email' => $user->email ?? 'N/A',
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'notification_id' => $notification->id ?? null
            ]);
        } catch (\Exception $e) {
            \Log::error("Erreur lors de la création de la notification d'approbation", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'user_id' => $userId,
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null
            ]);
        }
    }

    /**
     * Notifier le soumetteur lors du rejet d'une entité
     * 
     * @param mixed $entity L'entité rejetée
     * @param string $entityType Type d'entité
     * @param string $entityName Nom affiché de l'entité
     * @param string $reason Raison du rejet
     * @param string $userIdField Champ contenant l'ID utilisateur
     * @param string|null $entityIdentifier Identifiant de l'entité
     * @return void
     */
    protected function notifySubmitterOnRejection($entity, $entityType, $entityName, $reason, $userIdField = 'employee_id', $entityIdentifier = null)
    {
        $userId = $this->getUserIdFromEntity($entity, $userIdField);
        if (!$userId) {
            \Log::warning("Impossible de trouver l'ID utilisateur pour la notification de rejet", [
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'field' => $userIdField
            ]);
            return;
        }

        $identifier = $entityIdentifier ?? $entity->id ?? $entity->reference ?? $entity->number ?? 'N/A';
        
        // Créer la notification de manière synchrone pour garantir sa création en base
        try {
            $this->createNotificationSync([
                'user_id' => $userId,
                'title' => "Rejet {$entityName}",
                'message' => "Votre {$entityName} #{$identifier} a été rejetée. Raison: {$reason}",
                'type' => 'error',
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null,
                'action_route' => "/{$entityType}s/{$entity->id}",
                'metadata' => ['reason' => $reason],
            ]);
            \Log::info("Notification de rejet créée pour l'utilisateur", [
                'user_id' => $userId,
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null
            ]);
        } catch (\Exception $e) {
            \Log::error("Erreur lors de la création de la notification de rejet", [
                'error' => $e->getMessage(),
                'user_id' => $userId,
                'entity_type' => $entityType,
                'entity_id' => $entity->id ?? null
            ]);
        }
    }
}

