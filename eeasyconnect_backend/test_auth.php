<?php

// Script de test pour vérifier l'authentification
$baseUrl = 'http://localhost:8000/api';

echo "=== Test de l'Authentification ===\n\n";

// Test 1: Connexion avec des identifiants valides
echo "1. Test de connexion avec des identifiants valides...\n";
$loginData = [
    'email' => 'admin@example.com',
    'password' => 'password'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code HTTP: $httpCode\n";
echo "Réponse: $response\n\n";

if ($httpCode === 200) {
    $data = json_decode($response, true);
    if (isset($data['token'])) {
        $token = $data['token'];
        echo "✅ Connexion réussie! Token obtenu: " . substr($token, 0, 20) . "...\n\n";
        
        // Test 2: Accès à une route protégée
        echo "2. Test d'accès à une route protégée (/me)...\n";
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/me');
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $token,
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Code HTTP: $httpCode\n";
        echo "Réponse: $response\n\n";
        
        if ($httpCode === 200) {
            echo "✅ Accès à la route protégée réussi!\n\n";
        } else {
            echo "❌ Échec de l'accès à la route protégée\n\n";
        }
        
        // Test 3: Accès à une route avec middleware de rôle
        echo "3. Test d'accès à une route avec middleware de rôle...\n";
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/hr/employees');
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $token,
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Code HTTP: $httpCode\n";
        echo "Réponse: $response\n\n";
        
        if ($httpCode === 200) {
            echo "✅ Accès à la route avec middleware de rôle réussi!\n\n";
        } else {
            echo "❌ Échec de l'accès à la route avec middleware de rôle\n\n";
        }
        
        // Test 4: Déconnexion
        echo "4. Test de déconnexion...\n";
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $baseUrl . '/logout');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $token,
            'Accept: application/json'
        ]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "Code HTTP: $httpCode\n";
        echo "Réponse: $response\n\n";
        
        if ($httpCode === 200) {
            echo "✅ Déconnexion réussie!\n\n";
        } else {
            echo "❌ Échec de la déconnexion\n\n";
        }
        
    } else {
        echo "❌ Token non trouvé dans la réponse\n\n";
    }
} else {
    echo "❌ Échec de la connexion\n\n";
}

// Test 5: Connexion avec des identifiants invalides
echo "5. Test de connexion avec des identifiants invalides...\n";
$invalidLoginData = [
    'email' => 'invalid@example.com',
    'password' => 'wrongpassword'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/login');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($invalidLoginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code HTTP: $httpCode\n";
echo "Réponse: $response\n\n";

if ($httpCode === 401) {
    echo "✅ Rejet des identifiants invalides correct!\n\n";
} else {
    echo "❌ Les identifiants invalides ont été acceptés (problème de sécurité!)\n\n";
}

// Test 6: Accès à une route protégée sans token
echo "6. Test d'accès à une route protégée sans token...\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $baseUrl . '/me');
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code HTTP: $httpCode\n";
echo "Réponse: $response\n\n";

if ($httpCode === 401) {
    echo "✅ Accès refusé sans token (sécurité correcte!)\n\n";
} else {
    echo "❌ Accès autorisé sans token (problème de sécurité!)\n\n";
}

echo "=== Fin des tests ===\n";
?>

