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
    try {
      final token = storage.read('token');
      var queryParams = <String, String>{};
      if (status != null && status != 'all') {
        // Normaliser le statut vers le format backend
        String backendStatus = status;
        if (status == 'pending') backendStatus = 'en_attente';
        if (status == 'approved' || status == 'validated')
          backendStatus = 'valide';
        if (status == 'rejected') backendStatus = 'rejete';
        queryParams['statut'] = backendStatus;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '$baseUrl/fournisseurs-list$queryString';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Essayer différents formats de réponse
        List<dynamic> data = [];

        if (responseData['data'] != null) {
          data = responseData['data'];
        } else if (responseData['fournisseurs'] != null) {
          data = responseData['fournisseurs'];
        } else if (responseData is List) {
          data = responseData;
        } else {
          return [];
        }

        if (data.isNotEmpty) {}

        try {
          final suppliers =
              data.map((json) => Supplier.fromJson(json)).toList();
          return suppliers;
        } catch (e) {
          return [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Récupérer un fournisseur par ID
  Future<Supplier> getSupplierById(int id) async {
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
    // Validation des champs requis
    if (supplier.nom.isEmpty) {
      throw Exception('Le nom du fournisseur est requis');
    }
    if (supplier.email.isEmpty) {
      throw Exception('L\'email est requis');
    }
    if (supplier.telephone.isEmpty) {
      throw Exception('Le téléphone est requis');
    }
    if (supplier.adresse.isEmpty) {
      throw Exception('L\'adresse est requise');
    }
    if (supplier.ville.isEmpty) {
      throw Exception('La ville est requise');
    }
    if (supplier.pays.isEmpty) {
      throw Exception('Le pays est requis');
    }

    final token = storage.read('token');
    final supplierData = supplier.toJson();
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-create'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(supplierData),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return Supplier.fromJson(responseData['data'] ?? responseData);
    }

    // Afficher les détails de l'erreur
    final errorBody = response.body;
    throw Exception(
      'Erreur lors de la création du fournisseur: ${response.statusCode} - $errorBody',
    );
  }

  // Mettre à jour un fournisseur
  Future<Supplier> updateSupplier(Supplier supplier) async {
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

  // Supprimer un fournisseur (soft delete)
  Future<bool> deleteSupplier(int supplierId) async {
    final token = storage.read('token');
    final response = await http.delete(
      Uri.parse('$baseUrl/fournisseurs-destroy/$supplierId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  // Récupérer les statistiques
  Future<SupplierStats> getSupplierStats() async {
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

  // Valider un fournisseur
  Future<bool> approveSupplier(
    int supplierId, {
    String? validationComment,
  }) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/fournisseurs-validate/$supplierId';
      final body = {
        if (validationComment != null && validationComment.isNotEmpty)
          'validation_comment': validationComment,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Ce fournisseur ne peut pas être validé';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors de la validation';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e, stackTrace) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Rejeter un fournisseur
  Future<bool> rejectSupplier(
    int supplierId, {
    required String rejectionReason,
    String? rejectionComment,
  }) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/fournisseurs-reject/$supplierId';
      final body = {
        'rejection_reason': rejectionReason,
        if (rejectionComment != null && rejectionComment.isNotEmpty)
          'rejection_comment': rejectionComment,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Ce fournisseur ne peut pas être rejeté';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e, stackTrace) {
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Évaluer un fournisseur
  Future<bool> rateSupplier(
    int supplierId,
    double rating, {
    String? comments,
  }) async {
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
    final token = storage.read('token');
    final response = await http.post(
      Uri.parse('$baseUrl/fournisseurs-submit/$supplierId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }
}
