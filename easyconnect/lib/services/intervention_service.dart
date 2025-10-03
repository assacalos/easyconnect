import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/utils/constant.dart';

class InterventionService {
  final storage = GetStorage();

  // Récupérer toutes les interventions
  Future<List<Intervention>> getInterventions({
    String? status,
    String? type,
    String? priority,
    String? search,
  }) async {
    try {
      final token = storage.read('token');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(
        Uri.parse('$baseUrl/interventions$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Intervention.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des interventions: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.getInterventions: $e');
      throw Exception('Erreur lors de la récupération des interventions: $e');
    }
  }

  // Récupérer une intervention par ID
  Future<Intervention> getInterventionById(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/interventions/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Intervention.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération de l\'intervention: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.getInterventionById: $e');
      throw Exception('Erreur lors de la récupération de l\'intervention: $e');
    }
  }

  // Créer une intervention
  Future<Intervention> createIntervention(Intervention intervention) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/interventions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(intervention.toJson()),
      );

      if (response.statusCode == 201) {
        return Intervention.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création de l\'intervention: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.createIntervention: $e');
      throw Exception('Erreur lors de la création de l\'intervention: $e');
    }
  }

  // Mettre à jour une intervention
  Future<Intervention> updateIntervention(Intervention intervention) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/interventions/${intervention.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(intervention.toJson()),
      );

      if (response.statusCode == 200) {
        return Intervention.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de l\'intervention: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.updateIntervention: $e');
      throw Exception('Erreur lors de la mise à jour de l\'intervention: $e');
    }
  }

  // Approuver une intervention
  Future<bool> approveIntervention(int interventionId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/interventions/$interventionId/approve'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.approveIntervention: $e');
      return false;
    }
  }

  // Rejeter une intervention
  Future<bool> rejectIntervention(int interventionId, {required String reason}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/interventions/$interventionId/reject'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.rejectIntervention: $e');
      return false;
    }
  }

  // Démarrer une intervention
  Future<bool> startIntervention(int interventionId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/interventions/$interventionId/start'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.startIntervention: $e');
      return false;
    }
  }

  // Terminer une intervention
  Future<bool> completeIntervention(int interventionId, {
    required String solution,
    String? completionNotes,
    double? actualDuration,
    double? cost,
  }) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/interventions/$interventionId/complete'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'solution': solution,
          'completion_notes': completionNotes,
          'actual_duration': actualDuration,
          'cost': cost,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.completeIntervention: $e');
      return false;
    }
  }

  // Supprimer une intervention
  Future<bool> deleteIntervention(int interventionId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/interventions/$interventionId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.deleteIntervention: $e');
      return false;
    }
  }

  // Récupérer les statistiques des interventions
  Future<InterventionStats> getInterventionStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/interventions/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return InterventionStats.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.getInterventionStats: $e');
      // Retourner des données de test en cas d'erreur
      return InterventionStats(
        totalInterventions: 0,
        pendingInterventions: 0,
        approvedInterventions: 0,
        inProgressInterventions: 0,
        completedInterventions: 0,
        rejectedInterventions: 0,
        externalInterventions: 0,
        onSiteInterventions: 0,
        averageDuration: 0.0,
        totalCost: 0.0,
        interventionsByMonth: {},
        interventionsByPriority: {},
      );
    }
  }

  // Récupérer les interventions en attente
  Future<List<Intervention>> getPendingInterventions() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/interventions/pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Intervention.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des interventions en attente: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.getPendingInterventions: $e');
      throw Exception(
        'Erreur lors de la récupération des interventions en attente: $e',
      );
    }
  }

  // Récupérer les interventions du technicien
  Future<List<Intervention>> getTechnicianInterventions(int technicianId) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/interventions/technician/$technicianId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Intervention.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des interventions du technicien: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur InterventionService.getTechnicianInterventions: $e');
      throw Exception(
        'Erreur lors de la récupération des interventions du technicien: $e',
      );
    }
  }

  // Ajouter une pièce jointe
  Future<bool> addAttachment(int interventionId, String filePath) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/interventions/$interventionId/attachments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'file_path': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.addAttachment: $e');
      return false;
    }
  }

  // Supprimer une pièce jointe
  Future<bool> removeAttachment(int interventionId, String filePath) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/interventions/$interventionId/attachments'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'file_path': filePath}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur InterventionService.removeAttachment: $e');
      return false;
    }
  }
}
