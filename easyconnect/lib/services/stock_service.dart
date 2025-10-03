import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class StockService extends GetxService {
  static StockService get to => Get.find();
  final storage = GetStorage();

  // Tester la connectivité à l'API
  Future<bool> testConnection() async {
    try {
      print('🧪 StockService: Test de connectivité à l\'API...');
      print('🌐 StockService: URL de base: $baseUrl');

      final token = storage.read('token');
      print('🔑 StockService: Token disponible: ${token != null ? "✅" : "❌"}');

      final response = await http
          .get(
            Uri.parse('$baseUrl/stocks'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      print(
        '📡 StockService: Test de connectivité - Status: ${response.statusCode}',
      );
      print('📄 StockService: Test de connectivité - Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ StockService: Erreur de connectivité: $e');
      return false;
    }
  }

  // Récupérer tous les stocks
  Future<List<Stock>> getStocks({
    String? search,
    String? category,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      print('🌐 StockService: getStocks() appelé');
      print(
        '📊 StockService: search=$search, category=$category, status=$status',
      );

      final token = storage.read('token');
      print('🔑 StockService: Token récupéré: ${token != null ? "✅" : "❌"}');

      String url = '$baseUrl/stocks';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (category != null && category.isNotEmpty) {
        params.add('category=$category');
      }
      if (status != null && status.isNotEmpty) {
        params.add('status=$status');
      }
      if (page != null) {
        params.add('page=$page');
      }
      if (limit != null) {
        params.add('limit=$limit');
      }

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print('🔗 StockService: URL appelée: $url');
      print(
        '🔑 StockService: Headers: Accept: application/json, Authorization: Bearer $token',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 StockService: Réponse reçue - Status: ${response.statusCode}');
      print('📄 StockService: Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          print('📊 StockService: Response data keys: ${responseData.keys}');
          print('📄 StockService: Response data content: $responseData');

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
          // Essayer le format spécifique aux stocks
          else if (responseData['stocks'] != null) {
            if (responseData['stocks'] is List) {
              data = responseData['stocks'];
            }
          }
          // Essayer le format avec success
          else if (responseData['success'] == true &&
              responseData['stocks'] != null) {
            if (responseData['stocks'] is List) {
              data = responseData['stocks'];
            }
          }

          print('📦 StockService: ${data.length} stocks trouvés dans l\'API');

          if (data.isEmpty) {
            print('⚠️ StockService: Aucun stock trouvé dans l\'API');
            print(
              '📄 StockService: Structure de réponse: ${responseData.runtimeType}',
            );
            print('📄 StockService: Contenu complet: $responseData');
            return [];
          }

          try {
            return data.map((json) {
              print('🔍 StockService: Parsing stock JSON: $json');
              return Stock.fromJson(json);
            }).toList();
          } catch (e) {
            print('❌ StockService: Erreur lors du parsing des stocks: $e');
            print('📄 StockService: Données problématiques: $data');
            rethrow;
          }
        } catch (e) {
          print('❌ StockService: Erreur de parsing JSON: $e');
          print('📄 StockService: Body content: ${response.body}');
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        print(
          '❌ StockService: Erreur API ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Erreur lors de la récupération des stocks: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ StockService: Erreur lors du chargement: $e');
      rethrow;
    }
  }

  // Récupérer un stock par ID
  Future<Stock> getStock(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/stocks/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Stock.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération du stock: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.getStock: $e');
      rethrow;
    }
  }

  // Créer un nouveau stock
  Future<Map<String, dynamic>> createStock({
    required String name,
    required String description,
    required String category,
    required String sku,
    required double quantity,
    required double minQuantity,
    required double maxQuantity,
    required double unitPrice,
    required String unit,
    String? location,
    String? supplier,
    String? barcode,
    String? image,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'category': category,
          'sku': sku,
          'quantity': quantity,
          'min_quantity': minQuantity,
          'max_quantity': maxQuantity,
          'unit_price': unitPrice,
          'unit': unit,
          'location': location,
          'supplier': supplier,
          'barcode': barcode,
          'image': image,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création du stock: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.createStock: $e');
      rethrow;
    }
  }

  // Mettre à jour un stock
  Future<Map<String, dynamic>> updateStock({
    required int id,
    required String name,
    required String description,
    required String category,
    required String sku,
    required double minQuantity,
    required double maxQuantity,
    required double unitPrice,
    required String unit,
    String? location,
    String? supplier,
    String? barcode,
    String? image,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/stocks/$id'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'category': category,
          'sku': sku,
          'min_quantity': minQuantity,
          'max_quantity': maxQuantity,
          'unit_price': unitPrice,
          'unit': unit,
          'location': location,
          'supplier': supplier,
          'barcode': barcode,
          'image': image,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour du stock: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.updateStock: $e');
      rethrow;
    }
  }

  // Supprimer un stock
  Future<Map<String, dynamic>> deleteStock(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/stocks/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression du stock: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.deleteStock: $e');
      rethrow;
    }
  }

  // Ajouter un mouvement de stock
  Future<Map<String, dynamic>> addStockMovement({
    required int stockId,
    required String type,
    required double quantity,
    String? reason,
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks/$stockId/movements'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'type': type,
          'quantity': quantity,
          'reason': reason,
          'reference': reference,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du mouvement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.addStockMovement: $e');
      rethrow;
    }
  }

  // Récupérer les mouvements d'un stock
  Future<List<StockMovement>> getStockMovements({
    required int stockId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    try {
      String url = '$baseUrl/stocks/$stockId/movements';
      List<String> params = [];

      if (type != null && type.isNotEmpty) {
        params.add('type=$type');
      }
      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (page != null) {
        params.add('page=$page');
      }
      if (limit != null) {
        params.add('limit=$limit');
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
        return (data['data'] as List)
            .map((json) => StockMovement.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des mouvements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.getStockMovements: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques de stock
  Future<StockStats> getStockStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/stocks/stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
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
        return StockStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.getStockStats: $e');
      rethrow;
    }
  }

  // Récupérer les catégories de stock
  Future<List<StockCategory>> getStockCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stocks/categories'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => StockCategory.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des catégories: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.getStockCategories: $e');
      rethrow;
    }
  }

  // Créer une catégorie de stock
  Future<Map<String, dynamic>> createStockCategory({
    required String name,
    required String description,
    String? parentCategory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks/categories'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'description': description,
          'parent_category': parentCategory,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création de la catégorie: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.createStockCategory: $e');
      rethrow;
    }
  }

  // Récupérer les alertes de stock
  Future<List<StockAlert>> getStockAlerts({
    bool? unreadOnly,
    String? type,
  }) async {
    try {
      String url = '$baseUrl/stocks/alerts';
      List<String> params = [];

      if (unreadOnly == true) {
        params.add('unread_only=true');
      }
      if (type != null && type.isNotEmpty) {
        params.add('type=$type');
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
        return (data['data'] as List)
            .map((json) => StockAlert.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des alertes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.getStockAlerts: $e');
      rethrow;
    }
  }

  // Marquer une alerte comme lue
  Future<Map<String, dynamic>> markAlertAsRead(int alertId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/stocks/alerts/$alertId/read'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du marquage de l\'alerte: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.markAlertAsRead: $e');
      rethrow;
    }
  }

  // Rechercher des stocks par code-barres
  Future<Stock?> searchStockByBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stocks/search/barcode/$barcode'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Stock.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception(
          'Erreur lors de la recherche par code-barres: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.searchStockByBarcode: $e');
      rethrow;
    }
  }

  // Ajuster le stock
  Future<Map<String, dynamic>> adjustStock({
    required int stockId,
    required double newQuantity,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks/$stockId/adjust'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'new_quantity': newQuantity,
          'reason': reason,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajustement du stock: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur StockService.adjustStock: $e');
      rethrow;
    }
  }

  // Mettre à jour le statut d'approbation d'un stock
  Future<Map<String, dynamic>> updateStockStatus(
    int stockId,
    String status,
    String? comments,
  ) async {
    try {
      print('🔄 StockService: updateStockStatus($stockId, $status) appelé');

      final token = storage.read('token');
      print('🔑 StockService: Token récupéré: ${token != null ? "✅" : "❌"}');

      final response = await http.patch(
        Uri.parse('$baseUrl/stocks/$stockId/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': status, 'comments': comments}),
      );

      print('📡 StockService: Réponse reçue - Status: ${response.statusCode}');
      print('📄 StockService: Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ StockService: Statut mis à jour avec succès');
        return jsonDecode(response.body);
      } else {
        print(
          '❌ StockService: Erreur API ${response.statusCode}: ${response.body}',
        );
        throw Exception(
          'Erreur lors de la mise à jour du statut: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ StockService: Erreur lors de la mise à jour du statut: $e');
      rethrow;
    }
  }

  // Valider un stock
  Future<Map<String, dynamic>> approveStock(int stockId) async {
    return await updateStockStatus(stockId, 'approved', null);
  }

  // Rejeter un stock
  Future<Map<String, dynamic>> rejectStock(int stockId, String reason) async {
    return await updateStockStatus(stockId, 'rejected', reason);
  }
}
