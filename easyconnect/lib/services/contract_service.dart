import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:easyconnect/Models/contract_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class ContractService extends GetxService {
  static ContractService get to => Get.find();

  // Créer un contrat
  Future<Map<String, dynamic>> createContract({
    required int employeeId,
    required String contractType,
    required String position,
    required String department,
    required String jobTitle,
    required String jobDescription,
    required double grossSalary,
    required double netSalary,
    required String salaryCurrency,
    required String paymentFrequency,
    required DateTime startDate,
    DateTime? endDate,
    int? durationMonths,
    required String workLocation,
    required String workSchedule,
    required int weeklyHours,
    required String probationPeriod,
    String? notes,
    String? contractTemplate,
    List<ContractClause>? clauses,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contracts'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'employee_id': employeeId,
          'contract_type': contractType,
          'position': position,
          'department': department,
          'job_title': jobTitle,
          'job_description': jobDescription,
          'gross_salary': grossSalary,
          'net_salary': netSalary,
          'salary_currency': salaryCurrency,
          'payment_frequency': paymentFrequency,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'duration_months': durationMonths,
          'work_location': workLocation,
          'work_schedule': workSchedule,
          'weekly_hours': weeklyHours,
          'probation_period': probationPeriod,
          'notes': notes,
          'contract_template': contractTemplate,
          'clauses': clauses?.map((c) => c.toJson()).toList(),
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la création du contrat: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.createContract: $e');
      rethrow;
    }
  }

  // Récupérer tous les contrats
  Future<List<Contract>> getAllContracts({
    String? status,
    String? contractType,
    String? department,
    int? employeeId,
  }) async {
    try {
      String url = '$baseUrl/contracts';
      List<String> params = [];

      if (status != null) {
        params.add('status=$status');
      }
      if (contractType != null) {
        params.add('contract_type=$contractType');
      }
      if (department != null) {
        params.add('department=$department');
      }
      if (employeeId != null) {
        params.add('employee_id=$employeeId');
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
            .map((json) => Contract.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des contrats: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getAllContracts: $e');
      rethrow;
    }
  }

  // Récupérer un contrat par ID
  Future<Contract> getContract(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Contract.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération du contrat: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getContract: $e');
      rethrow;
    }
  }

  // Soumettre un contrat pour approbation
  Future<Map<String, dynamic>> submitContract(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contracts/$id/submit'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la soumission: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur ContractService.submitContract: $e');
      rethrow;
    }
  }

  // Approuver un contrat
  Future<Map<String, dynamic>> approveContract(int id, {String? notes}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contracts/$id/approve'),
        headers: ApiService.headers(),
        body: jsonEncode({'notes': notes}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'approbation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.approveContract: $e');
      rethrow;
    }
  }

  // Rejeter un contrat
  Future<Map<String, dynamic>> rejectContract(
    int id, {
    required String reason,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contracts/$id/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'rejection_reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du rejet: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur ContractService.rejectContract: $e');
      rethrow;
    }
  }

  // Mettre à jour un contrat
  Future<Map<String, dynamic>> updateContract({
    required int id,
    String? contractType,
    String? position,
    String? department,
    String? jobTitle,
    String? jobDescription,
    double? grossSalary,
    double? netSalary,
    String? salaryCurrency,
    String? paymentFrequency,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMonths,
    String? workLocation,
    String? workSchedule,
    int? weeklyHours,
    String? probationPeriod,
    String? notes,
    List<ContractClause>? clauses,
  }) async {
    try {
      Map<String, dynamic> body = {};

      if (contractType != null) body['contract_type'] = contractType;
      if (position != null) body['position'] = position;
      if (department != null) body['department'] = department;
      if (jobTitle != null) body['job_title'] = jobTitle;
      if (jobDescription != null) body['job_description'] = jobDescription;
      if (grossSalary != null) body['gross_salary'] = grossSalary;
      if (netSalary != null) body['net_salary'] = netSalary;
      if (salaryCurrency != null) body['salary_currency'] = salaryCurrency;
      if (paymentFrequency != null)
        body['payment_frequency'] = paymentFrequency;
      if (startDate != null) body['start_date'] = startDate.toIso8601String();
      if (endDate != null) body['end_date'] = endDate.toIso8601String();
      if (durationMonths != null) body['duration_months'] = durationMonths;
      if (workLocation != null) body['work_location'] = workLocation;
      if (workSchedule != null) body['work_schedule'] = workSchedule;
      if (weeklyHours != null) body['weekly_hours'] = weeklyHours;
      if (probationPeriod != null) body['probation_period'] = probationPeriod;
      if (notes != null) body['notes'] = notes;
      if (clauses != null)
        body['clauses'] = clauses.map((c) => c.toJson()).toList();

      final response = await http.put(
        Uri.parse('$baseUrl/contracts/$id'),
        headers: ApiService.headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la mise à jour: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.updateContract: $e');
      rethrow;
    }
  }

  // Résilier un contrat
  Future<Map<String, dynamic>> terminateContract({
    required int id,
    required String reason,
    required DateTime terminationDate,
    String? notes,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contracts/$id/terminate'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'termination_reason': reason,
          'termination_date': terminationDate.toIso8601String(),
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la résiliation: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.terminateContract: $e');
      rethrow;
    }
  }

  // Annuler un contrat
  Future<Map<String, dynamic>> cancelContract(int id, {String? reason}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contracts/$id/cancel'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de l\'annulation: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur ContractService.cancelContract: $e');
      rethrow;
    }
  }

  // Supprimer un contrat
  Future<Map<String, dynamic>> deleteContract(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contracts/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de la suppression: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.deleteContract: $e');
      rethrow;
    }
  }

  // Récupérer les clauses d'un contrat
  Future<List<ContractClause>> getContractClauses(int contractId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/$contractId/clauses'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => ContractClause.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des clauses: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getContractClauses: $e');
      rethrow;
    }
  }

  // Ajouter une clause à un contrat
  Future<Map<String, dynamic>> addContractClause({
    required int contractId,
    required String title,
    required String content,
    required String type,
    required bool isMandatory,
    int? order,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contracts/$contractId/clauses'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'title': title,
          'content': content,
          'type': type,
          'is_mandatory': isMandatory,
          'order': order,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la clause: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.addContractClause: $e');
      rethrow;
    }
  }

  // Récupérer les pièces jointes d'un contrat
  Future<List<ContractAttachment>> getContractAttachments(
    int contractId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/$contractId/attachments'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => ContractAttachment.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des pièces jointes: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getContractAttachments: $e');
      rethrow;
    }
  }

  // Ajouter une pièce jointe à un contrat
  Future<Map<String, dynamic>> addContractAttachment({
    required int contractId,
    required String fileName,
    required String filePath,
    required String fileType,
    required int fileSize,
    required String attachmentType,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contracts/$contractId/attachments'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'file_name': fileName,
          'file_path': filePath,
          'file_type': fileType,
          'file_size': fileSize,
          'attachment_type': attachmentType,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Erreur lors de l\'ajout de la pièce jointe: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.addContractAttachment: $e');
      rethrow;
    }
  }

  // Récupérer les modèles de contrat
  Future<List<ContractTemplate>> getContractTemplates({
    String? contractType,
    String? department,
  }) async {
    try {
      String url = '$baseUrl/contract-templates';
      List<String> params = [];

      if (contractType != null) {
        params.add('contract_type=$contractType');
      }
      if (department != null) {
        params.add('department=$department');
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
            .map((json) => ContractTemplate.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des modèles: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getContractTemplates: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques des contrats
  Future<ContractStats> getContractStats({
    DateTime? startDate,
    DateTime? endDate,
    String? department,
    String? contractType,
  }) async {
    try {
      String url = '$baseUrl/contract-stats';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (department != null) {
        params.add('department=$department');
      }
      if (contractType != null) {
        params.add('contract_type=$contractType');
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
        return ContractStats.fromJson(data['data']);
      } else {
        throw Exception(
          'Erreur lors de la récupération des statistiques: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getContractStats: $e');
      rethrow;
    }
  }

  // Récupérer les contrats expirant bientôt
  Future<List<Contract>> getExpiringContracts({int daysAhead = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/expiring?days_ahead=$daysAhead'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Contract.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Erreur lors de la récupération des contrats expirants: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Erreur ContractService.getExpiringContracts: $e');
      rethrow;
    }
  }

  // Récupérer les employés disponibles pour un nouveau contrat
  Future<List<Map<String, dynamic>>> getAvailableEmployees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employees/available-for-contract'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        // Retourner des employés par défaut en cas d'erreur
        return [
          {
            'id': 1,
            'name': 'Jean Dupont',
            'email': 'jean.dupont@example.com',
            'position': 'Développeur',
          },
          {
            'id': 2,
            'name': 'Marie Martin',
            'email': 'marie.martin@example.com',
            'position': 'Designer',
          },
          {
            'id': 3,
            'name': 'Pierre Durand',
            'email': 'pierre.durand@example.com',
            'position': 'Manager',
          },
        ];
      }
    } catch (e) {
      print('Erreur ContractService.getAvailableEmployees: $e');
      return [
        {
          'id': 1,
          'name': 'Jean Dupont',
          'email': 'jean.dupont@example.com',
          'position': 'Développeur',
        },
        {
          'id': 2,
          'name': 'Marie Martin',
          'email': 'marie.martin@example.com',
          'position': 'Designer',
        },
        {
          'id': 3,
          'name': 'Pierre Durand',
          'email': 'pierre.durand@example.com',
          'position': 'Manager',
        },
      ];
    }
  }

  // Générer un numéro de contrat
  Future<String> generateContractNumber() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contracts/generate-number'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['contract_number'];
      } else {
        // Générer un numéro par défaut
        final now = DateTime.now();
        return 'CTR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
      }
    } catch (e) {
      print('Erreur ContractService.generateContractNumber: $e');
      final now = DateTime.now();
      return 'CTR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}';
    }
  }
}
