<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;
use Pusher\Pusher;

class NotificationService
{
    private $pusher;

    public function __construct()
    {
        try {
            $this->pusher = new Pusher(
                config('broadcasting.connections.pusher.key'),
                config('broadcasting.connections.pusher.secret'),
                config('broadcasting.connections.pusher.app_id'),
                [
                    'cluster' => config('broadcasting.connections.pusher.options.cluster'),
                    'useTLS' => true
                ]
            );
        } catch (\Exception $e) {
            // Pusher non disponible, continuer sans
            $this->pusher = null;
        }
    }

    /**
     * Créer une notification et l'envoyer en temps réel
     */
    public function createAndBroadcast($userId, $type, $titre, $message, $data = [], $priorite = 'normale', $canal = 'app')
    {
        // Créer la notification en base
        $notification = Notification::create([
            'user_id' => $userId,
            'type' => $type,
            'titre' => $titre,
            'message' => $message,
            'data' => $data,
            'priorite' => $priorite,
            'canal' => $canal
        ]);

        // Envoyer en temps réel
        $this->broadcastToUser($userId, $notification);

        return $notification;
    }

    /**
     * Envoyer une notification à un utilisateur spécifique
     */
    public function broadcastToUser($userId, $notification)
    {
        // WebSockets désactivés pour le moment
        // Les notifications sont stockées en base de données
        \Log::info("Notification envoyée à l'utilisateur {$userId}: " . $notification->titre);
    }

    /**
     * Envoyer une notification à tous les utilisateurs d'un rôle
     */
    public function broadcastToRole($role, $type, $titre, $message, $data = [], $priorite = 'normale')
    {
        $users = User::where('role', $role)->get();
        
        foreach ($users as $user) {
            $this->createAndBroadcast($user->id, $type, $titre, $message, $data, $priorite);
        }
    }

    /**
     * Envoyer une notification à tous les RH
     */
    public function broadcastToRH($type, $titre, $message, $data = [], $priorite = 'normale')
    {
        $this->broadcastToRole(4, $type, $titre, $message, $data, $priorite);
    }

    /**
     * Envoyer une notification à tous les admins
     */
    public function broadcastToAdmins($type, $titre, $message, $data = [], $priorite = 'normale')
    {
        $this->broadcastToRole(1, $type, $titre, $message, $data, $priorite);
    }

    /**
     * Envoyer une notification à tous les patrons
     */
    public function broadcastToPatrons($type, $titre, $message, $data = [], $priorite = 'normale')
    {
        $this->broadcastToRole(6, $type, $titre, $message, $data, $priorite);
    }

    /**
     * Notification de nouveau pointage
     */
    public function notifyNewPointage($pointage)
    {
        $this->broadcastToRH(
            'pointage',
            'Nouveau pointage',
            "{$pointage->user->nom} {$pointage->user->prenom} a pointé",
            [
                'pointage_id' => $pointage->id,
                'user_id' => $pointage->user_id,
                'type_pointage' => $pointage->type_pointage,
                'date_pointage' => $pointage->date_pointage
            ],
            'normale'
        );
    }

    /**
     * Notification de validation de pointage
     */
    public function notifyPointageValidated($pointage)
    {
        $this->createAndBroadcast(
            $pointage->user_id,
            'pointage',
            'Pointage validé',
            'Votre pointage a été validé',
            [
                'pointage_id' => $pointage->id,
                'type_pointage' => $pointage->type_pointage,
                'date_pointage' => $pointage->date_pointage
            ],
            'normale'
        );
    }

    /**
     * Notification de rejet de pointage
     */
    public function notifyPointageRejected($pointage)
    {
        $this->createAndBroadcast(
            $pointage->user_id,
            'pointage',
            'Pointage rejeté',
            'Votre pointage a été rejeté',
            [
                'pointage_id' => $pointage->id,
                'type_pointage' => $pointage->type_pointage,
                'date_pointage' => $pointage->date_pointage,
                'raison' => $pointage->commentaire
            ],
            'normale'
        );
    }

    /**
     * Notification de nouveau congé
     */
    public function notifyNewConge($conge)
    {
        $this->broadcastToRH(
            'conge',
            'Nouvelle demande de congé',
            "{$conge->user->nom} {$conge->user->prenom} a demandé un congé",
            [
                'conge_id' => $conge->id,
                'user_id' => $conge->user_id,
                'type_conge' => $conge->type_conge,
                'date_debut' => $conge->date_debut,
                'date_fin' => $conge->date_fin,
                'urgent' => $conge->urgent
            ],
            $conge->urgent ? 'urgente' : 'normale'
        );
    }

    /**
     * Notification d'approbation de congé
     */
    public function notifyCongeApproved($conge)
    {
        $this->createAndBroadcast(
            $conge->user_id,
            'conge',
            'Congé approuvé',
            'Votre demande de congé a été approuvée',
            [
                'conge_id' => $conge->id,
                'type_conge' => $conge->type_conge,
                'date_debut' => $conge->date_debut,
                'date_fin' => $conge->date_fin,
                'commentaire' => $conge->commentaire_rh
            ],
            'normale'
        );
    }

    /**
     * Notification de rejet de congé
     */
    public function notifyCongeRejected($conge)
    {
        $this->createAndBroadcast(
            $conge->user_id,
            'conge',
            'Congé rejeté',
            'Votre demande de congé a été rejetée',
            [
                'conge_id' => $conge->id,
                'type_conge' => $conge->type_conge,
                'date_debut' => $conge->date_debut,
                'date_fin' => $conge->date_fin,
                'raison' => $conge->raison_rejet
            ],
            'normale'
        );
    }

    /**
     * Notification de nouvelle évaluation
     */
    public function notifyNewEvaluation($evaluation)
    {
        $this->createAndBroadcast(
            $evaluation->user_id,
            'evaluation',
            'Nouvelle évaluation',
            'Une nouvelle évaluation vous a été assignée',
            [
                'evaluation_id' => $evaluation->id,
                'type_evaluation' => $evaluation->type_evaluation,
                'date_evaluation' => $evaluation->date_evaluation,
                'evaluateur' => $evaluation->evaluateur->nom . ' ' . $evaluation->evaluateur->prenom
            ],
            'normale'
        );
    }

    /**
     * Notification d'évaluation finalisée
     */
    public function notifyEvaluationFinalized($evaluation)
    {
        $this->createAndBroadcast(
            $evaluation->user_id,
            'evaluation',
            'Évaluation finalisée',
            'Votre évaluation a été finalisée',
            [
                'evaluation_id' => $evaluation->id,
                'type_evaluation' => $evaluation->type_evaluation,
                'note_globale' => $evaluation->note_globale,
                'date_evaluation' => $evaluation->date_evaluation
            ],
            'normale'
        );
    }

    /**
     * Notification de signature d'évaluation
     */
    public function notifyEvaluationSigned($evaluation, $signer)
    {
        $this->createAndBroadcast(
            $evaluation->evaluateur_id,
            'evaluation',
            'Évaluation signée',
            "L'évaluation a été signée par {$signer}",
            [
                'evaluation_id' => $evaluation->id,
                'user_id' => $evaluation->user_id,
                'signer' => $signer
            ],
            'normale'
        );
    }

    /**
     * Notification de nouveau client
     */
    public function notifyNewClient($client)
    {
        $this->broadcastToRole(2, 'client', 'Nouveau client', "Un nouveau client a été ajouté: {$client->nom} {$client->prenom}", [
            'client_id' => $client->id,
            'nom' => $client->nom,
            'prenom' => $client->prenom,
            'email' => $client->email
        ], 'normale');
    }

    /**
     * Notification de validation de client
     */
    public function notifyClientValidated($client)
    {
        $this->createAndBroadcast(
            $client->user_id,
            'client',
            'Client validé',
            'Votre client a été validé',
            [
                'client_id' => $client->id,
                'nom' => $client->nom,
                'prenom' => $client->prenom
            ],
            'normale'
        );
    }

    /**
     * Notification de rejet de client
     */
    public function notifyClientRejected($client)
    {
        $this->createAndBroadcast(
            $client->user_id,
            'client',
            'Client rejeté',
            'Votre client a été rejeté',
            [
                'client_id' => $client->id,
                'nom' => $client->nom,
                'prenom' => $client->prenom,
                'raison' => $client->commentaire_rejet
            ],
            'normale'
        );
    }

    /**
     * Notification de nouveau paiement
     */
    public function notifyNewPayment($paiement)
    {
        $this->broadcastToRole(3, 'paiement', 'Nouveau paiement', "Un nouveau paiement a été enregistré", [
            'paiement_id' => $paiement->id,
            'montant' => $paiement->montant,
            'date_paiement' => $paiement->date_paiement
        ], 'normale');
    }

    /**
     * Notification de validation de paiement
     */
    public function notifyPaymentValidated($paiement)
    {
        $this->createAndBroadcast(
            $paiement->user_id ?? 1, // Si pas d'utilisateur associé, envoyer à l'admin
            'paiement',
            'Paiement validé',
            'Le paiement a été validé',
            [
                'paiement_id' => $paiement->id,
                'montant' => $paiement->montant,
                'date_paiement' => $paiement->date_paiement
            ],
            'normale'
        );
    }

    /**
     * Notification système
     */
    public function notifySystem($message, $priorite = 'normale')
    {
        $this->broadcastToAdmins(
            'systeme',
            'Notification système',
            $message,
            [],
            $priorite
        );
    }

    /**
     * Notification de maintenance
     */
    public function notifyMaintenance($message, $dateDebut, $dateFin)
    {
        $this->broadcastToRole(1, 'systeme', 'Maintenance programmée', $message, [
            'date_debut' => $dateDebut,
            'date_fin' => $dateFin,
            'type' => 'maintenance'
        ], 'haute');
    }
}

