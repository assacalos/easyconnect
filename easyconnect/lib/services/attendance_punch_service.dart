import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../Models/attendance_punch_model.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../utils/constant.dart';
import '../services/api_service.dart';

class AttendancePunchService {
  static final AttendancePunchService _instance =
      AttendancePunchService._internal();
  factory AttendancePunchService() => _instance;
  AttendancePunchService._internal();

  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  // Enregistrer un pointage avec photo et géolocalisation
  Future<Map<String, dynamic>> punchAttendance({
    required String type, // 'check_in' ou 'check_out'
    required File photo,
    String? notes,
  }) async {
    try {
      print('🔄 Début du pointage: $type');

      // 1. Obtenir la localisation
      print('📍 Récupération de la localisation...');
      final locationInfo = await _locationService.getLocationInfo();
      if (locationInfo == null) {
        throw Exception('Impossible d\'obtenir la localisation');
      }

      // 2. Valider la photo
      print('📸 Validation de la photo...');
      await _cameraService.validateImage(photo);

      // 3. Préparer les données
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/attendance/punch'),
      );

      // Headers
      request.headers.addAll(ApiService.headers());

      // Champs
      request.fields['type'] = type;
      request.fields['latitude'] = locationInfo.latitude.toString();
      request.fields['longitude'] = locationInfo.longitude.toString();
      request.fields['address'] = locationInfo.address;
      request.fields['accuracy'] = locationInfo.accuracy.toString();
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      // Photo
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          filename: 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      print('📡 Envoi de la requête...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📊 Réponse: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Pointage enregistré avec succès',
          'data': AttendancePunchModel.fromJson(data['data']),
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors du pointage',
        };
      }
    } catch (e) {
      print('❌ Erreur lors du pointage: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Vérifier si l'utilisateur peut pointer
  Future<Map<String, dynamic>> canPunch({String type = 'check_in'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/can-punch?type=$type'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'can_punch': false,
          'message': 'Erreur lors de la vérification',
        };
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification: $e');
      return {'success': false, 'can_punch': false, 'message': 'Erreur: $e'};
    }
  }

  // Obtenir la liste des pointages
  Future<List<AttendancePunchModel>> getAttendances({
    String? status,
    String? type,
    int? userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      String url = '$baseUrl/attendances';
      List<String> params = [];

      if (status != null) params.add('status=$status');
      if (type != null) params.add('type=$type');
      if (userId != null) params.add('user_id=$userId');
      if (dateFrom != null) params.add('date_from=$dateFrom');
      if (dateTo != null) params.add('date_to=$dateTo');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<dynamic> attendancesData;
          if (data['data']['data'] != null) {
            // Pagination
            attendancesData = data['data']['data'];
          } else {
            attendancesData = data['data'];
          }

          return attendancesData
              .map((json) => AttendancePunchModel.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur lors de la récupération des pointages: $e');
      return [];
    }
  }

  // Obtenir les pointages en attente
  Future<List<AttendancePunchModel>> getPendingAttendances() async {
    return await getAttendances(status: 'pending');
  }

  // Approuver un pointage
  Future<Map<String, dynamic>> approveAttendance(int attendanceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendances/$attendanceId/approve'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors de l\'approbation',
        };
      }
    } catch (e) {
      print('❌ Erreur lors de l\'approbation: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Rejeter un pointage
  Future<Map<String, dynamic>> rejectAttendance(
    int attendanceId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendances/$attendanceId/reject'),
        headers: ApiService.headers(),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors du rejet',
        };
      }
    } catch (e) {
      print('❌ Erreur lors du rejet: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Obtenir un pointage spécifique
  Future<AttendancePunchModel?> getAttendance(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendances/$id'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return AttendancePunchModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération du pointage: $e');
      return null;
    }
  }
}
