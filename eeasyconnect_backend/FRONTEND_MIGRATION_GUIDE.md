# Guide de Migration Frontend

## Vue d'ensemble

Ce guide décrit les changements nécessaires côté frontend suite aux améliorations backend (pagination, API Resources, cache, queues).

## ⚠️ Changements Critiques

### 1. Structure des Réponses Paginées

**AVANT** : Les listes retournaient directement un tableau

```json
{
  "success": true,
  "data": [
    { "id": 1, "nom": "Client 1" },
    { "id": 2, "nom": "Client 2" }
  ]
}
```

**MAINTENANT** : Les listes retournent un objet avec pagination

```json
{
  "success": true,
  "data": [
    { "id": 1, "nom": "Client 1" },
    { "id": 2, "nom": "Client 2" }
  ],
  "pagination": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 15,
    "total": 72
  },
  "message": "Liste récupérée avec succès"
}
```

### 2. Endpoints Affectés

Tous les endpoints `index()` retournent maintenant cette structure :

- `GET /api/clients`
- `GET /api/factures`
- `GET /api/paiements`
- `GET /api/devis`
- `GET /api/bordereaux`
- `GET /api/interventions`
- `GET /api/employees`
- `GET /api/conges`
- `GET /api/stocks`
- `GET /api/equipment`
- `GET /api/expenses`
- `GET /api/taxes`
- `GET /api/evaluations`
- `GET /api/contracts`
- `GET /api/bons-de-commande`
- `GET /api/commandes-entreprise`
- `GET /api/attendances`
- `GET /api/leave-requests`
- `GET /api/pointages`
- `GET /api/salaries`
- `GET /api/invoices`
- `GET /api/payment-schedules`
- `GET /api/users`
- `GET /api/user-reportings`

## 🔧 Modifications Frontend Requises

### 1. Adapter les Services/API Calls

**Exemple Flutter/Dart** :

```dart
// AVANT
Future<List<Client>> getClients() async {
  final response = await http.get(Uri.parse('$baseUrl/api/clients'));
  final data = json.decode(response.body);
  return (data['data'] as List)
      .map((json) => Client.fromJson(json))
      .toList();
}

// MAINTENANT
Future<PaginatedResponse<Client>> getClients({int page = 1, int perPage = 15}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/api/clients?page=$page&per_page=$perPage')
  );
  final data = json.decode(response.body);
  
  return PaginatedResponse<Client>(
    items: (data['data'] as List)
        .map((json) => Client.fromJson(json))
        .toList(),
    currentPage: data['pagination']['current_page'],
    lastPage: data['pagination']['last_page'],
    perPage: data['pagination']['per_page'],
    total: data['pagination']['total'],
  );
}
```

**Exemple React/TypeScript** :

```typescript
// AVANT
const getClients = async (): Promise<Client[]> => {
  const response = await fetch('/api/clients');
  const data = await response.json();
  return data.data;
};

// MAINTENANT
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
  };
}

const getClients = async (
  page: number = 1,
  perPage: number = 15
): Promise<PaginatedResponse<Client>> => {
  const response = await fetch(
    `/api/clients?page=${page}&per_page=${perPage}`
  );
  const data = await response.json();
  return {
    data: data.data,
    pagination: data.pagination,
  };
};
```

### 2. Créer un Modèle PaginatedResponse

**Flutter/Dart** :

```dart
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

// Utilisation avec un générateur
class ClientService {
  Stream<PaginatedResponse<Client>> getClientsStream({
    int page = 1,
    int perPage = 15,
  }) async* {
    while (true) {
      final response = await getClients(page: page, perPage: perPage);
      yield response;
      
      if (!response.hasNextPage) break;
      page++;
    }
  }
}
```

**React/TypeScript** :

```typescript
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
  };
}

// Hook personnalisé
const usePaginatedData = <T>(
  fetchFn: (page: number) => Promise<PaginatedResponse<T>>,
  initialPage: number = 1
) => {
  const [data, setData] = useState<T[]>([]);
  const [pagination, setPagination] = useState(null);
  const [page, setPage] = useState(initialPage);
  const [loading, setLoading] = useState(false);

  const loadPage = async (pageNum: number) => {
    setLoading(true);
    try {
      const response = await fetchFn(pageNum);
      setData(response.data);
      setPagination(response.pagination);
      setPage(pageNum);
    } finally {
      setLoading(false);
    }
  };

  return {
    data,
    pagination,
    page,
    loading,
    loadPage,
    nextPage: () => {
      if (pagination && page < pagination.last_page) {
        loadPage(page + 1);
      }
    },
    previousPage: () => {
      if (page > 1) {
        loadPage(page - 1);
      }
    },
  };
};
```

### 3. Mettre à Jour les Composants de Liste

**Flutter - Exemple avec ListView** :

```dart
class ClientsListPage extends StatefulWidget {
  @override
  _ClientsListPageState createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  int _currentPage = 1;
  PaginatedResponse<Client>? _response;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final response = await ClientService().getClients(
        page: page,
        perPage: 15,
      );
      setState(() {
        _response = response;
        _currentPage = page;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _response == null) {
      return CircularProgressIndicator();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _response?.items.length ?? 0,
            itemBuilder: (context, index) {
              return ClientTile(client: _response!.items[index]);
            },
          ),
        ),
        // Pagination controls
        if (_response != null)
          PaginationControls(
            currentPage: _response!.currentPage,
            lastPage: _response!.lastPage,
            onPageChanged: (page) => _loadClients(page: page),
          ),
      ],
    );
  }
}
```

**React - Exemple avec Table** :

```tsx
const ClientsList: React.FC = () => {
  const {
    data,
    pagination,
    page,
    loading,
    nextPage,
    previousPage,
    loadPage,
  } = usePaginatedData((page) => getClients(page, 15));

  if (loading && !data.length) {
    return <Spinner />;
  }

  return (
    <div>
      <table>
        <thead>
          <tr>
            <th>Nom</th>
            <th>Email</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {data.map((client) => (
            <tr key={client.id}>
              <td>{client.nom}</td>
              <td>{client.email}</td>
              <td>
                <button onClick={() => handleEdit(client.id)}>Éditer</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Pagination */}
      {pagination && (
        <div className="pagination">
          <button
            onClick={previousPage}
            disabled={page === 1}
          >
            Précédent
          </button>
          <span>
            Page {pagination.current_page} sur {pagination.last_page}
          </span>
          <button
            onClick={nextPage}
            disabled={page === pagination.last_page}
          >
            Suivant
          </button>
        </div>
      )}
    </div>
  );
};
```

### 4. Paramètres de Pagination

Tous les endpoints `index()` acceptent maintenant ces paramètres de requête :

- `page` : Numéro de page (défaut: 1)
- `per_page` : Nombre d'éléments par page (défaut: 15, max recommandé: 100)

**Exemple** :
```
GET /api/clients?page=2&per_page=20
```

### 5. Gestion des Erreurs

La structure des erreurs reste la même :

```json
{
  "success": false,
  "message": "Message d'erreur"
}
```

## ✅ Changements Transparents (Pas d'Action Requise)

### 1. Cache
Le cache est transparent pour le frontend. Aucun changement nécessaire.

### 2. Queue Jobs
Les notifications et le traitement d'images sont maintenant asynchrones, mais cela n'affecte pas le frontend.

### 3. API Resources
La structure des données reste la même, seule la pagination a été ajoutée.

## 📋 Checklist de Migration

- [ ] Créer le modèle `PaginatedResponse` dans votre framework
- [ ] Mettre à jour tous les appels API pour les listes
- [ ] Adapter les composants de liste pour afficher la pagination
- [ ] Ajouter les contrôles de pagination (boutons précédent/suivant)
- [ ] Tester tous les endpoints de liste
- [ ] Mettre à jour la documentation frontend
- [ ] Tester la navigation entre les pages
- [ ] Vérifier que les filtres fonctionnent avec la pagination

## 🎯 Exemple Complet - Service Flutter

```dart
// models/paginated_response.dart
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['data'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      pagination: PaginationMeta.fromJson(json['pagination']),
    );
  }
}

class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'],
      lastPage: json['last_page'],
      perPage: json['per_page'],
      total: json['total'],
    );
  }

  bool get hasNextPage => currentPage < lastPage;
  bool get hasPreviousPage => currentPage > 1;
}

// services/client_service.dart
class ClientService {
  final String baseUrl = 'https://api.example.com';

  Future<PaginatedResponse<Client>> getClients({
    int page = 1,
    int perPage = 15,
    Map<String, String>? filters,
  }) async {
    final uri = Uri.parse('$baseUrl/api/clients')
        .replace(queryParameters: {
      'page': page.toString(),
      'per_page': perPage.toString(),
      ...?filters,
    });

    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return PaginatedResponse.fromJson(
        json,
        (item) => Client.fromJson(item),
      );
    } else {
      throw Exception('Failed to load clients');
    }
  }
}
```

## 🚀 Améliorations Recommandées

### 1. Infinite Scroll (Optionnel)

Au lieu de la pagination classique, vous pouvez implémenter un infinite scroll :

```dart
class InfiniteScrollList extends StatefulWidget {
  @override
  _InfiniteScrollListState createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<InfiniteScrollList> {
  final List<Client> _clients = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;

    setState(() => _loading = true);
    try {
      final response = await ClientService().getClients(page: _currentPage);
      setState(() {
        _clients.addAll(response.items);
        _currentPage++;
        _hasMore = response.pagination.hasNextPage;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _clients.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _clients.length) {
          // Dernier élément = loader
          if (_loading) {
            return CircularProgressIndicator();
          }
          // Charger plus quand on arrive à la fin
          _loadMore();
          return SizedBox.shrink();
        }
        return ClientTile(client: _clients[index]);
      },
    );
  }
}
```

### 2. Cache Local (Optionnel)

Mettre en cache les données paginées localement pour améliorer l'expérience utilisateur.

## 📞 Support

Si vous rencontrez des problèmes lors de la migration, vérifiez :

1. Que les paramètres `page` et `per_page` sont bien envoyés
2. Que la structure de réponse est bien parsée
3. Que les composants de pagination gèrent correctement les états (loading, erreur, vide)

