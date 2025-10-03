import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/utils/constant.dart';

class SupplierService extends GetxService {
  static SupplierService get to => Get.find();

  final storage = GetStorage();

  // Récupérer tous les fournisseurs
  Future<List<Supplier>> getSuppliers({String? status, String? search}) async {
    print('🌐 SupplierService: getSuppliers() appelé');
    print('📊 SupplierService: status = $status, search = $search');

    try {
      final token = storage.read('token');
      print('🔑 SupplierService: Token récupéré: ${token != null ? "✅" : "❌"}');

      var queryParams = <String, String>{};
      if (status != null && status != 'all') queryParams['statut'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/fournisseurs-list$queryString';
      print('🔗 SupplierService: URL appelée: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
        '📡 SupplierService: Réponse reçue - Status: ${response.statusCode}',
      );
      print('📄 SupplierService: Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 SupplierService: Response data keys: ${responseData.keys}');
        print('📄 SupplierService: Full response: ${response.body}');

        // Essayer différents formats de réponse
        List<dynamic> data = [];

        if (responseData['data'] != null) {
          data = responseData['data'];
          print(
            '📦 SupplierService: Données trouvées dans "data": ${data.length}',
          );
        } else if (responseData['fournisseurs'] != null) {
          data = responseData['fournisseurs'];
          print(
            '📦 SupplierService: Données trouvées dans "fournisseurs": ${data.length}',
          );
        } else if (responseData is List) {
          data = responseData;
          print(
            '📦 SupplierService: Données trouvées directement dans la liste: ${data.length}',
          );
        } else {
          print('❌ SupplierService: Format de réponse non reconnu');
          print('📄 SupplierService: Structure: ${responseData.runtimeType}');
          return [];
        }

        if (data.isNotEmpty) {
          print('📋 SupplierService: Premier élément: ${data.first}');
        }

        try {
          final suppliers =
              data.map((json) => Supplier.fromJson(json)).toList();
          print('✅ SupplierService: ${suppliers.length} fournisseurs créés');
          return suppliers;
        } catch (e) {
          print(
            '❌ SupplierService: Erreur lors du parsing des fournisseurs: $e',
          );
          print(
            '📋 SupplierService: Premier élément problématique: ${data.isNotEmpty ? data.first : "Aucun"}',
          );
          return [];
        }
      }

      print('❌ SupplierService: Erreur HTTP ${response.statusCode}');
      print('📄 SupplierService: Response body: ${response.body}');
      return [];
    } catch (e) {
      print('❌ SupplierService: Exception globale dans getSuppliers: $e');
      print('🔍 SupplierService: Type d\'erreur: ${e.runtimeType}');
      return [];
    }
  }

  // Récupérer un fournisseur par ID
  Future<Supplier> getSupplierById(int id) async {
    print('🔍 SupplierService: getSupplierById($id) appelé');

    final token = storage.read('token');
    final response = await http.get(
      Uri.parse('$baseUrl/fournisseurs-show/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la récupération du fournisseur: ${response.statusCode}',
    );
  }

  // Créer un fournisseur
  Future<Supplier> createSupplier(Supplier supplier) async {
    print('➕ SupplierService: createSupplier() appelé');
    print('📝 SupplierService: Nom = ${supplier.nom}');

    final token = storage.read('token');
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-create'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(supplier.toJson()),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la création du fournisseur: ${response.statusCode}',
    );
  }

  // Mettre à jour un fournisseur
  Future<Supplier> updateSupplier(Supplier supplier) async {
    print('✏️ SupplierService: updateSupplier(${supplier.id}) appelé');

    final token = storage.read('token');
    final response = await http.put(
      Uri.parse('$baseUrl/fournisseurs-update/${supplier.id}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(supplier.toJson()),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la mise à jour du fournisseur: ${response.statusCode}',
    );
  }

  // Supprimer un fournisseur
  Future<bool> deleteSupplier(int supplierId) async {
    print('🗑️ SupplierService: deleteSupplier($supplierId) appelé');

    final token = storage.read('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/fournisseurs-delete/$supplierId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Récupérer les statistiques
  Future<SupplierStats> getSupplierStats() async {
    print('📊 SupplierService: getSupplierStats() appelé');

    final token = storage.read('token');
    final response = await http.get(
      Uri.parse('$baseUrl/fournisseurs-stats'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return SupplierStats.fromJson(responseData['data']);
    }

    throw Exception(
      'Erreur lors de la récupération des statistiques: ${response.statusCode}',
    );
  }

  // Récupérer les fournisseurs en attente
  Future<List<Supplier>> getPendingSuppliers() async {
    print('⏳ SupplierService: getPendingSuppliers() appelé');

    final token = storage.read('token');
    final response = await http.get(
      Uri.parse('$baseUrl/fournisseurs-list?statut=pending'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final List<dynamic> data = responseData['data'] ?? [];
      return data.map((json) => Supplier.fromJson(json)).toList();
    }

    throw Exception(
      'Erreur lors de la récupération des fournisseurs en attente: ${response.statusCode}',
    );
  }

  // Approuver un fournisseur
  Future<bool> approveSupplier(int supplierId, {String? comments}) async {
    print('✅ SupplierService: approveSupplier($supplierId) appelé');

    final token = storage.read('token');
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-validate/$supplierId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'comments': comments}),
    );

    return response.statusCode == 200;
  }

  // Rejeter un fournisseur
  Future<bool> rejectSupplier(int supplierId, String reason) async {
    print('❌ SupplierService: rejectSupplier($supplierId) appelé');

    final token = storage.read('token');
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-reject/$supplierId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );

    return response.statusCode == 200;
  }

  // Évaluer un fournisseur
  Future<bool> rateSupplier(
    int supplierId,
    double rating, {
    String? comments,
  }) async {
    print('⭐ SupplierService: rateSupplier($supplierId, $rating) appelé');

    final token = storage.read('token');
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-rate/$supplierId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'rating': rating, 'comments': comments}),
    );

    return response.statusCode == 200;
  }

  // Soumettre un fournisseur
  Future<bool> submitSupplier(int supplierId) async {
    print('📤 SupplierService: submitSupplier($supplierId) appelé');

    final token = storage.read('token');
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-submit/$supplierId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
