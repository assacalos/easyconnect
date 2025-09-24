# Intégration Flutter - Système de Paiement

## Vue d'ensemble

Ce document décrit l'intégration du système de paiement backend avec l'application Flutter, basé sur les modèles Flutter fournis.

## Modèles Flutter

### PaymentModel
```dart
class PaymentModel {
  final int id;
  final String paymentNumber;
  final String type; // 'one_time', 'monthly'
  final int clientId;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final int comptableId;
  final String comptableName;
  final DateTime paymentDate;
  final DateTime? dueDate;
  final String status; // 'draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue'
  final double amount;
  final String currency;
  final String paymentMethod; // 'bank_transfer', 'check', 'cash', 'card', 'direct_debit'
  final String? description;
  final String? notes;
  final String? reference;
  final PaymentSchedule? schedule; // Pour les paiements mensuels
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;
}
```

### PaymentSchedule
```dart
class PaymentSchedule {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final int frequency; // Nombre de jours entre les paiements
  final int totalInstallments;
  final int paidInstallments;
  final double installmentAmount;
  final String status; // 'active', 'paused', 'completed', 'cancelled'
  final DateTime? nextPaymentDate;
  final List<PaymentInstallment> installments;
}
```

### PaymentInstallment
```dart
class PaymentInstallment {
  final int id;
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final String status; // 'pending', 'paid', 'overdue'
  final DateTime? paidDate;
  final String? notes;
}
```

### PaymentStats
```dart
class PaymentStats {
  final int totalPayments;
  final int oneTimePayments;
  final int monthlyPayments;
  final int pendingPayments;
  final int approvedPayments;
  final int paidPayments;
  final int overduePayments;
  final double totalAmount;
  final double pendingAmount;
  final double paidAmount;
  final double overdueAmount;
  final List<PaymentModel> recentPayments;
  final Map<String, double> monthlyStats;
  final Map<String, int> paymentMethodStats;
}
```

### PaymentTemplate
```dart
class PaymentTemplate {
  final int id;
  final String name;
  final String description;
  final String type; // 'one_time', 'monthly'
  final double defaultAmount;
  final String defaultPaymentMethod;
  final int? defaultFrequency; // Pour les paiements mensuels
  final String template;
  final bool isDefault;
  final DateTime createdAt;
}
```

## Endpoints API

### Paiements
- `GET /api/payments` - Liste des paiements avec filtres
- `GET /api/payments/{id}` - Détails d'un paiement
- `POST /api/payments` - Créer un nouveau paiement
- `PUT /api/payments/{id}` - Modifier un paiement
- `DELETE /api/payments/{id}` - Supprimer un paiement
- `POST /api/payments/{id}/submit` - Soumettre un paiement
- `POST /api/payments/{id}/approve` - Approuver un paiement
- `POST /api/payments/{id}/reject` - Rejeter un paiement
- `POST /api/payments/{id}/mark-paid` - Marquer comme payé
- `GET /api/payments-statistics` - Statistiques des paiements
- `POST /api/payments/update-overdue` - Mettre à jour les paiements en retard

### Filtres disponibles
- `status` - Statut du paiement
- `type` - Type de paiement (one_time, monthly)
- `date_debut` - Date de début
- `date_fin` - Date de fin
- `client_id` - ID du client
- `comptable_id` - ID du comptable
- `payment_method` - Méthode de paiement
- `per_page` - Nombre d'éléments par page

## Exemples d'utilisation

### Créer un paiement ponctuel
```dart
final paymentData = {
  'type': 'one_time',
  'client_id': 1,
  'comptable_id': 2,
  'payment_date': '2025-01-15',
  'due_date': '2025-02-15',
  'amount': 1500.00,
  'currency': 'EUR',
  'payment_method': 'bank_transfer',
  'description': 'Paiement pour services',
  'notes': 'Paiement standard',
  'reference': 'REF-001'
};

final response = await http.post(
  Uri.parse('$baseUrl/api/payments'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
  body: jsonEncode(paymentData),
);
```

### Créer un paiement mensuel
```dart
final paymentData = {
  'type': 'monthly',
  'client_id': 1,
  'comptable_id': 2,
  'payment_date': '2025-01-15',
  'amount': 500.00,
  'currency': 'EUR',
  'payment_method': 'direct_debit',
  'description': 'Paiement mensuel',
  'schedule': {
    'start_date': '2025-01-15',
    'end_date': '2025-12-15',
    'frequency': 30,
    'description': 'Paiement mensuel pour services'
  }
};
```

### Récupérer les statistiques
```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/payments-statistics?date_debut=2025-01-01&date_fin=2025-12-31'),
  headers: {
    'Authorization': 'Bearer $token',
  },
);

final stats = PaymentStats.fromJson(jsonDecode(response.body)['data']);
```

## Widgets Flutter recommandés

### PaymentListWidget
```dart
class PaymentListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentModel>>(
      future: PaymentService.getPayments(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final payment = snapshot.data![index];
              return PaymentCard(payment: payment);
            },
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

### PaymentCard
```dart
class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  
  const PaymentCard({required this.payment});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(payment.paymentNumber),
        subtitle: Text('${payment.clientName} - ${payment.amount} ${payment.currency}'),
        trailing: Chip(
          label: Text(payment.status),
          backgroundColor: _getStatusColor(payment.status),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailPage(payment: payment),
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft': return Colors.grey;
      case 'submitted': return Colors.blue;
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'paid': return Colors.green;
      case 'overdue': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
```

### PaymentStatsWidget
```dart
class PaymentStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaymentStats>(
      future: PaymentService.getStats(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final stats = snapshot.data!;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: StatCard('Total', stats.totalPayments.toString())),
                  Expanded(child: StatCard('Payés', stats.paidPayments.toString())),
                ],
              ),
              Row(
                children: [
                  Expanded(child: StatCard('En attente', stats.pendingPayments.toString())),
                  Expanded(child: StatCard('En retard', stats.overduePayments.toString())),
                ],
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## Gestion des erreurs

```dart
class PaymentService {
  static Future<List<PaymentModel>> getPayments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/payments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']['data'] as List)
            .map((json) => PaymentModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération des paiements');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
```

## Authentification

Tous les endpoints nécessitent une authentification via token Bearer :

```dart
final headers = {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
};
```

## Pagination

Les listes de paiements supportent la pagination :

```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/payments?page=1&per_page=20'),
  headers: {'Authorization': 'Bearer $token'},
);

final data = jsonDecode(response.body);
final payments = (data['data']['data'] as List)
    .map((json) => PaymentModel.fromJson(json))
    .toList();
final currentPage = data['data']['current_page'];
final totalPages = data['data']['last_page'];
```

## Filtres avancés

```dart
// Filtrer par statut et type
final response = await http.get(
  Uri.parse('$baseUrl/api/payments?status=paid&type=one_time'),
  headers: {'Authorization': 'Bearer $token'},
);

// Filtrer par date
final response = await http.get(
  Uri.parse('$baseUrl/api/payments?date_debut=2025-01-01&date_fin=2025-01-31'),
  headers: {'Authorization': 'Bearer $token'},
);

// Filtrer par client
final response = await http.get(
  Uri.parse('$baseUrl/api/payments?client_id=1'),
  headers: {'Authorization': 'Bearer $token'},
);
```

## Notes importantes

1. **Gestion des rôles** : Les comptables ne voient que leurs propres paiements
2. **Validation** : Les paiements ne peuvent être modifiés qu'en statut 'draft'
3. **États** : Les transitions d'état sont contrôlées (draft → submitted → approved → paid)
4. **Paiements mensuels** : Créent automatiquement un échéancier avec des échéances
5. **Templates** : Support des templates HTML pour la génération de documents
6. **Statistiques** : Calculs automatiques des métriques de performance
