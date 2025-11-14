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
      final token = storage.read('token');
      final response = await http
          .get(
            Uri.parse('$baseUrl/stocks'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
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
      final token = storage.read('token');
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
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      // Gérer les réponses avec différents codes de statut
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
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
          // Si la réponse est directement une liste
          else if (responseData is List) {
            data = responseData;
          }
          if (data.isEmpty) {
            return [];
          }

          try {
            return data.map((json) {
              return Stock.fromJson(json);
            }).toList();
          } catch (e) {
            rethrow;
          }
        } catch (e) {
          throw Exception('Erreur de format des données: $e');
        }
      } else {
        // Pour les erreurs 500, retourner une liste vide plutôt que de planter
        // Cela permet à l'application de continuer à fonctionner
        if (response.statusCode == 500) {
          return [];
        }

        throw Exception(
          'Erreur lors de la récupération des stocks: ${response.statusCode}',
        );
      }
    } catch (e) {
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
      rethrow;
    }
  }

  // Créer un nouveau stock
  Future<Stock> createStock(Stock stock) async {
    try {
      print('🔵 [STOCK_SERVICE] createStock() appelé');
      print(
        '🔵 [STOCK_SERVICE] Stock à créer: name=${stock.name}, category=${stock.category}, sku=${stock.sku}',
      );

      // Validation des champs requis
      if (stock.name.isEmpty) {
        throw Exception('Le nom du produit est requis');
      }
      if (stock.category.isEmpty) {
        throw Exception('La catégorie est requise');
      }
      if (stock.sku.isEmpty) {
        throw Exception('Le SKU est requis');
      }
      // Note: 'unit' n'est pas requis car il n'existe pas dans le backend
      if (stock.quantity < 0) {
        throw Exception('La quantité doit être >= 0');
      }
      if (stock.minQuantity < 0) {
        throw Exception('La quantité minimale doit être >= 0');
      }
      if (stock.maxQuantity < 0) {
        throw Exception('La quantité maximale doit être >= 0');
      }
      if (stock.unitPrice < 0) {
        throw Exception('Le prix unitaire doit être >= 0');
      }

      final stockData = stock.toJson();
      print('🔵 [STOCK_SERVICE] Données JSON à envoyer: $stockData');

      // Essayer d'abord la route stocks-create, puis stocks en fallback
      String url = '$baseUrl/stocks-create';
      print('🔵 [STOCK_SERVICE] Tentative avec route: $url');

      http.Response response;
      try {
        response = await http.post(
          Uri.parse(url),
          headers: ApiService.headers(),
          body: jsonEncode(stockData),
        );
        print(
          '🔵 [STOCK_SERVICE] Réponse route stocks-create - Status: ${response.statusCode}',
        );
      } catch (e) {
        print(
          '⚠️ [STOCK_SERVICE] Route stocks-create échouée, essai route stocks: $e',
        );
        // Si la première route échoue, essayer la route standard
        url = '$baseUrl/stocks';
        print('🔵 [STOCK_SERVICE] Tentative avec route: $url');
        response = await http.post(
          Uri.parse(url),
          headers: ApiService.headers(),
          body: jsonEncode(stockData),
        );
        print(
          '🔵 [STOCK_SERVICE] Réponse route stocks - Status: ${response.statusCode}',
        );
      }

      print(
        '🔵 [STOCK_SERVICE] Réponse finale - Status: ${response.statusCode}',
      );
      print('🔵 [STOCK_SERVICE] Réponse body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔵 [STOCK_SERVICE] Réponse parsée avec succès');
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      // Afficher les détails de l'erreur
      final errorBody = response.body;
      print(
        '❌ [STOCK_SERVICE] Erreur lors de la création - Status: ${response.statusCode}',
      );
      print('❌ [STOCK_SERVICE] Erreur body: $errorBody');

      // Essayer de parser le message d'erreur du backend
      try {
        final errorData = jsonDecode(errorBody);
        final message = errorData['message'] ?? errorBody;
        throw Exception('Erreur ${response.statusCode}: $message');
      } catch (e) {
        throw Exception(
          'Erreur lors de la création du stock: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e, stackTrace) {
      print('❌ [STOCK_SERVICE] Exception createStock: $e');
      print('❌ [STOCK_SERVICE] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Mettre à jour un stock
  Future<Stock> updateStock(Stock stock) async {
    try {
      if (stock.id == null) {
        throw Exception('L\'ID du stock est requis pour la mise à jour');
      }

      final stockData = stock.toJson();
      final response = await http.put(
        Uri.parse('$baseUrl/stocks-update/${stock.id}'),
        headers: ApiService.headers(),
        body: jsonEncode(stockData),
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      final errorBody = response.body;
      throw Exception(
        'Erreur lors de la mise à jour du stock: ${response.statusCode} - $errorBody',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer un stock
  Future<Map<String, dynamic>> deleteStock(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/stocks-destroy/$id'),
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
      rethrow;
    }
  }

  // Ajouter du stock (entrée)
  Future<Stock> addStock({
    required int stockId,
    required double quantity,
    double? unitCost,
    String reason = 'purchase',
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks-add-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'quantity': quantity,
          if (unitCost != null) 'unit_cost': unitCost,
          'reason': reason,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      throw Exception(
        'Erreur lors de l\'ajout du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Retirer du stock (sortie)
  Future<Stock> removeStock({
    required int stockId,
    required double quantity,
    String reason = 'sale',
    String? reference,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks-remove-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'quantity': quantity,
          'reason': reason,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      throw Exception(
        'Erreur lors du retrait du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Ajuster le stock (inventaire)
  Future<Stock> adjustStock({
    required int stockId,
    required double newQuantity,
    String reason = 'adjustment',
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks-adjust-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'new_quantity': newQuantity,
          'reason': reason,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      throw Exception(
        'Erreur lors de l\'ajustement du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Transférer du stock
  Future<Stock> transferStock({
    required int stockId,
    required double quantity,
    required String locationTo,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks-transfer-stock/$stockId'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'quantity': quantity,
          'location_to': locationTo,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      throw Exception(
        'Erreur lors du transfert du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Ajouter un mouvement de stock (ancienne méthode pour compatibilité)
  @Deprecated('Utilisez addStock, removeStock, adjustStock ou transferStock')
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
        Uri.parse('$baseUrl/stocks-movements/$stockId'),
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
      String url = '$baseUrl/stocks-movements/$stockId';
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
      rethrow;
    }
  }

  // Récupérer les statistiques de stock
  Future<StockStats> getStockStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/stocks-statistics';
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
        return StockStats.fromJson(data['data'] ?? data);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les catégories de stock
  Future<List<StockCategory>> getStockCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stocks-categories'),
        headers: ApiService.headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categoriesList = data['data'] ?? data;
        return categoriesList
            .map((json) => StockCategory.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des catégories: ${response.statusCode}',
        );
      }
    } catch (e) {
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
        Uri.parse(
          '$baseUrl/stock-categories',
        ), // Correction: conforme à Laravel
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
      rethrow;
    }
  }

  // Rejeter un stock (endpoint selon la doc: POST /api/stocks/{id}/rejeter)
  // Approuver/Valider un stock
  Future<Stock> approveStock({
    required int stockId,
    String? validationComment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks/$stockId/valider'),
        headers: ApiService.headers(),
        body: jsonEncode({
          if (validationComment != null && validationComment.isNotEmpty)
            'validation_comment': validationComment,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      throw Exception(
        'Erreur lors de l\'approbation du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Stock> rejectStock({
    required int stockId,
    required String commentaire,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stocks/$stockId/rejeter'),
        headers: ApiService.headers(),
        body: jsonEncode({'commentaire': commentaire}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return Stock.fromJson(responseData['data'] ?? responseData);
      }

      throw Exception(
        'Erreur lors du rejet du stock: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }
}
