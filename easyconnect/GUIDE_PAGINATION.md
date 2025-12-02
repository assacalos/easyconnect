# Guide d'Implémentation de la Pagination Côté Serveur

## Vue d'ensemble

Ce guide explique comment implémenter la pagination côté serveur avec Laravel et la gérer côté Flutter.

## Structure

### 1. Côté Laravel (Backend)

#### Format de réponse attendu

Laravel doit retourner une réponse au format suivant :

```json
{
  "success": true,
  "data": {
    "data": [...],           // Les données de la page
    "current_page": 1,       // Page actuelle
    "last_page": 5,          // Dernière page
    "per_page": 15,          // Nombre d'items par page
    "total": 100,            // Total d'items
    "from": 1,               // Premier item de la page
    "to": 15,                // Dernier item de la page
    "first_page_url": "...", // URL première page
    "last_page_url": "...",  // URL dernière page
    "next_page_url": "...",  // URL page suivante (null si dernière page)
    "prev_page_url": null,   // URL page précédente (null si première page)
    "path": "..."            // Chemin de base
  }
}
```

#### Exemple de contrôleur Laravel

```php
public function index(Request $request): JsonResponse
{
    $perPage = $request->input('per_page', 15);
    
    $query = Employee::query();
    
    // Appliquer les filtres
    if ($request->has('search')) {
        $query->where('name', 'like', "%{$request->search}%");
    }
    
    // Pagination
    $employees = $query->paginate($perPage);
    
    return response()->json([
        'success' => true,
        'data' => $employees->items(),
        'current_page' => $employees->currentPage(),
        'last_page' => $employees->lastPage(),
        'per_page' => $employees->perPage(),
        'total' => $employees->total(),
        'from' => $employees->firstItem(),
        'to' => $employees->lastItem(),
        'first_page_url' => $employees->url(1),
        'last_page_url' => $employees->url($employees->lastPage()),
        'next_page_url' => $employees->nextPageUrl(),
        'prev_page_url' => $employees->previousPageUrl(),
        'path' => $employees->path(),
    ], 200);
}
```

### 2. Côté Flutter (Frontend)

#### Modèles créés

1. **PaginationResponse<T>** (`lib/Models/pagination_response.dart`)
   - Contient les données et les métadonnées de pagination
   - Méthodes utilitaires : `hasNextPage`, `hasPreviousPage`, etc.

2. **PaginationMeta** (`lib/Models/pagination_response.dart`)
   - Contient toutes les métadonnées de pagination

3. **PaginationHelper** (`lib/utils/pagination_helper.dart`)
   - Parse les réponses JSON de Laravel
   - Utilitaires pour gérer les URLs et calculer les pages

#### Utilisation dans les Services

```dart
// Dans votre service (ex: employee_service.dart)
Future<PaginationResponse<Employee>> getEmployeesPaginated({
  String? search,
  int page = 1,
  int perPage = 15,
}) async {
  // Construire l'URL avec les paramètres
  final url = '${AppConfig.baseUrl}/employees?page=$page&per_page=$perPage';
  
  final response = await http.get(Uri.parse(url), headers: ApiService.headers());
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    // Utiliser PaginationHelper pour parser
    return PaginationHelper.parseResponse<Employee>(
      json: data,
      fromJsonT: (json) => Employee.fromJson(json),
    );
  }
  
  throw Exception('Erreur: ${response.statusCode}');
}
```

#### Utilisation dans les Contrôleurs

```dart
// Dans votre contrôleur (ex: employee_controller.dart)
final RxInt currentPage = 1.obs;
final RxInt totalPages = 1.obs;
final RxInt totalItems = 0.obs;
final RxBool hasNextPage = false.obs;
final RxBool hasPreviousPage = false.obs;

Future<void> loadEmployees({int page = 1}) async {
  try {
    isLoading.value = true;
    
    final paginatedResponse = await _employeeService.getEmployeesPaginated(
      page: page,
      perPage: 15,
    );
    
    // Mettre à jour les métadonnées
    totalPages.value = paginatedResponse.meta.lastPage;
    totalItems.value = paginatedResponse.meta.total;
    hasNextPage.value = paginatedResponse.hasNextPage;
    hasPreviousPage.value = paginatedResponse.hasPreviousPage;
    currentPage.value = paginatedResponse.meta.currentPage;
    
    // Mettre à jour les données
    if (page == 1) {
      employees.value = paginatedResponse.data;
    } else {
      // Pour scroll infini, ajouter à la liste existante
      employees.addAll(paginatedResponse.data);
    }
  } finally {
    isLoading.value = false;
  }
}

// Charger la page suivante
Future<void> loadNextPage() async {
  if (hasNextPage.value && !isLoading.value) {
    await loadEmployees(page: currentPage.value + 1);
  }
}
```

#### Utilisation dans les Vues

```dart
// Dans votre vue
Obx(() => ListView.builder(
  itemCount: controller.employees.length + (controller.hasNextPage.value ? 1 : 0),
  itemBuilder: (context, index) {
    if (index == controller.employees.length) {
      // Afficher un loader et charger la page suivante
      controller.loadNextPage();
      return const CircularProgressIndicator();
    }
    return EmployeeCard(employee: controller.employees[index]);
  },
))
```

## Checklist d'implémentation

### Backend Laravel
- [ ] Modifier les contrôleurs pour utiliser `->paginate(15)` au lieu de `->get()`
- [ ] Retourner toutes les métadonnées de pagination dans la réponse JSON
- [ ] Gérer les paramètres `page` et `per_page` dans les requêtes
- [ ] Tester que les liens `next_page_url` et `prev_page_url` sont corrects

### Frontend Flutter
- [ ] Utiliser `PaginationResponse<T>` dans les services
- [ ] Utiliser `PaginationHelper.parseResponse()` pour parser les réponses
- [ ] Ajouter les observables de pagination dans les contrôleurs
- [ ] Implémenter `loadNextPage()` et `loadPreviousPage()`
- [ ] Mettre à jour les vues pour afficher les métadonnées de pagination

## Exemples de contrôleurs à modifier

- EmployeeController
- ClientController
- StockController
- InvoiceController
- PaymentController
- Et tous les autres contrôleurs qui retournent des listes

## Notes importantes

1. **Toujours utiliser `paginate(15)`** pour les listes longues
2. **Retourner toutes les métadonnées** pour que Flutter puisse gérer la navigation
3. **Gérer les paramètres de requête** (`page`, `per_page`, `search`, etc.)
4. **Tester avec de grandes listes** pour vérifier les performances

