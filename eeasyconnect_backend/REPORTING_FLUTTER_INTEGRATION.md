# 📊 Intégration Flutter - Système de Reporting

## 🎯 **Vue d'ensemble**

Le système de reporting permet aux utilisateurs de créer, soumettre et gérer des rapports mensuels basés sur leur rôle (Commercial, Comptable, Technicien).

## 🔗 **Endpoints API**

### **Base URL**: `http://127.0.0.1:8000/api`

### **Authentification**
Tous les endpoints nécessitent un token Bearer dans l'en-tête :
```
Authorization: Bearer {token}
```

## 📋 **Endpoints Disponibles**

### **1. Liste des Reportings**
```http
GET /user-reportings
```

**Paramètres de requête :**
- `status` (optionnel) : `draft`, `submitted`, `approved`
- `date_debut` (optionnel) : Date de début (YYYY-MM-DD)
- `date_fin` (optionnel) : Date de fin (YYYY-MM-DD)
- `user_id` (optionnel) : ID de l'utilisateur
- `per_page` (optionnel) : Nombre d'éléments par page (défaut: 15)

**Réponse :**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 1,
        "user_id": 2,
        "user_name": "Jean Dupont",
        "user_role": "Commercial",
        "report_date": "2025-09-01",
        "metrics": {
          "clients_prospectes": 12,
          "rdv_obtenus": 15,
          "devis_crees": 8,
          "chiffre_affaires": 150000
        },
        "status": "approved",
        "submitted_at": "2025-09-05 10:30:00",
        "approved_at": "2025-09-10 14:20:00",
        "comments": "Excellent travail ce mois-ci",
        "created_at": "2025-09-01 09:00:00",
        "updated_at": "2025-09-10 14:20:00"
      }
    ],
    "total": 25
  },
  "message": "Liste des reportings récupérée avec succès"
}
```

### **2. Détails d'un Reporting**
```http
GET /user-reportings/{id}
```

**Réponse :** Même format que l'élément dans la liste

### **3. Créer un Reporting**
```http
POST /user-reportings
```

**Body :**
```json
{
  "report_date": "2025-09-01",
  "metrics": {
    "clients_prospectes": 10,
    "rdv_obtenus": 12,
    "devis_crees": 5,
    "chiffre_affaires": 120000
  },
  "comments": "Commentaires optionnels"
}
```

### **4. Mettre à jour un Reporting**
```http
PUT /user-reportings/{id}
```

**Body :** Même format que la création

### **5. Supprimer un Reporting**
```http
DELETE /user-reportings/{id}
```

### **6. Soumettre un Reporting**
```http
POST /user-reportings/{id}/submit
```

### **7. Approuver un Reporting**
```http
POST /user-reportings/{id}/approve
```

**Body :**
```json
{
  "comments": "Commentaires d'approbation"
}
```

### **8. Générer automatiquement un Reporting**
```http
POST /user-reportings/generate
```

**Body :**
```json
{
  "report_date": "2025-09-01",
  "user_id": 2
}
```

### **9. Statistiques des Reportings**
```http
GET /user-reportings-statistics
```

**Paramètres :**
- `date_debut` (optionnel)
- `date_fin` (optionnel)

## 🏗️ **Modèles Dart**

### **ReportingModel**
```dart
class ReportingModel {
  final int id;
  final int userId;
  final String userName;
  final String userRole;
  final DateTime reportDate;
  final Map<String, dynamic> metrics;
  final String status; // 'draft', 'submitted', 'approved'
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? comments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReportingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.reportDate,
    required this.metrics,
    required this.status,
    this.submittedAt,
    this.approvedAt,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportingModel.fromJson(Map<String, dynamic> json) {
    return ReportingModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userRole: json['user_role'],
      reportDate: DateTime.parse(json['report_date']),
      metrics: Map<String, dynamic>.from(json['metrics']),
      status: json['status'],
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at']) : null,
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      comments: json['comments'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'report_date': reportDate.toIso8601String().split('T')[0],
      'metrics': metrics,
      'status': status,
      'submitted_at': submittedAt?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'comments': comments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### **Métriques Commerciales**
```dart
class CommercialMetrics {
  final int clientsProspectes;
  final int rdvObtenus;
  final List<RdvInfo> rdvList;
  final int devisCrees;
  final int devisAcceptes;
  final double chiffreAffaires;
  final int nouveauxClients;
  final int appelsEffectues;
  final int emailsEnvoyes;
  final int visitesRealisees;

  CommercialMetrics({
    required this.clientsProspectes,
    required this.rdvObtenus,
    required this.rdvList,
    required this.devisCrees,
    required this.devisAcceptes,
    required this.chiffreAffaires,
    required this.nouveauxClients,
    required this.appelsEffectues,
    required this.emailsEnvoyes,
    required this.visitesRealisees,
  });

  factory CommercialMetrics.fromJson(Map<String, dynamic> json) {
    return CommercialMetrics(
      clientsProspectes: json['clients_prospectes'] ?? 0,
      rdvObtenus: json['rdv_obtenus'] ?? 0,
      rdvList: (json['rdv_list'] as List<dynamic>?)
          ?.map((e) => RdvInfo.fromJson(e))
          .toList() ?? [],
      devisCrees: json['devis_crees'] ?? 0,
      devisAcceptes: json['devis_acceptes'] ?? 0,
      chiffreAffaires: (json['chiffre_affaires'] ?? 0).toDouble(),
      nouveauxClients: json['nouveaux_clients'] ?? 0,
      appelsEffectues: json['appels_effectues'] ?? 0,
      emailsEnvoyes: json['emails_envoyes'] ?? 0,
      visitesRealisees: json['visites_realisees'] ?? 0,
    );
  }
}
```

### **Métriques Comptables**
```dart
class ComptableMetrics {
  final int facturesEmises;
  final int facturesPayees;
  final double montantFacture;
  final double montantEncaissement;
  final int bordereauxTraites;
  final int bonsCommandeTraites;
  final double chiffreAffaires;
  final int clientsFactures;
  final int relancesEffectuees;
  final double encaissements;

  ComptableMetrics({
    required this.facturesEmises,
    required this.facturesPayees,
    required this.montantFacture,
    required this.montantEncaissement,
    required this.bordereauxTraites,
    required this.bonsCommandeTraites,
    required this.chiffreAffaires,
    required this.clientsFactures,
    required this.relancesEffectuees,
    required this.encaissements,
  });

  factory ComptableMetrics.fromJson(Map<String, dynamic> json) {
    return ComptableMetrics(
      facturesEmises: json['factures_emises'] ?? 0,
      facturesPayees: json['factures_payees'] ?? 0,
      montantFacture: (json['montant_facture'] ?? 0).toDouble(),
      montantEncaissement: (json['montant_encaissement'] ?? 0).toDouble(),
      bordereauxTraites: json['bordereaux_traites'] ?? 0,
      bonsCommandeTraites: json['bons_commande_traites'] ?? 0,
      chiffreAffaires: (json['chiffre_affaires'] ?? 0).toDouble(),
      clientsFactures: json['clients_factures'] ?? 0,
      relancesEffectuees: json['relances_effectuees'] ?? 0,
      encaissements: (json['encaissements'] ?? 0).toDouble(),
    );
  }
}
```

### **Métriques Techniques**
```dart
class TechnicienMetrics {
  final int interventionsPlanifiees;
  final int interventionsRealisees;
  final int interventionsAnnulees;
  final List<InterventionInfo> interventionsList;
  final int clientsVisites;
  final int problemesResolus;
  final int problemesEnCours;
  final double tempsTravail;
  final int deplacements;
  final String? notesTechniques;

  TechnicienMetrics({
    required this.interventionsPlanifiees,
    required this.interventionsRealisees,
    required this.interventionsAnnulees,
    required this.interventionsList,
    required this.clientsVisites,
    required this.problemesResolus,
    required this.problemesEnCours,
    required this.tempsTravail,
    required this.deplacements,
    this.notesTechniques,
  });

  factory TechnicienMetrics.fromJson(Map<String, dynamic> json) {
    return TechnicienMetrics(
      interventionsPlanifiees: json['interventions_planifiees'] ?? 0,
      interventionsRealisees: json['interventions_realisees'] ?? 0,
      interventionsAnnulees: json['interventions_annulees'] ?? 0,
      interventionsList: (json['interventions_list'] as List<dynamic>?)
          ?.map((e) => InterventionInfo.fromJson(e))
          .toList() ?? [],
      clientsVisites: json['clients_visites'] ?? 0,
      problemesResolus: json['problemes_resolus'] ?? 0,
      problemesEnCours: json['problemes_en_cours'] ?? 0,
      tempsTravail: (json['temps_travail'] ?? 0).toDouble(),
      deplacements: json['deplacements'] ?? 0,
      notesTechniques: json['notes_techniques'],
    );
  }
}
```

## 🎨 **Widgets Flutter Recommandés**

### **1. Liste des Reportings**
```dart
class ReportingListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReportingModel>>(
      future: ReportingService.getReportings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }
        
        return ListView.builder(
          itemCount: snapshot.data?.length ?? 0,
          itemBuilder: (context, index) {
            final reporting = snapshot.data![index];
            return ReportingCard(reporting: reporting);
          },
        );
      },
    );
  }
}
```

### **2. Carte de Reporting**
```dart
class ReportingCard extends StatelessWidget {
  final ReportingModel reporting;
  
  const ReportingCard({required this.reporting});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Reporting ${reporting.reportDate}'),
        subtitle: Text('${reporting.userRole} - ${reporting.status}'),
        trailing: _getStatusIcon(reporting.status),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportingDetail(reporting: reporting),
          ),
        ),
      ),
    );
  }
  
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icon(Icons.edit, color: Colors.orange);
      case 'submitted':
        return Icon(Icons.send, color: Colors.blue);
      case 'approved':
        return Icon(Icons.check_circle, color: Colors.green);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }
}
```

### **3. Formulaire de Reporting**
```dart
class ReportingFormWidget extends StatefulWidget {
  final ReportingModel? reporting;
  
  const ReportingFormWidget({this.reporting});
  
  @override
  _ReportingFormWidgetState createState() => _ReportingFormWidgetState();
}

class _ReportingFormWidgetState extends State<ReportingFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _reportDate;
  late Map<String, dynamic> _metrics;
  
  @override
  void initState() {
    super.initState();
    _reportDate = widget.reporting?.reportDate ?? DateTime.now();
    _metrics = widget.reporting?.metrics ?? {};
  }
  
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Champs de base
          TextFormField(
            decoration: InputDecoration(labelText: 'Date du rapport'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _reportDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _reportDate = date);
              }
            },
          ),
          
          // Métriques selon le rôle
          _buildMetricsFields(),
          
          // Boutons d'action
          Row(
            children: [
              ElevatedButton(
                onPressed: _saveDraft,
                child: Text('Sauvegarder'),
              ),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Soumettre'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsFields() {
    // Implémentation selon le rôle de l'utilisateur
    return Container(); // Placeholder
  }
  
  void _saveDraft() {
    // Logique de sauvegarde
  }
  
  void _submit() {
    // Logique de soumission
  }
}
```

## 🔐 **Gestion des Permissions**

### **Rôles et Accès**
- **Commercial (role: 2)** : Peut créer/modifier ses propres reportings
- **Comptable (role: 3)** : Peut créer/modifier ses propres reportings
- **Technicien (role: 5)** : Peut créer/modifier ses propres reportings
- **RH (role: 4)** : Peut voir tous les reportings, peut approuver
- **Admin (role: 1)** : Accès complet
- **Patron (role: 6)** : Accès complet

### **États des Reportings**
1. **Draft** : Peut être modifié par le créateur
2. **Submitted** : En attente d'approbation
3. **Approved** : Approuvé, ne peut plus être modifié

## 📱 **Fonctionnalités Recommandées**

### **1. Dashboard Reporting**
- Vue d'ensemble des reportings
- Statistiques par rôle
- Graphiques de performance

### **2. Création de Reporting**
- Formulaire adaptatif selon le rôle
- Génération automatique des métriques
- Validation des données

### **3. Gestion des Approbations**
- Liste des reportings en attente
- Interface d'approbation pour RH/Admin
- Commentaires d'approbation

### **4. Historique et Rapports**
- Historique des reportings
- Export PDF/Excel
- Comparaisons mensuelles

## 🚀 **Exemple d'Utilisation**

```dart
// Récupérer les reportings
final reportings = await ReportingService.getReportings(
  status: 'submitted',
  dateDebut: DateTime(2025, 9, 1),
  dateFin: DateTime(2025, 9, 30),
);

// Créer un nouveau reporting
final newReporting = await ReportingService.createReporting(
  reportDate: DateTime.now(),
  metrics: {
    'clients_prospectes': 10,
    'rdv_obtenus': 12,
    'chiffre_affaires': 150000,
  },
);

// Soumettre un reporting
await ReportingService.submitReporting(reportingId);

// Approuver un reporting
await ReportingService.approveReporting(
  reportingId,
  comments: 'Excellent travail !',
);
```

## ⚠️ **Points d'Attention**

1. **Validation des données** : Vérifier les métriques selon le rôle
2. **Gestion des erreurs** : Messages d'erreur clairs
3. **Performance** : Pagination pour les grandes listes
4. **Sécurité** : Validation côté client ET serveur
5. **UX** : Interface intuitive et responsive

## 📊 **Métriques Disponibles par Rôle**

### **Commercial**
- Clients prospectés
- RDV obtenus
- Devis créés/acceptés
- Chiffre d'affaires
- Appels/emails/visites

### **Comptable**
- Factures émises/payées
- Montants facturés/encaissés
- Bordereaux traités
- Relances effectuées

### **Technicien**
- Interventions planifiées/réalisées
- Clients visités
- Problèmes résolus
- Temps de travail
- Déplacements

Ce système de reporting est maintenant complètement intégré avec votre backend Laravel et prêt pour l'implémentation Flutter ! 🎯
