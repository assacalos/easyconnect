<?php

namespace App\Services;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PushNotificationService
{
    /**
     * URL de l'API Firebase Cloud Messaging
     */
    protected $fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    /**
     * Clé serveur FCM (à configurer dans .env)
     */
    protected $serverKey;

    public function __construct()
    {
        $this->serverKey = config('services.fcm.server_key');
    }

    /**
     * Envoyer une notification push à un utilisateur
     * 
     * @param int $userId ID de l'utilisateur
     * @param string $title Titre de la notification
     * @param string $body Corps de la notification
     * @param array $data Données supplémentaires (optionnel)
     * @param array $options Options supplémentaires (optionnel)
     * @return array Résultat de l'envoi
     */
    public function sendToUser($userId, $title, $body, $data = [], $options = [])
    {
        $user = User::find($userId);
        if (!$user) {
            Log::warning("Utilisateur introuvable pour l'envoi de notification push", ['user_id' => $userId]);
            return ['success' => false, 'message' => 'Utilisateur introuvable'];
        }

        // Récupérer tous les tokens actifs de l'utilisateur
        $tokens = $user->activeDeviceTokens()->pluck('token')->toArray();

        if (empty($tokens)) {
            Log::info("Aucun token d'appareil actif pour l'utilisateur", ['user_id' => $userId]);
            return ['success' => false, 'message' => 'Aucun token d\'appareil actif'];
        }

        return $this->sendToTokens($tokens, $title, $body, $data, $options);
    }

    /**
     * Envoyer une notification push à plusieurs tokens
     * 
     * @param array|string $tokens Token(s) FCM
     * @param string $title Titre de la notification
     * @param string $body Corps de la notification
     * @param array $data Données supplémentaires (optionnel)
     * @param array $options Options supplémentaires (optionnel)
     * @return array Résultat de l'envoi
     */
    public function sendToTokens($tokens, $title, $body, $data = [], $options = [])
    {
        if (empty($this->serverKey)) {
            Log::error("Clé serveur FCM non configurée");
            return ['success' => false, 'message' => 'Clé serveur FCM non configurée'];
        }

        // Convertir en tableau si c'est une chaîne
        if (is_string($tokens)) {
            $tokens = [$tokens];
        }

        // Préparer le payload FCM
        $payload = [
            'notification' => [
                'title' => $title,
                'body' => $body,
                'sound' => $options['sound'] ?? 'default',
                'badge' => $options['badge'] ?? null,
            ],
            'data' => array_merge([
                'title' => $title,
                'body' => $body,
                'click_action' => $options['click_action'] ?? 'FLUTTER_NOTIFICATION_CLICK',
            ], $data),
            'priority' => $options['priority'] ?? 'high',
        ];

        $results = [];
        $successCount = 0;
        $failureCount = 0;

        // Si un seul token, envoyer directement
        if (count($tokens) === 1) {
            $payload['to'] = $tokens[0];
            $result = $this->sendFcmRequest($payload);
            $results[] = $result;
            
            if ($result['success']) {
                $successCount++;
                // Marquer le token comme utilisé
                $this->markTokenAsUsed($tokens[0]);
            } else {
                $failureCount++;
                // Si le token est invalide, le désactiver
                if (isset($result['error']) && $this->isInvalidTokenError($result['error'])) {
                    $this->deactivateToken($tokens[0]);
                }
            }
        } else {
            // Pour plusieurs tokens, utiliser l'API multicast (jusqu'à 1000 tokens)
            $chunks = array_chunk($tokens, 1000);
            
            foreach ($chunks as $chunk) {
                $payload['registration_ids'] = $chunk;
                $result = $this->sendFcmRequest($payload);
                
                if ($result['success'] && isset($result['response']['results'])) {
                    foreach ($result['response']['results'] as $index => $tokenResult) {
                        if (isset($tokenResult['message_id'])) {
                            $successCount++;
                            $this->markTokenAsUsed($chunk[$index]);
                        } else {
                            $failureCount++;
                            if (isset($tokenResult['error']) && $this->isInvalidTokenError($tokenResult['error'])) {
                                $this->deactivateToken($chunk[$index]);
                            }
                        }
                    }
                } else {
                    $failureCount += count($chunk);
                }
                
                $results[] = $result;
            }
        }

        return [
            'success' => $successCount > 0,
            'success_count' => $successCount,
            'failure_count' => $failureCount,
            'total' => count($tokens),
            'results' => $results,
        ];
    }

    /**
     * Envoyer une requête à l'API FCM
     * 
     * @param array $payload Payload FCM
     * @return array Résultat de la requête
     */
    protected function sendFcmRequest($payload)
    {
        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $this->serverKey,
                'Content-Type' => 'application/json',
            ])->post($this->fcmUrl, $payload);

            if ($response->successful()) {
                $responseData = $response->json();
                Log::info("Notification push envoyée avec succès", [
                    'success' => $responseData['success'] ?? 0,
                    'failure' => $responseData['failure'] ?? 0,
                ]);
                
                return [
                    'success' => true,
                    'response' => $responseData,
                ];
            } else {
                Log::error("Erreur lors de l'envoi de notification push", [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
                
                return [
                    'success' => false,
                    'error' => 'Erreur HTTP: ' . $response->status(),
                    'response' => $response->json(),
                ];
            }
        } catch (\Exception $e) {
            Log::error("Exception lors de l'envoi de notification push", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);
            
            return [
                'success' => false,
                'error' => $e->getMessage(),
            ];
        }
    }

    /**
     * Vérifier si l'erreur indique un token invalide
     * 
     * @param string $error Message d'erreur
     * @return bool
     */
    protected function isInvalidTokenError($error)
    {
        $invalidTokenErrors = [
            'InvalidRegistration',
            'NotRegistered',
            'MismatchSenderId',
        ];
        
        return in_array($error, $invalidTokenErrors);
    }

    /**
     * Marquer un token comme utilisé
     * 
     * @param string $token Token FCM
     * @return void
     */
    protected function markTokenAsUsed($token)
    {
        DeviceToken::where('token', $token)->update(['last_used_at' => now()]);
    }

    /**
     * Désactiver un token invalide
     * 
     * @param string $token Token FCM
     * @return void
     */
    protected function deactivateToken($token)
    {
        DeviceToken::where('token', $token)->update(['is_active' => false]);
        Log::info("Token d'appareil désactivé (invalide)", ['token' => substr($token, 0, 20) . '...']);
    }

    /**
     * Enregistrer ou mettre à jour un token d'appareil
     * 
     * @param int $userId ID de l'utilisateur
     * @param string $token Token FCM
     * @param array $deviceInfo Informations sur l'appareil (optionnel)
     * @return DeviceToken
     */
    public function registerDeviceToken($userId, $token, $deviceInfo = [])
    {
        return DeviceToken::updateOrCreate(
            [
                'user_id' => $userId,
                'token' => $token,
            ],
            [
                'device_type' => $deviceInfo['device_type'] ?? null,
                'device_id' => $deviceInfo['device_id'] ?? null,
                'app_version' => $deviceInfo['app_version'] ?? null,
                'is_active' => true,
                'last_used_at' => now(),
            ]
        );
    }

    /**
     * Supprimer un token d'appareil
     * 
     * @param int $userId ID de l'utilisateur
     * @param string $token Token FCM (optionnel, si non fourni, supprime tous les tokens de l'utilisateur)
     * @return bool
     */
    public function unregisterDeviceToken($userId, $token = null)
    {
        $query = DeviceToken::where('user_id', $userId);
        
        if ($token) {
            $query->where('token', $token);
        }
        
        return $query->delete();
    }
}

