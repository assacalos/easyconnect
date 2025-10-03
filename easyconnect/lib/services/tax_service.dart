import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/utils/constant.dart';

class TaxService {
  final storage = GetStorage();

  // Tester la connectivité à l'API pour les impôts
  Future<bool> testTaxConnection() async {
    try {
      print('🧪 TaxService: Test de connectivité à l\'API...');
      print('🌐 TaxService: URL de base: $baseUrl');

      final token = storage.read('token');
      print('🔑 TaxService: Token disponible: ${token != null ? "✅" : "❌"}');

      final response = await http
          .get(
            Uri.parse('$baseUrl/taxes-list'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print(
        '📡 TaxService: Test de connectivité - Status: ${response.statusCode}',
      );
      print('📄 TaxService: Test de connectivité - Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ TaxService: Erreur de connectivité: $e');
      return false;
    }
  }

  // Récupérer tous les impôts et taxes
  Future<List<Tax>> getTaxes({
    String? status,
    String? type,
    String? search,
  }) async {
    try {
      print('🌐 TaxService: getTaxes() appelé');
      print('📊 TaxService: status=$status, type=$type, search=$search');

      final token = storage.read('token');
      print('🔑 TaxService: Token récupéré: ${token != null ? "✅" : "❌"}');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/taxes-list$queryString';
      print('🔗 TaxService: URL appelée: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 TaxService: Réponse reçue - Status: ${response.statusCode}');
      print('📄 TaxService: Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          print('📊 TaxService: Response data keys: ${responseData.keys}');

          // Gérer différents formats de réponse de l'API Laravel
          List<dynamic> data = [];

          // Essayer d'abord le format standard Laravel
          if (responseData['data'] != null) {
            if (responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['data']['data'] != null) {
              data = responseData['data']['data'];
            }
          }
          // Essayer le format spécifique aux impôts
          else if (responseData['taxes'] != null) {
            if (responseData['taxes'] is List) {
              data = responseData['taxes'];
            }
          }
          // Essayer le format avec success
          else if (responseData['success'] == true &&
              responseData['taxes'] != null) {
            if (responseData['taxes'] is List) {
              data = responseData['taxes'];
            }
          }

          print('📦 TaxService: ${data.length} impôts trouvés dans l\'API');

          if (data.isEmpty) {
            print('⚠️ TaxService: Aucun impôt trouvé dans l\'API');
            return [];
          }

          try {
            return data.map((json) {
              print('🔍 TaxService: Parsing tax JSON: $json');
              return Tax.fromJson(json);
            }).toList();
          } catch (e) {
            print('❌ TaxService: Erreur lors du parsing des impôts: $e');
            print('📄 TaxService: Données problématiques: $data');
            rethrow;
          }
        } catch (e) {
          print('❌ TaxService: Erreur de parsing JSON: $e');
          print('📄 TaxService: Body content: ${response.body}');
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        print(
          '❌ TaxService: Erreur API ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Erreur lors de la récupération des impôts: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ TaxService: Erreur lors du chargement des impôts: $e');
      rethrow;
    }
  }

  // Récupérer un impôt par ID
  Future<Tax> getTaxById(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/taxes-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Tax.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération de l\'impôt: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.getTaxById: $e');
      throw Exception('Erreur lors de la récupération de l\'impôt: $e');
    }
  }

  // Créer un impôt
  Future<Tax> createTax(Tax tax) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/taxes-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(tax.toJson()),
      );

      if (response.statusCode == 201) {
        return Tax.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création de l\'impôt: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.createTax: $e');
      throw Exception('Erreur lors de la création de l\'impôt: $e');
    }
  }

  // Mettre à jour un impôt
  Future<Tax> updateTax(Tax tax) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/taxes-update/${tax.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(tax.toJson()),
      );

      if (response.statusCode == 200) {
        return Tax.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de l\'impôt: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.updateTax: $e');
      throw Exception('Erreur lors de la mise à jour de l\'impôt: $e');
    }
  }

  // Marquer un impôt comme payé
  Future<bool> markTaxAsPaid(
    int taxId, {
    required String paymentMethod,
    String? reference,
    String? notes,
  }) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/taxes-pay/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'payment_method': paymentMethod,
          'reference': reference,
          'notes': notes,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur TaxService.markTaxAsPaid: $e');
      return false;
    }
  }

  // Supprimer un impôt
  Future<bool> deleteTax(int taxId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/taxes-delete/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur TaxService.deleteTax: $e');
      return false;
    }
  }

  // Récupérer les statistiques des impôts
  Future<TaxStats> getTaxStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/taxes-stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return TaxStats.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.getTaxStats: $e');
      // Retourner des données de test en cas d'erreur
      return TaxStats(
        totalAmount: 0.0,
        pendingAmount: 0.0,
        validatedAmount: 0.0,
        rejectedAmount: 0.0,
        total: 0,
        pending: 0,
        validated: 0,
        rejected: 0,
      );
    }
  }

  // Récupérer les impôts en retard
  Future<List<Tax>> getOverdueTaxes() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/taxes-overdue'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => Tax.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des impôts en retard: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.getOverdueTaxes: $e');
      throw Exception(
        'Erreur lors de la récupération des impôts en retard: $e',
      );
    }
  }

  // Récupérer les impôts à échéance proche
  Future<List<Tax>> getUpcomingTaxes() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/taxes-upcoming'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => Tax.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des impôts à échéance: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.getUpcomingTaxes: $e');
      throw Exception(
        'Erreur lors de la récupération des impôts à échéance: $e',
      );
    }
  }

  // Récupérer les catégories d'impôts
  Future<List<Tax>> getTaxCategories() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/tax-categories-list'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Tax.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des catégories: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.getTaxCategories: $e');
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Créer une catégorie d'impôt
  Future<Tax> createTaxCategory(Tax category) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/tax-categories-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 201) {
        return Tax.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création de la catégorie: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.createTaxCategory: $e');
      throw Exception('Erreur lors de la création de la catégorie: $e');
    }
  }

  // Mettre à jour une catégorie d'impôt
  Future<Tax> updateTaxCategory(Tax category) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/tax-categories-update/${category.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 200) {
        return Tax.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de la catégorie: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur TaxService.updateTaxCategory: $e');
      throw Exception('Erreur lors de la mise à jour de la catégorie: $e');
    }
  }

  // Supprimer une catégorie d'impôt
  Future<bool> deleteTaxCategory(int categoryId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/tax-categories-delete/$categoryId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur TaxService.deleteTaxCategory: $e');
      return false;
    }
  }

  // Approuver une taxe
  Future<bool> approveTax(int taxId, {String? notes}) async {
    try {
      print('✅ TaxService: Approbation de la taxe ID: $taxId');

      final token = storage.read('token');
      print('🔑 TaxService: Token récupéré: ${token != null ? "✅" : "❌"}');

      final response = await http.post(
        Uri.parse('$baseUrl/taxes-approve/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'notes': notes,
          'approved_at': DateTime.now().toIso8601String(),
        }),
      );

      print(
        '📡 TaxService: Réponse d\'approbation - Status: ${response.statusCode}',
      );
      print('📄 TaxService: Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ TaxService: Taxe approuvée avec succès');
        return true;
      } else {
        print(
          '❌ TaxService: Erreur lors de l\'approbation: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      print('❌ TaxService: Erreur lors de l\'approbation de la taxe: $e');
      return false;
    }
  }

  // Rejeter une taxe
  Future<bool> rejectTax(
    int taxId, {
    required String reason,
    String? notes,
  }) async {
    try {
      print('❌ TaxService: Rejet de la taxe ID: $taxId');
      print('📝 TaxService: Raison du rejet: $reason');

      final token = storage.read('token');
      print('🔑 TaxService: Token récupéré: ${token != null ? "✅" : "❌"}');

      final response = await http.post(
        Uri.parse('$baseUrl/taxes-reject/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'reason': reason,
          'notes': notes,
          'rejected_at': DateTime.now().toIso8601String(),
        }),
      );

      print('📡 TaxService: Réponse de rejet - Status: ${response.statusCode}');
      print('📄 TaxService: Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ TaxService: Taxe rejetée avec succès');
        return true;
      } else {
        print('❌ TaxService: Erreur lors du rejet: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ TaxService: Erreur lors du rejet de la taxe: $e');
      return false;
    }
  }

  // Récupérer les taxes en attente d'approbation
  Future<List<Tax>> getPendingTaxes() async {
    try {
      print('⏳ TaxService: Récupération des taxes en attente...');

      final token = storage.read('token');
      print('🔑 TaxService: Token récupéré: ${token != null ? "✅" : "❌"}');

      final response = await http.get(
        Uri.parse('$baseUrl/taxes-pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📡 TaxService: Réponse des taxes en attente - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> data = [];

        // Gérer différents formats de réponse
        if (responseData['data'] != null) {
          data =
              responseData['data'] is List
                  ? responseData['data']
                  : responseData['data']['data'] ?? [];
        } else if (responseData['taxes'] != null) {
          data = responseData['taxes'] is List ? responseData['taxes'] : [];
        }

        print('📦 TaxService: ${data.length} taxes en attente trouvées');

        return data.map((json) => Tax.fromJson(json)).toList();
      } else {
        print(
          '❌ TaxService: Erreur lors de la récupération des taxes en attente: ${response.statusCode}',
        );
        throw Exception(
          'Erreur lors de la récupération des taxes en attente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        '❌ TaxService: Erreur lors de la récupération des taxes en attente: $e',
      );
      throw Exception(
        'Erreur lors de la récupération des taxes en attente: $e',
      );
    }
  }

  // Récupérer l'historique des approbations/rejets
  Future<List<Map<String, dynamic>>> getTaxApprovalHistory(int taxId) async {
    try {
      print(
        '📜 TaxService: Récupération de l\'historique pour la taxe ID: $taxId',
      );

      final token = storage.read('token');
      print('🔑 TaxService: Token récupéré: ${token != null ? "✅" : "❌"}');

      final response = await http.get(
        Uri.parse('$baseUrl/taxes-history/$taxId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📡 TaxService: Réponse de l\'historique - Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> data = responseData['data'] ?? [];

        print('📦 TaxService: ${data.length} entrées d\'historique trouvées');

        return data.cast<Map<String, dynamic>>();
      } else {
        print(
          '❌ TaxService: Erreur lors de la récupération de l\'historique: ${response.statusCode}',
        );
        throw Exception(
          'Erreur lors de la récupération de l\'historique: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(
        '❌ TaxService: Erreur lors de la récupération de l\'historique: $e',
      );
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }
}
