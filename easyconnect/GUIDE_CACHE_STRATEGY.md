# Guide de Stratégie de Cache avec Protection Réseau

## Principe Fondamental

**Toujours envelopper les appels API dans un try/catch pour que, même si le réseau échoue, l'utilisateur puisse voir les données en cache.**

## Pattern Recommandé

```dart
Future<void> loadData() async {
  try {
    // 1. Afficher immédiatement les données du cache si disponibles
    final cacheKey = 'data_key';
    final cachedData = CacheHelper.get<List<DataType>>(cacheKey);
    if (cachedData != null && cachedData.isNotEmpty) {
      dataList.assignAll(cachedData);
      isLoading.value = false; // Permettre l'affichage immédiat
    } else {
      isLoading.value = true;
    }

    // 2. Charger les données fraîches depuis l'API (enveloppé dans try/catch)
    final freshData = await _service.getData();
    
    // 3. Mettre à jour avec les données fraîches
    dataList.assignAll(freshData);
    
    // 4. Sauvegarder dans le cache pour la prochaine fois
    CacheHelper.set(cacheKey, freshData);
  } catch (e) {
    // 5. En cas d'erreur réseau, vérifier le cache
    if (dataList.isEmpty) {
      final cacheKey = 'data_key';
      final cachedData = CacheHelper.get<List<DataType>>(cacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        // Charger les données du cache si disponibles
        dataList.assignAll(cachedData);
        // Ne pas afficher d'erreur si on a des données en cache
        return;
      }
    }

    // 6. Afficher l'erreur seulement si aucune donnée n'est disponible
    if (dataList.isEmpty) {
      // Afficher un message d'erreur approprié
      Get.snackbar('Erreur', 'Impossible de charger les données');
    }
  } finally {
    isLoading.value = false;
  }
}
```

## Points Clés

### 1. Affichage Immédiat du Cache
- Vérifier le cache **AVANT** l'appel API
- Afficher les données en cache immédiatement pour une meilleure UX
- Mettre `isLoading.value = false` si on a du cache

### 2. Protection Try/Catch
- **TOUJOURS** envelopper l'appel API dans un try/catch
- Ne pas laisser les erreurs réseau planter l'application
- Permettre à l'utilisateur de voir les données en cache même en cas d'échec réseau

### 3. Vérification du Cache en Cas d'Erreur
- Dans le bloc `catch`, vérifier le cache si la liste est vide
- Charger les données du cache si disponibles
- Ne pas afficher d'erreur si on a des données en cache

### 4. Gestion des Erreurs
- Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
- Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
- Afficher l'erreur seulement si aucune donnée n'est disponible

## Exemples d'Implémentation

### ✅ Bon Exemple (PaymentController)

```dart
Future<void> loadPayments() async {
  try {
    // Afficher immédiatement les données du cache
    final cacheKey = 'payments_${user.role}_${status}';
    final cachedPayments = CacheHelper.get<List<PaymentModel>>(cacheKey);
    if (cachedPayments != null && cachedPayments.isNotEmpty) {
      payments.assignAll(cachedPayments);
      isLoading.value = false;
    } else {
      isLoading.value = true;
    }

    // Charger depuis l'API (protégé par try/catch)
    final paymentList = await _paymentService.getAllPayments();
    payments.value = paymentList;
    CacheHelper.set(cacheKey, paymentList);
  } catch (e) {
    // Vérifier le cache en cas d'erreur
    if (payments.isEmpty) {
      final cacheKey = 'payments_${user.role}_${status}';
      final cachedPayments = CacheHelper.get<List<PaymentModel>>(cacheKey);
      if (cachedPayments != null && cachedPayments.isNotEmpty) {
        payments.assignAll(cachedPayments);
        return; // Ne pas afficher d'erreur
      }
    }
    // Afficher l'erreur seulement si aucune donnée n'est disponible
  } finally {
    isLoading.value = false;
  }
}
```

### ✅ Bon Exemple (ClientController)

```dart
Future<void> loadClients() async {
  try {
    // Afficher immédiatement les données du cache
    final cacheKey = 'clients_${status}';
    final cachedClients = CacheHelper.get<List<Client>>(cacheKey);
    if (cachedClients != null && cachedClients.isNotEmpty) {
      clients.assignAll(cachedClients);
      isLoading.value = false;
    } else {
      isLoading.value = true;
    }

    // Charger depuis l'API (protégé par try/catch interne)
    List<Client>? loadedClients;
    try {
      loadedClients = await _clientService.getClients();
      clients.assignAll(loadedClients);
    } catch (e) {
      // Si le chargement échoue mais qu'on a du cache, on garde le cache
      if (cachedClients == null) {
        rethrow; // Relancer seulement si on n'avait pas de cache
      }
    }
  } catch (e) {
    // Vérifier le cache en cas d'erreur
    if (clients.isEmpty) {
      final cacheKey = 'clients_${status}';
      final cachedClients = CacheHelper.get<List<Client>>(cacheKey);
      if (cachedClients != null && cachedClients.isNotEmpty) {
        clients.assignAll(cachedClients);
      }
    }
  } finally {
    isLoading.value = false;
  }
}
```

## Contrôleurs Vérifiés

- ✅ **PaymentController** - Protection complète avec vérification du cache
- ✅ **ClientController** - Protection complète avec try/catch interne
- ✅ **InvoiceController** - Protection complète avec vérification du cache
- ✅ **DevisController** - Protection complète avec vérification du cache
- ✅ **SalaryController** - Protection complète avec vérification du cache
- ✅ **TaxController** - Protection complète avec vérification du cache
- ✅ **EmployeeController** - Protection complète avec vérification du cache (amélioré)

## Checklist pour Nouveaux Contrôleurs

- [ ] Import de `CacheHelper`
- [ ] Vérification du cache AVANT l'appel API
- [ ] Affichage immédiat des données en cache
- [ ] Appel API enveloppé dans try/catch
- [ ] Vérification du cache dans le bloc catch
- [ ] Ne pas afficher d'erreur si des données sont disponibles
- [ ] Sauvegarder dans le cache après un chargement réussi

## Avantages

1. **Meilleure UX** : L'utilisateur voit immédiatement les données en cache
2. **Résilience** : L'application fonctionne même en cas de problème réseau
3. **Performance** : Affichage instantané des données mises en cache
4. **Fiabilité** : Pas de crash en cas d'erreur réseau

