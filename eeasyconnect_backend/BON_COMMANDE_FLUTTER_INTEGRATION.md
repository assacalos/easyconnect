# 🛒 Backend Gestion des Bons de Commande - Intégration Flutter

## 📋 Vue d'ensemble

Le backend pour la gestion des bons de commande est maintenant complet et optimisé pour l'intégration avec Flutter. Il offre toutes les fonctionnalités nécessaires pour une application mobile robuste.

## 🚀 Fonctionnalités Implémentées

### 1. **CRUD Complet**
- ✅ Création de bons de commande
- ✅ Lecture avec filtres avancés
- ✅ Modification (uniquement si en attente)
- ✅ Suppression (uniquement si en attente)

### 2. **Gestion des Statuts**
- 🔄 **En attente** → **Validé** → **En cours** → **Livré**
- ❌ **Annulé** (à tout moment sauf si livré)

### 3. **Fonctions Avancées**
- 📊 Dashboard avec statistiques
- 📈 Rapports détaillés
- 🔍 Recherche avancée
- 📋 Export des données
- 📋 Duplication de bons
- 📊 Statistiques par période

## 🔗 Endpoints API

### **Authentification Requise**
Tous les endpoints nécessitent un token Bearer dans l'en-tête :
```
Authorization: Bearer YOUR_TOKEN
```

### **1. Liste des Bons de Commande**
```
GET /api/bons-de-commande
```

**Paramètres de filtrage :**
- `statut` : Filtre par statut (en_attente, valide, en_cours, livre, annule)
- `date_debut` : Date de début
- `date_fin` : Date de fin
- `client_id` : ID du client
- `fournisseur_id` : ID du fournisseur
- `montant_min` : Montant minimum
- `montant_max` : Montant maximum
- `en_retard` : Bons en retard (true/false)
- `per_page` : Nombre d'éléments par page (défaut: 15)

**Exemple de requête Flutter :**
```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/bons-de-commande?statut=en_attente&per_page=20'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

### **2. Détails d'un Bon de Commande**
```
GET /api/bons-de-commande/{id}
```

### **3. Créer un Bon de Commande**
```
POST /api/bons-de-commande
```

**Body JSON :**
```json
{
  "client_id": 1,
  "fournisseur_id": 1,
  "numero_commande": "BC-2025-0001",
  "date_commande": "2025-01-20",
  "date_livraison_prevue": "2025-02-20",
  "montant_total": 15000.00,
  "description": "Commande de matériel informatique",
  "statut": "en_attente",
  "commentaire": "Commande urgente",
  "conditions_paiement": "Paiement à 30 jours",
  "delai_livraison": 30
}
```

### **4. Modifier un Bon de Commande**
```
PUT /api/bons-de-commande/{id}
```

### **5. Actions sur les Bons de Commande**

#### **Valider un bon**
```
POST /api/bons-de-commande/{id}/validate
```

#### **Marquer en cours**
```
POST /api/bons-de-commande/{id}/mark-in-progress
```

#### **Marquer comme livré**
```
POST /api/bons-de-commande/{id}/mark-delivered
```

#### **Annuler un bon**
```
POST /api/bons-de-commande/{id}/cancel
```

**Body JSON pour annulation :**
```json
{
  "commentaire": "Raison de l'annulation"
}
```

### **6. Fonctions Avancées**

#### **Dashboard**
```
GET /api/bons-de-commande-dashboard
```

#### **Statistiques**
```
GET /api/bons-de-commande-statistics?date_debut=2025-01-01&date_fin=2025-12-31
```

#### **Recherche**
```
GET /api/bons-de-commande-search?numero=BC&client_nom=John
```

#### **Dupliquer**
```
POST /api/bons-de-commande/{id}/duplicate
```

#### **Export**
```
GET /api/bons-de-commande-export
```

## 📱 Intégration Flutter

### **1. Modèle de Données Flutter**

```dart
class BonDeCommande {
  final int id;
  final int clientId;
  final int fournisseurId;
  final String numeroCommande;
  final DateTime dateCommande;
  final DateTime? dateLivraisonPrevue;
  final DateTime? dateLivraison;
  final double montantTotal;
  final String? description;
  final String statut;
  final String? commentaire;
  final String? conditionsPaiement;
  final int? delaiLivraison;
  final DateTime? dateValidation;
  final DateTime? dateDebutTraitement;
  final DateTime? dateAnnulation;
  final int userId;
  final Client? client;
  final Fournisseur? fournisseur;
  final User? createur;

  BonDeCommande({
    required this.id,
    required this.clientId,
    required this.fournisseurId,
    required this.numeroCommande,
    required this.dateCommande,
    this.dateLivraisonPrevue,
    this.dateLivraison,
    required this.montantTotal,
    this.description,
    required this.statut,
    this.commentaire,
    this.conditionsPaiement,
    this.delaiLivraison,
    this.dateValidation,
    this.dateDebutTraitement,
    this.dateAnnulation,
    required this.userId,
    this.client,
    this.fournisseur,
    this.createur,
  });

  factory BonDeCommande.fromJson(Map<String, dynamic> json) {
    return BonDeCommande(
      id: json['id'],
      clientId: json['client_id'],
      fournisseurId: json['fournisseur_id'],
      numeroCommande: json['numero_commande'],
      dateCommande: DateTime.parse(json['date_commande']),
      dateLivraisonPrevue: json['date_livraison_prevue'] != null 
          ? DateTime.parse(json['date_livraison_prevue']) 
          : null,
      dateLivraison: json['date_livraison'] != null 
          ? DateTime.parse(json['date_livraison']) 
          : null,
      montantTotal: json['montant_total'].toDouble(),
      description: json['description'],
      statut: json['statut'],
      commentaire: json['commentaire'],
      conditionsPaiement: json['conditions_paiement'],
      delaiLivraison: json['delai_livraison'],
      dateValidation: json['date_validation'] != null 
          ? DateTime.parse(json['date_validation']) 
          : null,
      dateDebutTraitement: json['date_debut_traitement'] != null 
          ? DateTime.parse(json['date_debut_traitement']) 
          : null,
      dateAnnulation: json['date_annulation'] != null 
          ? DateTime.parse(json['date_annulation']) 
          : null,
      userId: json['user_id'],
      client: json['client'] != null ? Client.fromJson(json['client']) : null,
      fournisseur: json['fournisseur'] != null ? Fournisseur.fromJson(json['fournisseur']) : null,
      createur: json['createur'] != null ? User.fromJson(json['createur']) : null,
    );
  }
}
```

### **2. Service API Flutter**

```dart
class BonDeCommandeService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  static Future<List<BonDeCommande>> getBonsDeCommande({
    String? statut,
    DateTime? dateDebut,
    DateTime? dateFin,
    int? clientId,
    int? fournisseurId,
    double? montantMin,
    double? montantMax,
    bool? enRetard,
    int perPage = 15,
  }) async {
    final uri = Uri.parse('$baseUrl/bons-de-commande').replace(
      queryParameters: {
        if (statut != null) 'statut': statut,
        if (dateDebut != null) 'date_debut': dateDebut.toIso8601String().split('T')[0],
        if (dateFin != null) 'date_fin': dateFin.toIso8601String().split('T')[0],
        if (clientId != null) 'client_id': clientId.toString(),
        if (fournisseurId != null) 'fournisseur_id': fournisseurId.toString(),
        if (montantMin != null) 'montant_min': montantMin.toString(),
        if (montantMax != null) 'montant_max': montantMax.toString(),
        if (enRetard != null) 'en_retard': enRetard.toString(),
        'per_page': perPage.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${await getToken()}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data']['data'] as List)
          .map((json) => BonDeCommande.fromJson(json))
          .toList();
    } else {
      throw Exception('Erreur lors de la récupération des bons de commande');
    }
  }

  static Future<BonDeCommande> createBonDeCommande(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bons-de-commande'),
      headers: {
        'Authorization': 'Bearer ${await getToken()}',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return BonDeCommande.fromJson(responseData['bon_de_commande']);
    } else {
      throw Exception('Erreur lors de la création du bon de commande');
    }
  }

  static Future<void> validateBonDeCommande(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bons-de-commande/$id/validate'),
      headers: {
        'Authorization': 'Bearer ${await getToken()}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la validation');
    }
  }

  // Autres méthodes...
}
```

### **3. Widget Flutter - Liste des Bons de Commande**

```dart
class BonsDeCommandeList extends StatefulWidget {
  @override
  _BonsDeCommandeListState createState() => _BonsDeCommandeListState();
}

class _BonsDeCommandeListState extends State<BonsDeCommandeList> {
  List<BonDeCommande> _bons = [];
  bool _isLoading = true;
  String _selectedStatut = 'tous';

  @override
  void initState() {
    super.initState();
    _loadBonsDeCommande();
  }

  Future<void> _loadBonsDeCommande() async {
    setState(() => _isLoading = true);
    try {
      final bons = await BonDeCommandeService.getBonsDeCommande(
        statut: _selectedStatut == 'tous' ? null : _selectedStatut,
      );
      setState(() {
        _bons = bons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bons de Commande'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBonsDeCommande,
              child: ListView.builder(
                itemCount: _bons.length,
                itemBuilder: (context, index) {
                  final bon = _bons[index];
                  return Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(bon.numeroCommande),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Client: ${bon.client?.nom ?? 'N/A'}'),
                          Text('Montant: ${bon.montantTotal.toStringAsFixed(2)} FCFA'),
                          Text('Statut: ${_getStatutLabel(bon.statut)}'),
                        ],
                      ),
                      trailing: _getStatutIcon(bon.statut),
                      onTap: () => _showBonDetails(bon),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBonDeCommande,
        child: Icon(Icons.add),
      ),
    );
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'valide': return 'Validé';
      case 'en_cours': return 'En cours';
      case 'livre': return 'Livré';
      case 'annule': return 'Annulé';
      default: return statut;
    }
  }

  Icon _getStatutIcon(String statut) {
    switch (statut) {
      case 'en_attente': return Icon(Icons.schedule, color: Colors.orange);
      case 'valide': return Icon(Icons.check_circle, color: Colors.green);
      case 'en_cours': return Icon(Icons.work, color: Colors.blue);
      case 'livre': return Icon(Icons.done_all, color: Colors.green);
      case 'annule': return Icon(Icons.cancel, color: Colors.red);
      default: return Icon(Icons.help);
    }
  }

  void _showBonDetails(BonDeCommande bon) {
    // Navigation vers la page de détails
  }

  void _createBonDeCommande() {
    // Navigation vers la page de création
  }

  void _showFilterDialog() {
    // Afficher le dialogue de filtrage
  }
}
```

## 🔐 Sécurité et Permissions

### **Rôles et Accès**

1. **Commercial (role: 2)** : Peut voir uniquement ses propres clients
2. **Comptable (role: 3)** : Accès complet aux bons de commande
3. **Patron (role: 6)** : Accès complet + validation
4. **Admin (role: 1)** : Accès complet + suppression

### **Validation des Données**

- ✅ Validation des statuts
- ✅ Vérification des permissions
- ✅ Contrôle des transitions d'état
- ✅ Protection contre les modifications non autorisées

## 📊 Statistiques et Rapports

Le backend fournit des endpoints riches pour les tableaux de bord Flutter :

- **Dashboard** : Vue d'ensemble avec KPIs
- **Statistiques** : Données par période
- **Rapports** : Export et analyse
- **Recherche** : Filtrage avancé

## 🚀 Prêt pour l'Intégration

Le backend est maintenant **100% prêt** pour l'intégration Flutter avec :

- ✅ API REST complète
- ✅ Authentification sécurisée
- ✅ Gestion des rôles
- ✅ Validation des données
- ✅ Gestion d'erreurs robuste
- ✅ Pagination et filtrage
- ✅ Documentation complète

**Prochaines étapes :** Implémenter les widgets Flutter en utilisant ces endpoints ! 🎯


