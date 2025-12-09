# Commandes de Déploiement - Notifications

## Commandes à exécuter sur le serveur après déploiement

### 1. Mettre à jour les dépendances (si nécessaire)

```bash
composer install --no-dev --optimize-autoloader
```

**Note** : Utilisez `composer update` uniquement si vous avez modifié `composer.json`

---

### 2. Vider tous les caches

```bash
# Vider le cache de configuration
php artisan config:clear

# Vider le cache de l'application
php artisan cache:clear

# Vider le cache des routes
php artisan route:clear

# Vider le cache des vues
php artisan view:clear
```

**Alternative** : Tout vider en une commande
```bash
php artisan optimize:clear
```

---

### 3. Reconstruire les caches (recommandé pour la production)

```bash
# Cache de configuration
php artisan config:cache

# Cache des routes
php artisan route:cache

# Cache des vues
php artisan view:cache
```

**Ou en une seule commande** :
```bash
php artisan optimize
```

---

### 4. Redémarrer les workers de queue (si vous utilisez les queues)

Si vous utilisez des queues pour les notifications (via `SendNotificationJob`), redémarrez les workers :

```bash
# Arrêter les workers existants
php artisan queue:restart

# Redémarrer les workers (selon votre configuration)
# Exemple avec supervisor :
sudo supervisorctl restart laravel-worker:*

# Ou si vous utilisez systemd :
sudo systemctl restart laravel-worker
```

**Note** : Si vous n'utilisez pas de queues, les notifications sont créées de manière synchrone et cette étape n'est pas nécessaire.

---

### 5. Vérifier les permissions (si nécessaire)

```bash
# Permissions pour storage
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Ou selon votre configuration utilisateur
chown -R votre-utilisateur:votre-groupe storage bootstrap/cache
```

---

### 6. Vérifier que le lien symbolique existe

```bash
# Vérifier si le lien existe
ls -la public/storage

# Si le lien n'existe pas, le créer
php artisan storage:link
```

---

## Script complet de déploiement

Vous pouvez créer un script `deploy.sh` :

```bash
#!/bin/bash

echo "🚀 Déploiement des notifications..."

# 1. Mettre à jour les dépendances
echo "📦 Mise à jour des dépendances..."
composer install --no-dev --optimize-autoloader

# 2. Vider les caches
echo "🧹 Nettoyage des caches..."
php artisan optimize:clear

# 3. Reconstruire les caches
echo "⚡ Optimisation de l'application..."
php artisan optimize

# 4. Redémarrer les workers de queue
echo "🔄 Redémarrage des workers de queue..."
php artisan queue:restart

# 5. Vérifier le lien symbolique
if [ ! -L "public/storage" ]; then
    echo "🔗 Création du lien symbolique..."
    php artisan storage:link
fi

echo "✅ Déploiement terminé !"
```

**Pour rendre le script exécutable** :
```bash
chmod +x deploy.sh
```

**Pour exécuter le script** :
```bash
./deploy.sh
```

---

## Commandes selon votre environnement

### Si vous utilisez Supervisor pour les queues

```bash
# Redémarrer tous les workers
sudo supervisorctl restart all

# Ou spécifiquement pour Laravel
sudo supervisorctl restart laravel-worker:*
```

### Si vous utilisez systemd

```bash
# Redémarrer le service
sudo systemctl restart laravel-worker
sudo systemctl status laravel-worker
```

### Si vous utilisez PM2

```bash
# Redémarrer l'application
pm2 restart all

# Ou spécifiquement
pm2 restart laravel-worker
```

---

## Vérification post-déploiement

### 1. Tester une notification

Créer une entité (expense, leave request, etc.) et vérifier que :
- La notification est créée en base de données
- L'API `/api/notifications` retourne la notification
- Le worker de queue traite la notification (si queues activées)

### 2. Vérifier les logs

```bash
# Logs Laravel
tail -f storage/logs/laravel.log

# Logs des queues (si activées)
tail -f storage/logs/queue.log
```

### 3. Tester l'API

```bash
# Tester la récupération des notifications
curl -X GET http://votre-domaine.com/api/notifications \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Accept: application/json"
```

---

## Commandes rapides (résumé)

```bash
# Déploiement rapide (production)
composer install --no-dev --optimize-autoloader && \
php artisan optimize:clear && \
php artisan optimize && \
php artisan queue:restart
```

---

## Notes importantes

1. **Pas de migrations nécessaires** : Aucune nouvelle migration n'a été créée aujourd'hui, donc `php artisan migrate` n'est pas nécessaire.

2. **Pas de nouvelles dépendances** : Aucune nouvelle dépendance Composer n'a été ajoutée.

3. **Queues optionnelles** : Si vous n'utilisez pas de queues (notifications synchrones), vous pouvez ignorer les commandes liées aux workers.

4. **Cache** : En production, il est recommandé d'utiliser les caches (`php artisan optimize`) pour de meilleures performances.

5. **Permissions** : Assurez-vous que les permissions sont correctes pour `storage/` et `bootstrap/cache/`.

---

## En cas de problème

### Si les notifications ne fonctionnent pas

1. Vérifier les logs :
```bash
tail -f storage/logs/laravel.log
```

2. Vérifier que le trait `SendsNotifications` est bien utilisé dans les contrôleurs

3. Vérifier que les routes API sont bien enregistrées :
```bash
php artisan route:list | grep notification
```

4. Tester manuellement la création d'une notification :
```bash
php artisan tinker
```
```php
$notification = \App\Models\Notification::create([
    'user_id' => 1,
    'title' => 'Test',
    'message' => 'Test notification',
    'type' => 'info',
]);
```

---

## Checklist de déploiement

- [ ] `composer install --no-dev --optimize-autoloader`
- [ ] `php artisan optimize:clear`
- [ ] `php artisan optimize`
- [ ] `php artisan queue:restart` (si queues activées)
- [ ] Vérifier `public/storage` (lien symbolique)
- [ ] Vérifier les permissions `storage/` et `bootstrap/cache/`
- [ ] Tester une notification
- [ ] Vérifier les logs

---

## Support

Si vous rencontrez des problèmes après le déploiement, vérifiez :
1. Les logs Laravel (`storage/logs/laravel.log`)
2. Les logs du serveur web (Apache/Nginx)
3. Les logs des workers de queue (si activés)
4. La configuration de la base de données
5. Les permissions des fichiers et dossiers

