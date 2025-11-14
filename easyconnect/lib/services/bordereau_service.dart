import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/utils/roles.dart';

class BordereauService {
  final storage = GetStorage();

  Future<List<Bordereau>> getBordereaux({int? status}) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bordereaux-list$queryString';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Gérer le cas où les données sont directement dans un tableau
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData['data'] != null) {
          data = responseData['data'];
        } else {
          return [];
        }

        final List<Bordereau> bordereauList =
            data
                .map((json) {
                  try {
                    return Bordereau.fromJson(json);
                  } catch (e) {
                    return null;
                  }
                })
                .where((bordereau) => bordereau != null)
                .cast<Bordereau>()
                .toList();

        return bordereauList;
      }

      throw Exception(
        'Erreur lors de la récupération des bordereaux: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des bordereaux: $e');
    }
  }

  Future<Bordereau> createBordereau(Bordereau bordereau) async {
    try {
      final token = storage.read('token');

      final bordereauJson = bordereau.toJson();

      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bordereauJson),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Gérer différents formats de réponse
          Map<String, dynamic> bordereauData;
          if (responseData is Map) {
            if (responseData['data'] != null) {
              bordereauData =
                  responseData['data'] is Map<String, dynamic>
                      ? responseData['data']
                      : Map<String, dynamic>.from(responseData['data']);
            } else if (responseData['bordereau'] != null) {
              bordereauData =
                  responseData['bordereau'] is Map<String, dynamic>
                      ? responseData['bordereau']
                      : Map<String, dynamic>.from(responseData['bordereau']);
            } else {
              bordereauData =
                  responseData is Map<String, dynamic>
                      ? responseData
                      : Map<String, dynamic>.from(responseData);
            }
          } else {
            throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}',
            );
          }

          final createdBordereau = Bordereau.fromJson(bordereauData);
          return createdBordereau;
        } catch (parseError) {
          throw Exception('Erreur lors du parsing de la réponse: $parseError');
        }
      } else if (response.statusCode == 403) {
        // Gestion spécifique de l'erreur 403 (Accès refusé)
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Accès refusé';
          final requiredRoles = errorData['required_roles'] as List<dynamic>?;
          final userRole = errorData['user_role'];

          String errorMessage = message;
          if (requiredRoles != null && userRole != null) {
            final rolesNames = requiredRoles
                .map(
                  (r) => Roles.getRoleName(
                    r is int ? r : int.tryParse(r.toString()),
                  ),
                )
                .join(', ');

            final userRoleName = Roles.getRoleName(
              userRole is int ? userRole : int.tryParse(userRole.toString()),
            );

            errorMessage =
                '$message\n\nRôles requis: $rolesNames\nVotre rôle: $userRoleName';
          }

          throw Exception(errorMessage);
        } catch (e) {
          // Si le parsing de l'erreur échoue, utiliser le message par défaut
          throw Exception(
            'Accès refusé (403). Vous n\'avez pas les permissions pour créer un bordereau. Vérifiez vos droits d\'accès avec l\'administrateur.',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Non autorisé (401). Votre session a peut-être expiré. Veuillez vous reconnecter.',
        );
      } else {
        throw Exception(
          'Erreur lors de la création du bordereau: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Bordereau> updateBordereau(Bordereau bordereau) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/bordereaux-update/${bordereau.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bordereau.toJson()),
      );

      if (response.statusCode == 200) {
        return Bordereau.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du bordereau');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bordereau');
    }
  }

  Future<bool> deleteBordereau(int bordereauId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/bordereaux-delete/$bordereauId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitBordereau(int bordereauId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux/$bordereauId/submit'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> approveBordereau(int bordereauId) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/bordereaux-validate/$bordereauId';

      print('🔵 [BORDEREAU_SERVICE] Appel POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🔵 [BORDEREAU_SERVICE] Réponse status: ${response.statusCode}');
      print('🔵 [BORDEREAU_SERVICE] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return true;
        } else {
          print('❌ [BORDEREAU_SERVICE] success == false dans la réponse');
          return false;
        }
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors de la validation';
        throw Exception('Erreur serveur: $message');
      } else {
        print('❌ [BORDEREAU_SERVICE] Status code: ${response.statusCode}');
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur lors de la validation';
        throw Exception('Erreur ${response.statusCode}: $message');
      }
    } catch (e, stackTrace) {
      print('❌ [BORDEREAU_SERVICE] Exception approveBordereau: $e');
      print('❌ [BORDEREAU_SERVICE] Stack trace: $stackTrace');
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  Future<bool> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      final token = storage.read('token');
      // Essayer d'abord la route avec le format /bordereaux/{id}/reject
      String url = '$baseUrl/bordereaux/$bordereauId/reject';
      final body = {'commentaire': commentaire};

      http.Response response;
      try {
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );
      } catch (e) {
        // Si la première route échoue, essayer l'ancienne route
        url = '$baseUrl/bordereaux-reject/$bordereauId';
        response = await http.post(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(body),
        );
      }

      print('🔵 [BORDEREAU_SERVICE] Réponse status: ${response.statusCode}');
      print('🔵 [BORDEREAU_SERVICE] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return true;
        } else {
          print('❌ [BORDEREAU_SERVICE] success == false dans la réponse');
          return false;
        }
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      } else {
        print('❌ [BORDEREAU_SERVICE] Status code: ${response.statusCode}');
        final responseData = json.decode(response.body);
        final message = responseData['message'] ?? 'Erreur lors du rejet';
        throw Exception('Erreur ${response.statusCode}: $message');
      }
    } catch (e, stackTrace) {
      print('❌ [BORDEREAU_SERVICE] Exception rejectBordereau: $e');
      print('❌ [BORDEREAU_SERVICE] Stack trace: $stackTrace');
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  Future<Map<String, dynamic>> getBordereauStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/bordereaux/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
