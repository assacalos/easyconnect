<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// Canal pour les notifications en temps réel
Broadcast::channel('user.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Canal pour les notifications globales (admin)
Broadcast::channel('notifications', function ($user) {
    return $user->role == 1; // Seuls les admins
});

// Canal pour les notifications RH
Broadcast::channel('hr-notifications', function ($user) {
    return in_array($user->role, [1, 4]); // Admin et RH
});

// Canal pour les notifications techniques
Broadcast::channel('tech-notifications', function ($user) {
    return in_array($user->role, [1, 5]); // Admin et Technicien
});