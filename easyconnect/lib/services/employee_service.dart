import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/employee_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class EmployeeService extends GetxService {
  static EmployeeService get to => Get.find();

  // Récupérer tous les employés
  Future<List<Employee>> getEmployees({
    String? search,
    String? department,
    String? position,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      String url = '$baseUrl/employees';
      List<String> params = [];

      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      if (department != null && department.isNotEmpty) {
        params.add('department=$department');
      }
      if (position != null && position.isNotEmpty) {
        params.add('position=$position');
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
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Employee.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des employés: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.getEmployees: $e');
      rethrow;
    }
  }

  // Récupérer un employé par ID
  Future<Employee> getEmployee(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Employee.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.getEmployee: $e');
      rethrow;
    }
  }

  // Créer un nouvel employé
  Future<Map<String, dynamic>> createEmployee({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? profilePicture,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'address': address,
          'birth_date': birthDate?.toIso8601String(),
          'gender': gender,
          'marital_status': maritalStatus,
          'nationality': nationality,
          'id_number': idNumber,
          'social_security_number': socialSecurityNumber,
          'position': position,
          'department': department,
          'manager': manager,
          'hire_date': hireDate?.toIso8601String(),
          'contract_start_date': contractStartDate?.toIso8601String(),
          'contract_end_date': contractEndDate?.toIso8601String(),
          'contract_type': contractType,
          'salary': salary,
          'currency': currency,
          'work_schedule': workSchedule,
          'profile_picture': profilePicture,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.createEmployee: $e');
      rethrow;
    }
  }

  // Mettre à jour un employé
  Future<Map<String, dynamic>> updateEmployee({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? maritalStatus,
    String? nationality,
    String? idNumber,
    String? socialSecurityNumber,
    String? position,
    String? department,
    String? manager,
    DateTime? hireDate,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    String? contractType,
    double? salary,
    String? currency,
    String? workSchedule,
    String? status,
    String? profilePicture,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/employees/$id'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone': phone,
          'address': address,
          'birth_date': birthDate?.toIso8601String(),
          'gender': gender,
          'marital_status': maritalStatus,
          'nationality': nationality,
          'id_number': idNumber,
          'social_security_number': socialSecurityNumber,
          'position': position,
          'department': department,
          'manager': manager,
          'hire_date': hireDate?.toIso8601String(),
          'contract_start_date': contractStartDate?.toIso8601String(),
          'contract_end_date': contractEndDate?.toIso8601String(),
          'contract_type': contractType,
          'salary': salary,
          'currency': currency,
          'work_schedule': workSchedule,
          'status': status,
          'profile_picture': profilePicture,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.updateEmployee: $e');
      rethrow;
    }
  }

  // Supprimer un employé
  Future<Map<String, dynamic>> deleteEmployee(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/employees/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression de l\'employé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.deleteEmployee: $e');
      rethrow;
    }
  }

  // Soumettre un employé pour approbation
  Future<Map<String, dynamic>> submitEmployeeForApproval(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$id/submit'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la soumission: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.submitEmployeeForApproval: $e');
      rethrow;
    }
  }

  // Approuver un employé (pour le patron)
  Future<Map<String, dynamic>> approveEmployee(int id, {String? comments}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$id/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.approveEmployee: $e');
      rethrow;
    }
  }

  // Rejeter un employé (pour le patron)
  Future<Map<String, dynamic>> rejectEmployee(int id, {required String reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$id/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.rejectEmployee: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques des employés
  Future<EmployeeStats> getEmployeeStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees/stats'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EmployeeStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.getEmployeeStats: $e');
      rethrow;
    }
  }

  // Récupérer les départements
  Future<List<String>> getDepartments() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees/departments'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des départements: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.getDepartments: $e');
      rethrow;
    }
  }

  // Récupérer les postes
  Future<List<String>> getPositions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees/positions'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des postes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.getPositions: $e');
      rethrow;
    }
  }

  // Gestion des documents d'employé
  Future<Map<String, dynamic>> addEmployeeDocument({
    required int employeeId,
    required String name,
    required String type,
    String? description,
    String? filePath,
    DateTime? expiryDate,
    bool isRequired = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$employeeId/documents'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'name': name,
          'type': type,
          'description': description,
          'file_path': filePath,
          'expiry_date': expiryDate?.toIso8601String(),
          'is_required': isRequired,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du document: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.addEmployeeDocument: $e');
      rethrow;
    }
  }

  // Gestion des congés d'employé
  Future<Map<String, dynamic>> addEmployeeLeave({
    required int employeeId,
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$employeeId/leaves'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'type': type,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'reason': reason,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.addEmployeeLeave: $e');
      rethrow;
    }
  }

  // Approuver un congé
  Future<Map<String, dynamic>> approveLeave(int leaveId, {String? comments}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leaves/$leaveId/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'comments': comments}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.approveLeave: $e');
      rethrow;
    }
  }

  // Rejeter un congé
  Future<Map<String, dynamic>> rejectLeave(int leaveId, {required String reason}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/leaves/$leaveId/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors du rejet du congé: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.rejectLeave: $e');
      rethrow;
    }
  }

  // Gestion des performances
  Future<Map<String, dynamic>> addEmployeePerformance({
    required int employeeId,
    required String period,
    required double rating,
    String? comments,
    String? goals,
    String? achievements,
    String? areasForImprovement,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employees/$employeeId/performances'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'period': period,
          'rating': rating,
          'comments': comments,
          'goals': goals,
          'achievements': achievements,
          'areas_for_improvement': areasForImprovement,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la performance: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.addEmployeePerformance: $e');
      rethrow;
    }
  }

  // Rechercher des employés
  Future<List<Employee>> searchEmployees(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees/search?q=$query'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Employee.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la recherche: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur EmployeeService.searchEmployees: $e');
      rethrow;
    }
  }
}
