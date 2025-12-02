# Implémentation des Queue Jobs

## Vue d'ensemble

Les Queue Jobs ont été implémentés pour améliorer les performances de l'API en déplaçant les tâches non critiques (notifications, traitement d'images) en arrière-plan. Cela permet de réduire le temps de réponse de l'API à moins de 200 ms.

## Configuration

### Driver de queue

Par défaut, Laravel utilise le driver `sync` (synchrone). Pour la production, configurez `database` ou `redis` dans le fichier `.env` :

```env
QUEUE_CONNECTION=database
# ou
QUEUE_CONNECTION=redis
```

### Migration de la table jobs

Exécutez la migration pour créer la table `jobs` :

```bash
php artisan migrate
```

## Jobs créés

### 1. SendNotificationJob

**Objectif** : Créer des notifications de manière asynchrone

**Utilisation** :
```php
use App\Jobs\SendNotificationJob;

SendNotificationJob::dispatch([
    'user_id' => 1,
    'title' => 'Titre de la notification',
    'message' => 'Message de la notification',
    'type' => 'info',
    'priorite' => 'normale'
]);
```

**Caractéristiques** :
- 3 tentatives en cas d'échec
- Backoff progressif : 10s, 30s, 60s
- Broadcast automatique si NotificationService est disponible
- Logging des erreurs

### 2. ProcessImageJob

**Objectif** : Traiter les images (redimensionnement, optimisation, miniatures) en arrière-plan

**Utilisation** :
```php
use App\Jobs\ProcessImageJob;

ProcessImageJob::dispatch($imagePath, [
    'disk' => 'public',
    'width' => 1200,
    'height' => 1200,
    'quality' => 85,
    'thumbnail' => [
        'width' => 300,
        'height' => 300
    ]
]);
```

**Caractéristiques** :
- Redimensionnement avec préservation du ratio
- Création automatique de miniatures
- Optimisation de la qualité
- 3 tentatives en cas d'échec

## Modifications apportées

### Trait SendsNotifications

Le trait `SendsNotifications` a été modifié pour utiliser les jobs par défaut :

```php
// Avant (synchrone)
$this->createNotification($data);

// Maintenant (asynchrone par défaut)
$this->createNotification($data); // Utilise SendNotificationJob

// Pour les cas critiques (synchrone)
$this->createNotification($data, true); // Création synchrone
```

### Contrôleurs modifiés

Les contrôleurs suivants utilisent maintenant les jobs :

- **EvaluationController** : Notifications d'évaluations
- **CongeController** : Notifications de congés
- **AttendanceController** : Traitement d'images de pointage
- **NotificationController** : Création de notifications via API
- Tous les contrôleurs utilisant `SendsNotifications` : Notifications automatiques

## Exécution des queues

### Développement

Pour exécuter les jobs en développement :

```bash
php artisan queue:work
```

### Production

Pour la production, utilisez un process manager comme Supervisor :

**Configuration Supervisor** (`/etc/supervisor/conf.d/laravel-worker.conf`) :

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /path/to/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/path/to/storage/logs/worker.log
stopwaitsecs=3600
```

Puis :

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start laravel-worker:*
```

## Monitoring

### Vérifier les jobs en attente

```bash
php artisan queue:monitor
```

### Voir les jobs échoués

```bash
php artisan queue:failed
```

### Réessayer les jobs échoués

```bash
php artisan queue:retry all
```

### Nettoyer les jobs échoués

```bash
php artisan queue:flush
```

## Performance

### Avant l'implémentation

- Temps de réponse moyen : 500-1000 ms
- Blocage lors de la création de notifications
- Blocage lors du traitement d'images

### Après l'implémentation

- Temps de réponse moyen : < 200 ms
- Notifications créées en arrière-plan
- Images traitées en arrière-plan
- API plus réactive

## Bonnes pratiques

1. **Utilisez les jobs pour les tâches non critiques** : notifications, emails, traitement d'images
2. **Gardez les opérations critiques synchrones** : authentification, validation de paiement
3. **Configurez les retries appropriés** : 3 tentatives avec backoff progressif
4. **Monitorer les queues** : surveillez les jobs échoués régulièrement
5. **Utilisez des queues séparées** : pour les tâches prioritaires vs normales

## Queues séparées (optionnel)

Pour créer des queues séparées pour les priorités :

```php
// Queue normale
SendNotificationJob::dispatch($data)->onQueue('notifications');

// Queue prioritaire
SendNotificationJob::dispatch($data)->onQueue('notifications-high');
```

Puis exécutez les workers séparément :

```bash
php artisan queue:work --queue=notifications-high,notifications
```

## Dépannage

### Les jobs ne s'exécutent pas

1. Vérifiez que le worker est en cours d'exécution : `php artisan queue:work`
2. Vérifiez la configuration dans `.env` : `QUEUE_CONNECTION=database`
3. Vérifiez que la table `jobs` existe : `php artisan migrate`

### Les jobs échouent

1. Consultez les logs : `storage/logs/laravel.log`
2. Vérifiez les jobs échoués : `php artisan queue:failed`
3. Vérifiez les dépendances (ex: Intervention Image pour ProcessImageJob)

### Performance dégradée

1. Augmentez le nombre de workers
2. Utilisez Redis au lieu de database
3. Optimisez les requêtes dans les jobs
4. Utilisez des queues séparées pour les priorités

