<?php

/**
 * Script de test simple pour les notifications avec queue
 * 
 * Utilisation :
 * 1. Assurez-vous que le worker tourne : php artisan queue:work
 * 2. Exécutez ce script : php test-notification-simple.php
 * 3. Vérifiez la table 'notifications' dans votre base de données
 */

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use App\Jobs\SendNotificationJob;
use App\Models\User;

echo "🚀 Test de notification avec queue\n";
echo str_repeat("=", 50) . "\n\n";

// Vérifier la configuration
$queueConnection = config('queue.default');
echo "📋 Configuration : QUEUE_CONNECTION={$queueConnection}\n";

if ($queueConnection === 'sync') {
    echo "⚠️  Mode 'sync' : Les notifications seront traitées immédiatement\n";
} else {
    echo "✅ Mode '{$queueConnection}' : Les notifications seront mises en queue\n";
    echo "⚠️  Assurez-vous que le worker tourne : php artisan queue:work\n";
}

echo "\n";

// Récupérer le premier utilisateur disponible
$user = User::first();

if (!$user) {
    echo "❌ Aucun utilisateur trouvé dans la base de données !\n";
    echo "💡 Créez d'abord un utilisateur.\n";
    exit(1);
}

echo "👤 Utilisateur sélectionné : {$user->name} (ID: {$user->id})\n\n";

// Créer une notification de test
$notificationData = [
    'user_id' => $user->id,
    'title' => 'Test de Queue - ' . date('H:i:s'),
    'message' => 'Cette notification a été créée via une queue ! Si vous voyez cette notification en base, c\'est que ça fonctionne ! 🎉',
    'type' => 'info',
    'priorite' => 'normale',
    'data' => [
        'test' => true,
        'timestamp' => now()->toDateTimeString()
    ]
];

echo "📤 Envoi de la notification à la queue...\n";
SendNotificationJob::dispatch($notificationData);
echo "✅ Notification envoyée !\n\n";

if ($queueConnection === 'sync') {
    echo "💡 La notification a été créée immédiatement en base de données.\n";
} else {
    echo "💡 La notification est maintenant dans la table 'jobs'.\n";
    echo "💡 Le worker va la traiter automatiquement.\n";
}

echo "\n";
echo "📊 Pour vérifier :\n";
echo "   SELECT * FROM notifications WHERE user_id = {$user->id} ORDER BY created_at DESC LIMIT 1;\n";
echo "\n";
echo "✅ Test terminé !\n";

