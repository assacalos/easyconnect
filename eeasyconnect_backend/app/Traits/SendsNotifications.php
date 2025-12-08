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
            return;
        }

        $identifier = $entityIdentifier ?? $entity->id ?? $entity->reference ?? $entity->number ?? 'N/A';
        
        $this->createNotification([
            'user_id' => $approver->id,
            'title' => "Soumission {$entityName}",
            'message' => "{$entityName} #{$identifier} a été soumise pour validation",
            'type' => 'info',
            'entity_type' => $entityType,
            'entity_id' => $entity->id ?? null,
            'action_route' => "/{$entityType}s/{$entity->id}",
        ]);
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
            return;
        }

        $identifier = $entityIdentifier ?? $entity->id ?? $entity->reference ?? $entity->number ?? 'N/A';
        
        $this->createNotification([
            'user_id' => $userId,
            'title' => "Approbation {$entityName}",
            'message' => "Votre {$entityName} #{$identifier} a été approuvée",
            'type' => 'success',
            'entity_type' => $entityType,
            'entity_id' => $entity->id ?? null,
            'action_route' => "/{$entityType}s/{$entity->id}",
        ]);
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
            return;
        }

        $identifier = $entityIdentifier ?? $entity->id ?? $entity->reference ?? $entity->number ?? 'N/A';
        
        $this->createNotification([
            'user_id' => $userId,
            'title' => "Rejet {$entityName}",
            'message' => "Votre {$entityName} #{$identifier} a été rejetée. Raison: {$reason}",
            'type' => 'error',
            'entity_type' => $entityType,
            'entity_id' => $entity->id ?? null,
            'action_route' => "/{$entityType}s/{$entity->id}",
            'metadata' => ['reason' => $reason],
        ]);
    }
}

