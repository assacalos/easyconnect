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
        Uri.parse('$baseUrl/equipments$queryString'),
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
        'Erreur lors de la récupération des équipements: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur EquipmentService.getEquipments: $e');
      throw Exception('Erreur lors de la récupération des équipements: $e');
    }
  }

  // Récupérer un équipement par ID
  Future<Equipment> getEquipmentById(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipments/$id'),
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
      print('Erreur EquipmentService.getEquipmentById: $e');
      throw Exception('Erreur lors de la récupération de l\'équipement: $e');
    }
  }

  // Créer un équipement
  Future<Equipment> createEquipment(Equipment equipment) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/equipments'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(equipment.toJson()),
      );

      if (response.statusCode == 201) {
        return Equipment.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création de l\'équipement: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur EquipmentService.createEquipment: $e');
      throw Exception('Erreur lors de la création de l\'équipement: $e');
    }
  }

  // Mettre à jour un équipement
  Future<Equipment> updateEquipment(Equipment equipment) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/equipments/${equipment.id}'),
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
      print('Erreur EquipmentService.updateEquipment: $e');
      throw Exception('Erreur lors de la mise à jour de l\'équipement: $e');
    }
  }

  // Supprimer un équipement
  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/equipments/$equipmentId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur EquipmentService.deleteEquipment: $e');
      return false;
    }
  }

  // Récupérer les statistiques des équipements
  Future<EquipmentStats> getEquipmentStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipments/stats'),
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
      print('Erreur EquipmentService.getEquipmentStats: $e');
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
      print('Erreur EquipmentService.getEquipmentCategories: $e');
      throw Exception('Erreur lors de la récupération des catégories: $e');
    }
  }

  // Récupérer les équipements nécessitant une maintenance
  Future<List<Equipment>> getEquipmentsNeedingMaintenance() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipments/needing-maintenance'),
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
      print('Erreur EquipmentService.getEquipmentsNeedingMaintenance: $e');
      throw Exception(
        'Erreur lors de la récupération des équipements nécessitant une maintenance: $e',
      );
    }
  }

  // Récupérer les équipements avec garantie expirée
  Future<List<Equipment>> getEquipmentsWithExpiredWarranty() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/equipments/expired-warranty'),
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
      print('Erreur EquipmentService.getEquipmentsWithExpiredWarranty: $e');
      throw Exception(
        'Erreur lors de la récupération des équipements avec garantie expirée: $e',
      );
    }
  }

  // Récupérer l'historique de maintenance d'un équipement
  Future<List<EquipmentMaintenance>> getEquipmentMaintenanceHistory(int equipmentId) async {
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
      print('Erreur EquipmentService.getEquipmentMaintenanceHistory: $e');
      throw Exception(
        'Erreur lors de la récupération de l\'historique de maintenance: $e',
      );
    }
  }

  // Planifier une maintenance
  Future<EquipmentMaintenance> scheduleMaintenance(EquipmentMaintenance maintenance) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/equipments/${maintenance.equipmentId}/maintenance'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(maintenance.toJson()),
      );

      if (response.statusCode == 201) {
        return EquipmentMaintenance.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la planification de la maintenance: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur EquipmentService.scheduleMaintenance: $e');
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
      print('Erreur EquipmentService.updateEquipmentStatus: $e');
      return false;
    }
  }

  // Mettre à jour l'état d'un équipement
  Future<bool> updateEquipmentCondition(int equipmentId, String condition) async {
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
      print('Erreur EquipmentService.updateEquipmentCondition: $e');
      return false;
    }
  }

  // Assigner un équipement à un utilisateur
  Future<bool> assignEquipment(int equipmentId, String assignedTo) async {
    try {
      final token = storage.read('token');

      final response = await http.patch(
        Uri.parse('$baseUrl/equipments/$equipmentId/assign'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'assigned_to': assignedTo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur EquipmentService.assignEquipment: $e');
      return false;
    }
  }

  // Désassigner un équipement
  Future<bool> unassignEquipment(int equipmentId) async {
    try {
      final token = storage.read('token');

      final response = await http.patch(
        Uri.parse('$baseUrl/equipments/$equipmentId/unassign'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur EquipmentService.unassignEquipment: $e');
      return false;
    }
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
      print('Erreur EquipmentService.addAttachment: $e');
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
      print('Erreur EquipmentService.removeAttachment: $e');
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
      print('Erreur EquipmentService.searchEquipments: $e');
      throw Exception('Erreur lors de la recherche d\'équipements: $e');
    }
  }
}
