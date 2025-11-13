import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/utils/constant.dart';

class EquipmentService {
  final storage = GetStorage();

  // Récupérer tous les équipements
  Future<List<Equipment>> getEquipments({
    String? status,
    String? category,
    String? condition,
    String? search,
  }) async {
    try {
      final token = storage.read('token');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (condition != null) queryParams['condition'] = condition;
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(
        Uri.parse('$baseUrl/equipment-list$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        // Gérer différents formats de réponse
        List<dynamic> data = [];

        if (decodedBody is List) {
          // Si la réponse est directement une liste
          data = decodedBody;
        } else if (decodedBody is Map) {
          // Si la réponse est un objet Map
          if (decodedBody.containsKey('data')) {
            final dataValue = decodedBody['data'];
            if (dataValue is List) {
              // Si 'data' est une liste
              data = dataValue;
            } else if (dataValue is Map) {
              // Si 'data' est un Map, chercher les équipements dans différentes clés possibles
              final dataMap = dataValue as Map<String, dynamic>;

              // Gérer la pagination Laravel (structure: { "data": { "data": [...], "current_page": 1, ... } })
              if (dataMap.containsKey('data') && dataMap['data'] is List) {
                data = dataMap['data'] as List<dynamic>;
              } else if (dataMap.containsKey('equipments')) {
                final equipmentsList = dataMap['equipments'];
                if (equipmentsList is List) {
                  data = equipmentsList;
                }
              } else if (dataMap.containsKey('equipment')) {
                final equipmentList = dataMap['equipment'];
                if (equipmentList is List) {
                  data = equipmentList;
                }
              } else {
                // Si 'data' est un Map mais ne contient pas de liste, essayer de convertir les valeurs
                // Peut-être que les équipements sont directement dans les valeurs du Map
                data =
                    dataMap.values.whereType<Map<String, dynamic>>().toList();
              }
            }
          } else {
            // Si pas de clé 'data', chercher d'autres clés possibles
            if (decodedBody.containsKey('equipments')) {
              final equipmentsList = decodedBody['equipments'];
              if (equipmentsList is List) {
                data = equipmentsList;
              }
            } else if (decodedBody.containsKey('equipment')) {
              final equipmentList = decodedBody['equipment'];
              if (equipmentList is List) {
                data = equipmentList;
              }
            }
          }
        }

        // Parser les équipements
        final equipments = <Equipment>[];
        for (var item in data) {
          try {
            if (item is Map<String, dynamic>) {
              equipments.add(Equipment.fromJson(item));
            }
          } catch (e) {
            // Ignorer les éléments invalides mais continuer
          }
        }

        return equipments;
      }
      throw Exception(
        'Erreur lors de la récupération des équipements: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des équipements: $e');
    }
  }

  // Récupérer un équipement par ID
  Future<Equipment> getEquipmentById(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipment/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Equipment.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération de l\'équipement: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'équipement: $e');
    }
  }

  // Créer un équipement
  Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/equipment-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(equipment.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decodedBody = json.decode(response.body);

        // Gérer différents formats de réponse
        Map<String, dynamic> equipmentData;
        if (decodedBody is Map && decodedBody.containsKey('data')) {
          final dataValue = decodedBody['data'];
          if (dataValue is Map) {
            equipmentData = dataValue as Map<String, dynamic>;
          } else {
            throw Exception('Format de réponse inattendu pour la création');
          }
        } else {
          throw Exception('Format de réponse inattendu pour la création');
        }

        return Equipment.fromJson(equipmentData);
      }
      throw Exception(
        'Erreur lors de la création de l\'équipement: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'équipement: $e');
    }
  }

  // Mettre à jour un équipement
  Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/equipment-update/${equipment.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(equipment.toJson()),
      );

      if (response.statusCode == 200) {
        return Equipment.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de l\'équipement: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'équipement: $e');
    }
  }

  // Supprimer un équipement
  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/equipment-destroy/$equipmentId'),
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

  // Récupérer les statistiques des équipements
  Future<EquipmentStats> getEquipmentStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipment-statistics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return EquipmentStats.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      // Retourner des données de test en cas d'erreur
      return EquipmentStats(
        totalEquipment: 0,
        activeEquipment: 0,
        inactiveEquipment: 0,
        maintenanceEquipment: 0,
        brokenEquipment: 0,
        retiredEquipment: 0,
        excellentCondition: 0,
        goodCondition: 0,
        fairCondition: 0,
        poorCondition: 0,
        criticalCondition: 0,
        needsMaintenance: 0,
        warrantyExpired: 0,
        warrantyExpiringSoon: 0,
        totalValue: 0.0,
        averageAge: 0.0,
        equipmentByCategory: {},
        equipmentByStatus: {},
        equipmentByCondition: {},
      );
    }
  }

  // Récupérer les catégories d'équipements
  Future<List<EquipmentCategory>> getEquipmentCategories() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipment-categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => EquipmentCategory.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des catégories: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Récupérer les équipements nécessitant une maintenance
  Future<List<Equipment>> getEquipmentsNeedingMaintenance() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipment-needs-maintenance'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des équipements nécessitant une maintenance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des équipements nécessitant une maintenance: $e',
      );
    }
  }

  // Récupérer les équipements avec garantie expirant bientôt
  Future<List<Equipment>> getEquipmentsWithWarrantyExpiringSoon() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipment-warranty-expiring-soon'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirant bientôt: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirant bientôt: $e',
      );
    }
  }

  // Récupérer les équipements avec garantie expirée
  Future<List<Equipment>> getEquipmentsWithExpiredWarranty() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipment-warranty-expired'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirée: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirée: $e',
      );
    }
  }

  // Récupérer l'historique de maintenance d'un équipement
  Future<List<EquipmentMaintenance>> getEquipmentMaintenanceHistory(
    int equipmentId,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipments/$equipmentId/maintenance'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => EquipmentMaintenance.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération de l\'historique de maintenance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération de l\'historique de maintenance: $e',
      );
    }
  }

  // Planifier une maintenance
  Future<EquipmentMaintenance> scheduleMaintenance(
    EquipmentMaintenance maintenance,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse(
          '$baseUrl/equipment/${maintenance.equipmentId}/schedule-maintenance',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(maintenance.toJson()),
      );

      if (response.statusCode == 201) {
        return EquipmentMaintenance.fromJson(
          json.decode(response.body)['data'],
        );
      }
      throw Exception(
        'Erreur lors de la planification de la maintenance: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la planification de la maintenance: $e');
    }
  }

  // Mettre à jour le statut d'un équipement
  Future<bool> updateEquipmentStatus(int equipmentId, String status) async {
    try {
      final token = storage.read('token');

      final response = await http.patch(
        Uri.parse('$baseUrl/equipments/$equipmentId/status'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour l'état d'un équipement
  Future<bool> updateEquipmentCondition(
    int equipmentId,
    String condition,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.patch(
        Uri.parse('$baseUrl/equipments/$equipmentId/condition'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'condition': condition}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Assigner un équipement à un utilisateur
  Future<bool> assignEquipment(int equipmentId, String assignedTo) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/equipment/$equipmentId/assign'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'assigned_to': assignedTo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Retourner un équipement (désassigner)
  Future<bool> returnEquipment(int equipmentId) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/equipment/$equipmentId/return'),
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

  // Désassigner un équipement (alias pour compatibilité)
  Future<bool> unassignEquipment(int equipmentId) async {
    return returnEquipment(equipmentId);
  }

  // Ajouter une pièce jointe
  Future<bool> addAttachment(int equipmentId, String filePath) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/equipments/$equipmentId/attachments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'file_path': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Supprimer une pièce jointe
  Future<bool> removeAttachment(int equipmentId, String filePath) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/equipments/$equipmentId/attachments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'file_path': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Rechercher des équipements
  Future<List<Equipment>> searchEquipments(String query) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipments/search?q=$query'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Equipment.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la recherche d\'équipements: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'équipements: $e');
    }
  }
}
