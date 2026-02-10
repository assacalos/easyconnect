import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:easyconnect/Models/task_model.dart';
import 'package:easyconnect/utils/constant.dart';
import 'package:easyconnect/services/api_service.dart';

class TaskService extends GetxService {
  static TaskService get to => Get.find<TaskService>();

  /// Liste des tâches (paginated). Patron/Admin voient tout, les autres uniquement les leurs.
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int perPage = 20,
    int? assignedTo,
    String? status,
  }) async {
    final queryParams = <String>['page=$page', 'per_page=$perPage'];
    if (assignedTo != null) queryParams.add('assigned_to=$assignedTo');
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');
    final url = '$baseUrl/tasks-list?${queryParams.join('&')}';

    final response = await http.get(
      Uri.parse(url),
      headers: ApiService.headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>?)
              ?.map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final pagination = data['pagination'] as Map<String, dynamic>?;
      return {
        'success': true,
        'data': list,
        'pagination': pagination ?? {},
      };
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur chargement des tâches');
  }

  /// Détail d'une tâche
  Future<TaskModel> getTask(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks-show/$id'),
      headers: ApiService.headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskData = data['data'] as Map<String, dynamic>?;
      if (taskData == null) throw Exception('Tâche non trouvée');
      return TaskModel.fromJson(taskData);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur chargement de la tâche');
  }

  /// Créer / assigner une tâche (Patron ou Admin)
  Future<TaskModel> createTask({
    required String titre,
    String? description,
    required int assignedTo,
    String priority = 'medium',
    String? dueDate,
  }) async {
    final body = {
      'titre': titre,
      'description': description,
      'assigned_to': assignedTo,
      'priority': priority,
      if (dueDate != null && dueDate.isNotEmpty) 'due_date': dueDate,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/tasks-create'),
      headers: ApiService.headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskData = data['data'] as Map<String, dynamic>?;
      if (taskData == null) throw Exception('Réponse invalide');
      return TaskModel.fromJson(taskData);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? err['errors']?.toString() ?? 'Erreur création tâche');
  }

  /// Mettre à jour une tâche (Patron/Admin: tous champs; assigné: statut seulement)
  Future<TaskModel> updateTask(
    int id, {
    String? titre,
    String? description,
    int? assignedTo,
    String? status,
    String? priority,
    String? dueDate,
  }) async {
    final body = <String, dynamic>{};
    if (titre != null) body['titre'] = titre;
    if (description != null) body['description'] = description;
    if (assignedTo != null) body['assigned_to'] = assignedTo;
    if (status != null) body['status'] = status;
    if (priority != null) body['priority'] = priority;
    if (dueDate != null) body['due_date'] = dueDate;

    final response = await http.put(
      Uri.parse('$baseUrl/tasks-update/$id'),
      headers: ApiService.headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final taskData = data['data'] as Map<String, dynamic>?;
      if (taskData == null) throw Exception('Réponse invalide');
      return TaskModel.fromJson(taskData);
    }
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? err['errors']?.toString() ?? 'Erreur mise à jour');
  }

  /// Mettre à jour uniquement le statut (pour l'assigné)
  Future<TaskModel> updateTaskStatus(int id, String status) async {
    return updateTask(id, status: status);
  }

  /// Supprimer une tâche (Patron ou Admin)
  Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks-destroy/$id'),
      headers: ApiService.headers(),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['message'] ?? 'Erreur suppression');
    }
  }
}
