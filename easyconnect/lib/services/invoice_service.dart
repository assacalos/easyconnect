import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class InvoiceService extends GetxService {
  static InvoiceService get to => Get.find();

  // Créer une facture
  Future<Map<String, dynamic>> createInvoice({
    required int clientId,
    required String clientName,
    required String clientEmail,
    required String clientAddress,
    required int commercialId,
    required String commercialName,
    required DateTime invoiceDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    required double taxRate,
    String? notes,
    String? terms,
  }) async {
    try {
      // Calculer les montants
      final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final taxAmount = subtotal * (taxRate / 100);
      final totalAmount = subtotal + taxAmount;

      final response = await http.post(
        Uri.parse('$baseUrl/factures-create'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'client_id': clientId,
          'nom': clientName,
          'email': clientEmail,
          'adresse': clientAddress,
          'user_id': commercialId,
          'commercial_name': commercialName,
          'invoice_date': invoiceDate.toIso8601String(),
          'due_date': dueDate.toIso8601String(),
          'items': items.map((item) => item.toJson()).toList(),
          'subtotal': subtotal,
          'tax_rate': taxRate,
          'tax_amount': taxAmount,
          'total_amount': totalAmount,
          'notes': notes,
          'terms': terms,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Le backend retourne {'success': true, 'data': {...}, 'message': '...'}
        return responseBody;
      } else {
        throw Exception(
          'Erreur lors de la création de la facture: ${response.statusCode} - ${responseBody['message'] ?? response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les factures d'un comptable
  Future<List<InvoiceModel>> getCommercialInvoices({
    required int commercialId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/factures-list';
      List<String> params = [];

      params.add('commercial_id=$commercialId');
      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> invoiceList = data['data'] ?? [];
        if (invoiceList.isEmpty) {
          return [];
        }

        final invoices = <InvoiceModel>[];
        for (var json in invoiceList) {
          try {
            final invoice = InvoiceModel.fromJson(json);
            invoices.add(invoice);
          } catch (e, stackTrace) {
          }
        }
        return invoices;
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures commerciales: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      throw Exception(
        'Erreur lors de la récupération des factures commerciales: $e',
      );
    }
  }

  // Récupérer toutes les factures (pour le patron)
  Future<List<InvoiceModel>> getAllInvoices({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? commercialId,
    int? clientId,
  }) async {
    try {
      String url = '$baseUrl/factures-list';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (status != null) {
        params.add('status=$status');
      }
      if (commercialId != null) {
        params.add('commercial_id=$commercialId');
      }
      if (clientId != null) {
        params.add('client_id=$clientId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> invoiceList = data['data'] ?? [];
        if (invoiceList.isEmpty) {
          return [];
        }

        final invoices = <InvoiceModel>[];
        for (var json in invoiceList) {
          try {
            final invoice = InvoiceModel.fromJson(json);
            invoices.add(invoice);
          } catch (e, stackTrace) {
          }
        }
        return invoices;
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      throw Exception('Erreur lors de la récupération des factures: $e');
    }
  }

  // Récupérer une facture par ID
  Future<InvoiceModel> getInvoiceById(int invoiceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/factures-show/$invoiceId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InvoiceModel.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour une facture
  Future<Map<String, dynamic>> updateInvoice({
    required int invoiceId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/factures-update/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Soumettre une facture au patron
  Future<Map<String, dynamic>> submitInvoiceToPatron(int invoiceId) async {
    try {
      // Route non disponible dans Laravel - utiliser factures-create à la place
      final response = await http.post(
        Uri.parse('$baseUrl/factures-create'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la soumission de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Approuver une facture (pour le patron)
  Future<Map<String, dynamic>> approveInvoice({
    required int invoiceId,
    String? comments,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/factures-validate/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Rejeter une facture (pour le patron)
  Future<Map<String, dynamic>> rejectInvoice({
    required int invoiceId,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/factures-reject/$invoiceId'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Envoyer une facture par email
  Future<Map<String, dynamic>> sendInvoiceByEmail({
    required int invoiceId,
    required String email,
    String? message,
  }) async {
    try {
      // Route non disponible dans Laravel - utiliser factures-create à la place
      final response = await http.post(
        Uri.parse('$baseUrl/factures-create'),
        headers: ApiService.headers(),
        body: jsonEncode({'email': email, 'message': message}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'envoi de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Marquer une facture comme payée
  Future<Map<String, dynamic>> markInvoiceAsPaid({
    required int invoiceId,
    required PaymentInfo paymentInfo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/factures/$invoiceId/mark-paid'),
        headers: ApiService.headers(),
        body: jsonEncode(paymentInfo.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du paiement de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une facture
  Future<Map<String, dynamic>> deleteInvoice(int invoiceId) async {
    try {
      // Route de suppression non disponible dans Laravel
      final response = await http.delete(
        Uri.parse('$baseUrl/factures-update/$invoiceId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression de la facture: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les statistiques de facturation
  Future<InvoiceStats> getInvoiceStats({
    DateTime? startDate,
    DateTime? endDate,
    int? commercialId,
  }) async {
    try {
      String url = '$baseUrl/factures-reports';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (commercialId != null) {
        params.add('commercial_id=$commercialId');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return InvoiceStats.fromJson(data);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les factures en attente d'approbation (pour le patron)
  Future<List<InvoiceModel>> getPendingInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/factures-list?status=pending'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> invoiceList = data['data'] ?? [];
        return invoiceList.map((json) => InvoiceModel.fromJson(json)).toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des factures en attente: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Générer un numéro de facture
  Future<String> generateInvoiceNumber() async {
    try {
      // Route non disponible dans Laravel - générer côté client
      final response = await http.get(
        Uri.parse('$baseUrl/factures-list'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['invoice_number'];
      } else {
        throw Exception(
          'Erreur lors de la génération du numéro: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les modèles de facture
  Future<List<InvoiceTemplate>> getInvoiceTemplates() async {
    try {
      // Route non disponible dans Laravel - utiliser factures-reports
      final response = await http.get(
        Uri.parse('$baseUrl/factures-reports'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> templateList = data['data'] ?? [];
        return templateList
            .map((json) => InvoiceTemplate.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des modèles: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Méthode pour générer des données mockées (DÉSACTIVÉE - utilisez les vraies données de l'API)
  // Cette méthode n'est plus utilisée et peut être supprimée
  @Deprecated('Utilisez getAllInvoices() ou getCommercialInvoices() à la place')
  List<InvoiceModel> getMockInvoices() {
    return [
      InvoiceModel(
        id: 1,
        invoiceNumber: 'FAC-2024-001',
        clientId: 1,
        clientName: 'Client Test 1',
        clientEmail: 'client1@test.com',
        clientAddress: '123 Rue Test, Paris',
        commercialId: 1,
        commercialName: 'Commercial Test',
        invoiceDate: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 25)),
        subtotal: 1000.0,
        taxRate: 20.0,
        taxAmount: 200.0,
        totalAmount: 1200.0,
        status: 'en_attente',
        notes: 'Facture de test',
        terms: 'Paiement à 30 jours',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        currency: 'fcfa',
        items: [
          InvoiceItem(
            id: 1,
            description: 'Service de consultation',
            quantity: 1,
            unitPrice: 1000.0,
            totalPrice: 1000.0,
          ),
        ],
      ),
      InvoiceModel(
        id: 2,
        invoiceNumber: 'FAC-2024-002',
        clientId: 2,
        clientName: 'Client Test 2',
        clientEmail: 'client2@test.com',
        clientAddress: '456 Avenue Test, Lyon',
        commercialId: 1,
        commercialName: 'Commercial Test',
        invoiceDate: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 27)),
        subtotal: 1500.0,
        taxRate: 20.0,
        taxAmount: 300.0,
        totalAmount: 1800.0,
        status: 'valide',
        notes: 'Facture approuvée',
        terms: 'Paiement à 30 jours',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        currency: 'fcfa',
        items: [
          InvoiceItem(
            id: 2,
            description: 'Développement web',
            quantity: 1,
            unitPrice: 1500.0,
            totalPrice: 1500.0,
          ),
        ],
      ),
      InvoiceModel(
        id: 3,
        invoiceNumber: 'FAC-2024-003',
        clientId: 3,
        clientName: 'Client Test 3',
        clientEmail: 'client3@test.com',
        clientAddress: '789 Boulevard Test, Marseille',
        commercialId: 1,
        commercialName: 'Commercial Test',
        invoiceDate: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 29)),
        subtotal: 800.0,
        taxRate: 20.0,
        taxAmount: 160.0,
        totalAmount: 960.0,
        status: 'en_attente',
        notes: 'Facture en attente',
        terms: 'Paiement à 30 jours',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        currency: 'fcfa',
        items: [
          InvoiceItem(
            id: 3,
            description: 'Maintenance',
            quantity: 1,
            unitPrice: 800.0,
            totalPrice: 800.0,
          ),
        ],
      ),
      InvoiceModel(
        id: 4,
        invoiceNumber: 'FAC-2024-004',
        clientId: 4,
        clientName: 'Client Test 4',
        clientEmail: 'client4@test.com',
        clientAddress: '321 Rue Test, Toulouse',
        commercialId: 1,
        commercialName: 'Commercial Test',
        invoiceDate: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().add(const Duration(days: 28)),
        subtotal: 600.0,
        taxRate: 20.0,
        taxAmount: 120.0,
        totalAmount: 720.0,
        status: 'rejete',
        notes: 'Facture rejetée',
        terms: 'Paiement à 30 jours',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        currency: 'fcfa',
        items: [
          InvoiceItem(
            id: 4,
            description: 'Service rejeté',
            quantity: 1,
            unitPrice: 600.0,
            totalPrice: 600.0,
          ),
        ],
      ),
    ];
  }
}
