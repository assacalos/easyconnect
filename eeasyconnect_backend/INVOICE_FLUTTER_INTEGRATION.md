# 📱 Intégration Flutter - Système de Facturation

## 🎯 **Vue d'ensemble**

Le système de facturation permet de créer, gérer et suivre les factures avec des items détaillés, des templates personnalisables et des statistiques avancées.

## 🔗 **Endpoints API**

### **Base URL**: `http://127.0.0.1:8000/api`

### **Authentification**
Tous les endpoints nécessitent un token Bearer dans l'en-tête :
```
Authorization: Bearer {token}
```

## 📋 **Endpoints Disponibles**

### **1. Liste des Factures**
```http
GET /invoices
```

**Paramètres de requête :**
- `status` (optionnel) : `draft`, `sent`, `paid`, `overdue`, `cancelled`
- `date_debut` (optionnel) : Date de début (YYYY-MM-DD)
- `date_fin` (optionnel) : Date de fin (YYYY-MM-DD)
- `client_id` (optionnel) : ID du client
- `commercial_id` (optionnel) : ID du commercial
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
        "invoice_number": "INV-2025-0001",
        "client_id": 2,
        "client_name": "Entreprise ABC",
        "client_email": "contact@entreprise-abc.com",
        "client_address": "123 Rue de la Paix, Abidjan",
        "commercial_id": 3,
        "commercial_name": "Jean Dupont",
        "invoice_date": "2025-09-24",
        "due_date": "2025-10-24",
        "status": "sent",
        "subtotal": 5000.00,
        "tax_rate": 18.0,
        "tax_amount": 900.00,
        "total_amount": 5900.00,
        "currency": "EUR",
        "notes": "Facture pour services de consultation",
        "terms": "Paiement à 30 jours",
        "payment_info": null,
        "items": [
          {
            "id": 1,
            "description": "Consultation technique",
            "quantity": 10,
            "unit_price": 500.00,
            "total_price": 5000.00,
            "unit": "heure"
          }
        ],
        "sent_at": "2025-09-24 10:30:00",
        "paid_at": null,
        "is_overdue": false,
        "days_until_due": 30,
        "created_at": "2025-09-24 10:00:00",
        "updated_at": "2025-09-24 10:30:00"
      }
    ],
    "total": 50
  },
  "message": "Liste des factures récupérée avec succès"
}
```

### **2. Détails d'une Facture**
```http
GET /invoices/{id}
```

**Réponse :** Même format que l'élément dans la liste

### **3. Créer une Facture**
```http
POST /invoices
```

**Body :**
```json
{
  "client_id": 2,
  "commercial_id": 3,
  "invoice_date": "2025-09-24",
  "due_date": "2025-10-24",
  "subtotal": 5000.00,
  "tax_rate": 18.0,
  "currency": "EUR",
  "notes": "Facture pour services de consultation",
  "terms": "Paiement à 30 jours",
  "items": [
    {
      "description": "Consultation technique",
      "quantity": 10,
      "unit_price": 500.00,
      "unit": "heure"
    },
    {
      "description": "Formation utilisateur",
      "quantity": 2,
      "unit_price": 1000.00,
      "unit": "session"
    }
  ]
}
```

### **4. Mettre à jour une Facture**
```http
PUT /invoices/{id}
```

**Body :** Même format que la création

### **5. Supprimer une Facture**
```http
DELETE /invoices/{id}
```

### **6. Envoyer une Facture**
```http
POST /invoices/{id}/send
```

### **7. Marquer comme Payée**
```http
POST /invoices/{id}/mark-paid
```

**Body :**
```json
{
  "payment_info": {
    "method": "bank_transfer",
    "reference": "PAY-123456",
    "amount": 5900.00,
    "notes": "Paiement reçu par virement"
  }
}
```

### **8. Annuler une Facture**
```http
POST /invoices/{id}/cancel
```

### **9. Statistiques des Factures**
```http
GET /invoices-statistics
```

**Paramètres :**
- `date_debut` (optionnel) : Date de début
- `date_fin` (optionnel) : Date de fin

**Réponse :**
```json
{
  "success": true,
  "data": {
    "total_invoices": 50,
    "draft_invoices": 10,
    "sent_invoices": 20,
    "paid_invoices": 15,
    "overdue_invoices": 5,
    "total_amount": 250000.00,
    "paid_amount": 150000.00,
    "pending_amount": 80000.00,
    "overdue_amount": 20000.00,
    "recent_invoices": [...],
    "monthly_stats": {
      "1": 25000.00,
      "2": 30000.00,
      "3": 28000.00,
      "4": 32000.00,
      "5": 29000.00,
      "6": 31000.00,
      "7": 27000.00,
      "8": 33000.00,
      "9": 30000.00,
      "10": 28000.00,
      "11": 32000.00,
      "12": 29000.00
    }
  },
  "message": "Statistiques récupérées avec succès"
}
```

### **10. Mettre à jour les Factures en Retard**
```http
POST /invoices/update-overdue
```

## 🏗️ **Modèles Dart**

### **InvoiceModel**
```dart
class InvoiceModel {
  final int id;
  final String invoiceNumber;
  final int clientId;
  final String clientName;
  final String clientEmail;
  final String clientAddress;
  final int commercialId;
  final String commercialName;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final String? notes;
  final String? terms;
  final List<InvoiceItem> items;
  final PaymentInfo? paymentInfo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? sentAt;
  final DateTime? paidAt;
  final bool isOverdue;
  final int? daysUntilDue;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientAddress,
    required this.commercialId,
    required this.commercialName,
    required this.invoiceDate,
    required this.dueDate,
    required this.status,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
    required this.currency,
    this.notes,
    this.terms,
    required this.items,
    this.paymentInfo,
    required this.createdAt,
    required this.updatedAt,
    this.sentAt,
    this.paidAt,
    required this.isOverdue,
    this.daysUntilDue,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      invoiceNumber: json['invoice_number'],
      clientId: json['client_id'],
      clientName: json['client_name'],
      clientEmail: json['client_email'],
      clientAddress: json['client_address'],
      commercialId: json['commercial_id'],
      commercialName: json['commercial_name'],
      invoiceDate: DateTime.parse(json['invoice_date']),
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      taxRate: (json['tax_rate'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'EUR',
      notes: json['notes'],
      terms: json['terms'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => InvoiceItem.fromJson(item))
          .toList() ?? [],
      paymentInfo: json['payment_info'] != null 
          ? PaymentInfo.fromJson(json['payment_info']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      isOverdue: json['is_overdue'] ?? false,
      daysUntilDue: json['days_until_due'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'client_name': clientName,
      'client_email': clientEmail,
      'client_address': clientAddress,
      'commercial_id': commercialId,
      'commercial_name': commercialName,
      'invoice_date': invoiceDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'currency': currency,
      'notes': notes,
      'terms': terms,
      'items': items.map((item) => item.toJson()).toList(),
      'payment_info': paymentInfo?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'is_overdue': isOverdue,
      'days_until_due': daysUntilDue,
    };
  }
}
```

### **InvoiceItem**
```dart
class InvoiceItem {
  final int id;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? unit;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.unit,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] ?? 0,
      description: json['description'],
      quantity: json['quantity'],
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      totalPrice: (json['total_price'] ?? 0).toDouble(),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'unit': unit,
    };
  }
}
```

### **PaymentInfo**
```dart
class PaymentInfo {
  final String method; // 'bank_transfer', 'check', 'cash', 'card'
  final String? reference;
  final DateTime? paymentDate;
  final double amount;
  final String? notes;

  PaymentInfo({
    required this.method,
    this.reference,
    this.paymentDate,
    required this.amount,
    this.notes,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      method: json['method'],
      reference: json['reference'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'reference': reference,
      'payment_date': paymentDate?.toIso8601String(),
      'amount': amount,
      'notes': notes,
    };
  }
}
```

### **InvoiceStats**
```dart
class InvoiceStats {
  final int totalInvoices;
  final int draftInvoices;
  final int sentInvoices;
  final int paidInvoices;
  final int overdueInvoices;
  final double totalAmount;
  final double paidAmount;
  final double pendingAmount;
  final double overdueAmount;
  final List<InvoiceModel> recentInvoices;
  final Map<String, double> monthlyStats;

  InvoiceStats({
    required this.totalInvoices,
    required this.draftInvoices,
    required this.sentInvoices,
    required this.paidInvoices,
    required this.overdueInvoices,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.overdueAmount,
    required this.recentInvoices,
    required this.monthlyStats,
  });

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    return InvoiceStats(
      totalInvoices: json['total_invoices'] ?? 0,
      draftInvoices: json['draft_invoices'] ?? 0,
      sentInvoices: json['sent_invoices'] ?? 0,
      paidInvoices: json['paid_invoices'] ?? 0,
      overdueInvoices: json['overdue_invoices'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      overdueAmount: (json['overdue_amount'] ?? 0).toDouble(),
      recentInvoices: (json['recent_invoices'] as List<dynamic>?)
          ?.map((invoice) => InvoiceModel.fromJson(invoice))
          .toList() ?? [],
      monthlyStats: Map<String, double>.from(json['monthly_stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_invoices': totalInvoices,
      'draft_invoices': draftInvoices,
      'sent_invoices': sentInvoices,
      'paid_invoices': paidInvoices,
      'overdue_invoices': overdueInvoices,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'pending_amount': pendingAmount,
      'overdue_amount': overdueAmount,
      'recent_invoices': recentInvoices.map((invoice) => invoice.toJson()).toList(),
      'monthly_stats': monthlyStats,
    };
  }
}
```

### **InvoiceTemplate**
```dart
class InvoiceTemplate {
  final int id;
  final String name;
  final String description;
  final String template;
  final bool isDefault;
  final DateTime createdAt;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.template,
    required this.isDefault,
    required this.createdAt,
  });

  factory InvoiceTemplate.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      template: json['template'],
      isDefault: json['is_default'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'template': template,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

## 🎨 **Widgets Flutter Recommandés**

### **1. Liste des Factures**
```dart
class InvoiceListWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InvoiceModel>>(
      future: InvoiceService.getInvoices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        
        final invoices = snapshot.data ?? [];
        
        return ListView.builder(
          itemCount: invoices.length,
          itemBuilder: (context, index) {
            final invoice = invoices[index];
            return InvoiceCard(invoice: invoice);
          },
        );
      },
    );
  }
}
```

### **2. Carte de Facture**
```dart
class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  
  const InvoiceCard({required this.invoice});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _getStatusIcon(invoice.status),
        title: Text(invoice.invoiceNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${invoice.clientName}'),
            Text('Date: ${_formatDate(invoice.invoiceDate)}'),
            Text('Montant: ${_formatAmount(invoice.totalAmount)} ${invoice.currency}'),
            if (invoice.isOverdue)
              Text('EN RETARD', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_getStatusText(invoice.status)),
            if (invoice.daysUntilDue != null)
              Text('${invoice.daysUntilDue} jours restants'),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceDetail(invoice: invoice),
          ),
        ),
      ),
    );
  }
  
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icon(Icons.edit, color: Colors.grey);
      case 'sent':
        return Icon(Icons.send, color: Colors.blue);
      case 'paid':
        return Icon(Icons.check_circle, color: Colors.green);
      case 'overdue':
        return Icon(Icons.warning, color: Colors.red);
      case 'cancelled':
        return Icon(Icons.cancel, color: Colors.red);
      default:
        return Icon(Icons.help, color: Colors.grey);
    }
  }
}
```

### **3. Formulaire de Création de Facture**
```dart
class CreateInvoiceForm extends StatefulWidget {
  @override
  _CreateInvoiceFormState createState() => _CreateInvoiceFormState();
}

class _CreateInvoiceFormState extends State<CreateInvoiceForm> {
  final _formKey = GlobalKey<FormState>();
  final _itemsController = TextEditingController();
  
  int _clientId = 0;
  int _commercialId = 0;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(Duration(days: 30));
  double _subtotal = 0.0;
  double _taxRate = 18.0;
  String _currency = 'EUR';
  String _notes = '';
  String _terms = 'Paiement à 30 jours';
  List<InvoiceItem> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle Facture')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Sélection du client
            DropdownButtonFormField<int>(
              value: _clientId,
              decoration: InputDecoration(labelText: 'Client'),
              items: _getClientItems(),
              onChanged: (value) => setState(() => _clientId = value ?? 0),
            ),
            
            // Sélection du commercial
            DropdownButtonFormField<int>(
              value: _commercialId,
              decoration: InputDecoration(labelText: 'Commercial'),
              items: _getCommercialItems(),
              onChanged: (value) => setState(() => _commercialId = value ?? 0),
            ),
            
            // Date de facture
            ListTile(
              title: Text('Date de facture'),
              subtitle: Text(_formatDate(_invoiceDate)),
              onTap: _selectInvoiceDate,
            ),
            
            // Date d'échéance
            ListTile(
              title: Text('Date d\'échéance'),
              subtitle: Text(_formatDate(_dueDate)),
              onTap: _selectDueDate,
            ),
            
            // Items de la facture
            ExpansionTile(
              title: Text('Items (${_items.length})'),
              children: [
                ..._items.map((item) => _buildItemCard(item)),
                ElevatedButton(
                  onPressed: _addItem,
                  child: Text('Ajouter un item'),
                ),
              ],
            ),
            
            // Sous-total
            TextFormField(
              initialValue: _subtotal.toString(),
              decoration: InputDecoration(labelText: 'Sous-total'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => _subtotal = double.tryParse(value) ?? 0),
            ),
            
            // Taux de TVA
            TextFormField(
              initialValue: _taxRate.toString(),
              decoration: InputDecoration(labelText: 'Taux de TVA (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => _taxRate = double.tryParse(value) ?? 18),
            ),
            
            // Devise
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: InputDecoration(labelText: 'Devise'),
              items: ['EUR', 'USD', 'XOF'].map((currency) => 
                DropdownMenuItem(value: currency, child: Text(currency))
              ).toList(),
              onChanged: (value) => setState(() => _currency = value ?? 'EUR'),
            ),
            
            // Notes
            TextFormField(
              initialValue: _notes,
              decoration: InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              onChanged: (value) => setState(() => _notes = value),
            ),
            
            // Conditions
            TextFormField(
              initialValue: _terms,
              decoration: InputDecoration(labelText: 'Conditions'),
              maxLines: 2,
              onChanged: (value) => setState(() => _terms = value),
            ),
            
            // Résumé
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Résumé', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    Text('Sous-total: ${_formatAmount(_subtotal)} $_currency'),
                    Text('TVA (${_taxRate}%): ${_formatAmount(_subtotal * _taxRate / 100)} $_currency'),
                    Divider(),
                    Text('Total: ${_formatAmount(_subtotal * (1 + _taxRate / 100))} $_currency',
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveDraft,
                    child: Text('Sauvegarder comme brouillon'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAndSend,
                    child: Text('Créer et envoyer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### **4. Statistiques des Factures**
```dart
class InvoiceStatsWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InvoiceStats>(
      future: InvoiceService.getStatistics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }
        
        final stats = snapshot.data!;
        
        return Column(
          children: [
            _buildStatsRow('Total factures', stats.totalInvoices, Colors.blue),
            _buildStatsRow('Brouillons', stats.draftInvoices, Colors.grey),
            _buildStatsRow('Envoyées', stats.sentInvoices, Colors.orange),
            _buildStatsRow('Payées', stats.paidInvoices, Colors.green),
            _buildStatsRow('En retard', stats.overdueInvoices, Colors.red),
            Divider(),
            _buildStatsRow('Montant total', stats.totalAmount, Colors.purple),
            _buildStatsRow('Montant payé', stats.paidAmount, Colors.green),
            _buildStatsRow('Montant en attente', stats.pendingAmount, Colors.orange),
            _buildStatsRow('Montant en retard', stats.overdueAmount, Colors.red),
          ],
        );
      },
    );
  }
  
  Widget _buildStatsRow(String label, dynamic value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value is double ? _formatAmount(value) : value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🔐 **Gestion des Permissions**

### **Rôles et Accès**
- **Admin/Patron** : Accès complet à toutes les factures
- **RH** : Peut voir toutes les factures
- **Commercial** : Peut voir et gérer ses propres factures
- **Comptable** : Peut voir toutes les factures et gérer les paiements
- **Technicien** : Accès limité selon les besoins

### **Fonctionnalités de Sécurité**
1. **Validation** : Vérification des données avant enregistrement
2. **Permissions** : Contrôle d'accès basé sur les rôles
3. **Audit** : Traçabilité des modifications
4. **Sécurité** : Protection des données sensibles

## 📱 **Fonctionnalités Recommandées**

### **1. Gestion des Factures**
- Création avec items détaillés
- Templates personnalisables
- Calculs automatiques (TVA, totaux)
- Gestion des statuts
- Export PDF

### **2. Suivi des Paiements**
- Marquage des factures payées
- Informations de paiement
- Historique des transactions
- Rappels automatiques

### **3. Statistiques et Rapports**
- Tableaux de bord
- Graphiques de performance
- Analyses de rentabilité
- Rapports personnalisés

### **4. Intégration**
- Synchronisation avec les clients
- Export vers comptabilité
- Notifications automatiques
- API pour intégrations tierces

## 🚀 **Exemple d'Utilisation**

```dart
// Créer une facture
final invoice = await InvoiceService.createInvoice({
  'client_id': 2,
  'commercial_id': 3,
  'invoice_date': '2025-09-24',
  'due_date': '2025-10-24',
  'subtotal': 5000.00,
  'tax_rate': 18.0,
  'currency': 'EUR',
  'notes': 'Facture pour services de consultation',
  'terms': 'Paiement à 30 jours',
  'items': [
    {
      'description': 'Consultation technique',
      'quantity': 10,
      'unit_price': 500.00,
      'unit': 'heure'
    }
  ]
});

// Envoyer une facture
await InvoiceService.sendInvoice(invoice.id);

// Marquer comme payée
await InvoiceService.markAsPaid(invoice.id, {
  'method': 'bank_transfer',
  'reference': 'PAY-123456',
  'amount': 5900.00,
  'notes': 'Paiement reçu par virement'
});

// Obtenir les statistiques
final stats = await InvoiceService.getStatistics(
  dateDebut: DateTime(2025, 9, 1),
  dateFin: DateTime(2025, 9, 30),
);
```

## ⚠️ **Points d'Attention**

1. **Calculs** : Vérifier les calculs de TVA et totaux
2. **Validation** : Valider les données côté client ET serveur
3. **Performance** : Optimiser les requêtes pour les grandes listes
4. **Sécurité** : Protéger les données financières sensibles
5. **UX** : Interface intuitive pour la saisie des factures

## 📊 **Métriques Disponibles**

### **Statistiques Individuelles**
- Nombre de factures par statut
- Montants totaux et payés
- Taux de recouvrement
- Délais de paiement moyens

### **Statistiques Globales**
- Factures par commercial
- Évolution mensuelle
- Analyse des retards
- Performance par client

Ce système de facturation est maintenant **100% fonctionnel** et prêt pour l'intégration Flutter ! 🎯✨
