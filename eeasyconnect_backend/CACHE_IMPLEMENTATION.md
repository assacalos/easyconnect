# Implémentation du Cache

## Vue d'ensemble

Le système de cache a été implémenté pour améliorer les performances de l'application en mettant en cache les données qui changent rarement ou les statistiques quotidiennes.

## Configuration

### Driver de cache

Par défaut, Laravel utilise le driver `file`. Pour la production, configurez Redis ou Memcached dans le fichier `.env` :

```env
CACHE_DRIVER=redis
# ou
CACHE_DRIVER=memcached
```

### Durées de cache

Les durées de cache sont définies dans le trait `CachesData` :

- **Données statiques** (listes déroulantes) : 24 heures (86400 secondes)
- **Statistiques quotidiennes** : 1 heure (3600 secondes)
- **Statistiques horaires** : 30 minutes (1800 secondes)
- **Rôles/permissions** : 24 heures (86400 secondes)

## Utilisation

### Trait CachesData

Le trait `CachesData` fournit des méthodes helper pour mettre en cache les données :

```php
use App\Traits\CachesData;

class MonController extends Controller
{
    use CachesData;

    // Cache pour données statiques
    public function getTypes()
    {
        $types = $this->rememberStatic('types_key', function () {
            return ['type1', 'type2'];
        });
    }

    // Cache pour statistiques quotidiennes
    public function getStats()
    {
        $dateKey = Carbon::now()->format('Y-m-d');
        $stats = $this->rememberDailyStats('stats_key', $dateKey, function () {
            return $this->calculateStats();
        });
    }
}
```

## Données mises en cache

### 1. Listes déroulantes statiques

- **Types de congés** (`leave_types`) : Liste des types de congés disponibles
- **Types d'interventions** (`intervention_types`) : Liste des types d'interventions

### 2. Statistiques quotidiennes

Les statistiques sont mises en cache par date pour éviter les recalculs fréquents :

- **Dashboard** (`dashboard_stats`) : Statistiques générales du tableau de bord
- **Rapports financiers** (`financial_report`) : Statistiques financières
- **Rapports RH** (`hr_report`) : Statistiques des ressources humaines
- **Rapports commerciaux** (`commercial_report`) : Statistiques commerciales
- **Statistiques des clients** (`client_stats`) : Statistiques des clients
- **Statistiques des employés** (`employee_stats`) : Statistiques des employés
- **Statistiques des équipements** (`equipment_stats`) : Statistiques des équipements
- **Statistiques des congés** (`leave_stats`) : Statistiques des congés
- **Statistiques des interventions** (`intervention_stats`) : Statistiques des interventions

### 3. Rôles et permissions

- **Noms des rôles** (`role_name:{role_id}`) : Mapping des IDs de rôles vers leurs noms

## Invalidation du cache

### Invalidation manuelle

Pour invalider le cache manuellement :

```php
// Invalider une clé spécifique
$this->forgetCache('leave_types');

// Invalider un pattern (Redis uniquement)
$this->forgetCachePattern('stats:*');
```

### Invalidation automatique

Le cache est automatiquement invalidé après :
- 24 heures pour les données statiques
- 1 heure pour les statistiques quotidiennes
- 30 minutes pour les statistiques horaires

## Bonnes pratiques

1. **Utilisez des clés de cache descriptives** : `leave_types`, `dashboard_stats`, etc.
2. **Incluez la date dans les clés de statistiques** : `stats:2024-01-15`
3. **N'oubliez pas d'invalider le cache** lors de modifications importantes
4. **Testez en développement** avec `CACHE_DRIVER=array` pour éviter les effets de bord

## Commandes utiles

```bash
# Vider tout le cache
php artisan cache:clear

# Vider le cache de configuration
php artisan config:clear

# Vider le cache des routes
php artisan route:clear
```

## Performance

Avec le cache activé, les performances attendues sont :

- **Listes déroulantes** : Réduction de ~95% du temps de réponse
- **Statistiques quotidiennes** : Réduction de ~80-90% du temps de réponse
- **Rôles/permissions** : Réduction de ~90% du temps de réponse

## Notes de production

1. **Redis recommandé** : Pour la production, utilisez Redis comme driver de cache
2. **Monitoring** : Surveillez l'utilisation de la mémoire Redis
3. **TTL appropriés** : Ajustez les durées de cache selon vos besoins
4. **Cache warming** : Considérez le préchargement du cache au démarrage de l'application

