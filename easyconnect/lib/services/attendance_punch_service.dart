import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
      // 1. Obtenir la localisation
      final locationInfo = await _locationService.getLocationInfo();
      if (locationInfo == null) {
        throw Exception('Impossible d\'obtenir la localisation');
      }

      // 2. Valider la photo
      await _cameraService.validateImage(photo);

      // 3. Utiliser les routes dédiées check-in ou check-out
      final endpoint =
          type == 'check_in'
              ? '/attendances/check-in'
              : '/attendances/check-out';

      // 4. Préparer les données
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Headers (important : ne pas mettre Content-Type pour MultipartRequest, il sera ajouté automatiquement)
      final headers = ApiService.headers();
      // Retirer Content-Type si présent car MultipartRequest le gère automatiquement
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      // Champs (le backend checkIn/checkOut fusionne le type automatiquement)
      request.fields['latitude'] = locationInfo.latitude.toString();
      request.fields['longitude'] = locationInfo.longitude.toString();
      if (locationInfo.address.isNotEmpty) {
        request.fields['address'] = locationInfo.address;
      }
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

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: Le serveur ne répond pas');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        // Vérifier le format de la réponse
        AttendancePunchModel? attendanceData;
        if (responseData['data'] != null) {
          try {
            attendanceData = AttendancePunchModel.fromJson(
              responseData['data'],
            );
          } catch (e) {}
        } else if (responseData['attendance'] != null) {
          try {
            attendanceData = AttendancePunchModel.fromJson(
              responseData['attendance'],
            );
          } catch (e) {}
        }

        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Pointage enregistré avec succès et soumis pour validation',
          'data': attendanceData,
        };
      } else {
        // Gestion détaillée des erreurs
        String errorMessage = 'Erreur lors du pointage';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
          if (errorData['errors'] != null) {
            // Erreurs de validation Laravel
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorList = errors.values.expand((e) => e as List).join(', ');
            errorMessage = errorList.isNotEmpty ? errorList : errorMessage;
          }
        } catch (e) {
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'message':
            'Erreur lors de l\'enregistrement du pointage: ${e.toString()}',
      };
    }
  }

  // Vérifier si l'utilisateur peut pointer (statut actuel)
  Future<Map<String, dynamic>> canPunch({String type = 'check_in'}) async {
    try {
      // Utiliser la route current-status (la route can-punch n'existe pas dans les routes backend)
      final url = '$baseUrl/attendances/current-status?type=$type';

      final response = await http
          .get(Uri.parse(url), headers: ApiService.headers())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: Le serveur ne répond pas');
            },
          );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Le backend canPunch() retourne {'success': true, 'can_punch': bool, 'message': string}
        // Gérer aussi le cas où les données sont dans 'data'
        bool canPunchValue = false;
        String message = '';
        String? currentStatus;

        if (result['can_punch'] != null) {
          // Format direct depuis canPunch()
          canPunchValue = result['can_punch'] ?? false;
          message =
              result['message'] ??
              (canPunchValue
                  ? 'Vous pouvez pointer maintenant'
                  : 'Vous ne pouvez pas pointer maintenant');
        } else if (result['data'] != null) {
          // Format avec wrapper data (fallback)
          final data = result['data'];
          // Si data contient can_punch, l'utiliser
          if (data['can_punch'] != null) {
            canPunchValue = data['can_punch'] ?? false;
            message =
                data['message'] ??
                (canPunchValue
                    ? 'Vous pouvez pointer maintenant'
                    : 'Vous ne pouvez pas pointer maintenant');
          } else if (data is Map &&
              data['user'] == null &&
              data['approver'] == null &&
              data['type'] == null &&
              data['status'] == null) {
            // Cas où il n'y a pas de pointage précédent (user/approver null = pas de pointage)
            // Aucun pointage existant : on peut pointer l'arrivée
            canPunchValue = type == 'check_in';
            message =
                canPunchValue
                    ? 'Vous pouvez pointer votre arrivée'
                    : 'Vous devez d\'abord pointer votre arrivée';
            currentStatus = 'no_attendance';
          } else {
            // Sinon, utiliser currentStatus pour calculer
            final status = data['status'] ?? result['status'];
            currentStatus = status?.toString();
            // Si status est null, c'est qu'il n'y a pas de pointage - permettre check_in
            if (status == null) {
              canPunchValue = type == 'check_in';
              message =
                  canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous devez d\'abord pointer votre arrivée';
            } else {
              // Calculer can_punch basé sur le type et le statut
              if (type == 'check_in') {
                canPunchValue = status != 'checked_in';
              } else if (type == 'check_out') {
                canPunchValue = status == 'checked_in';
              }
              message =
                  canPunchValue
                      ? 'Vous pouvez pointer maintenant'
                      : 'Vous ne pouvez pas pointer maintenant';
            }
          }
        } else {
          // Aucune donnée valide, par défaut permettre si pas de pointage
          canPunchValue =
              type ==
              'check_in'; // Par défaut, on peut toujours pointer l'arrivée
          message = 'Statut non disponible, pointage autorisé';
        }

        return {
          'success': true,
          'can_punch': canPunchValue,
          'message': message,
          'current_status': currentStatus,
        };
      } else {
        String errorMessage = 'Erreur lors de la vérification du statut';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }

        return {'success': false, 'can_punch': false, 'message': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'can_punch': false,
        'message': 'Erreur lors de la vérification: ${e.toString()}',
      };
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

        List<dynamic> attendancesData = [];

        // Gérer différents formats de réponse
        if (data is List) {
          // La réponse est directement une liste
          attendancesData = data;
        } else if (data is Map && data['data'] != null) {
          final dataField = data['data'];

          if (dataField is List) {
            // data['data'] est une liste
            attendancesData = dataField;
          } else if (dataField is Map && dataField['data'] != null) {
            // Pagination Laravel: data.data.data
            attendancesData =
                dataField['data'] is List
                    ? dataField['data']
                    : [dataField['data']];
          } else if (dataField is Map) {
            // data['data'] est un objet unique
            attendancesData = [dataField];
          } else {
            attendancesData = [dataField];
          }
        } else if (data is Map &&
            data['success'] == true &&
            data['data'] != null) {
          if (data['data'] is List) {
            attendancesData = data['data'];
          } else {
            attendancesData = [data['data']];
          }
        }

        final attendances =
            attendancesData
                .map((json) {
                  try {
                    final attendance = AttendancePunchModel.fromJson(json);
                    return attendance;
                  } catch (e) {
                    return null;
                  }
                })
                .where((attendance) => attendance != null)
                .cast<AttendancePunchModel>()
                .toList();
        return attendances;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Obtenir les pointages en attente
  Future<List<AttendancePunchModel>> getPendingAttendances() async {
    return await getAttendances(status: 'pending');
  }

  // Approuver un pointage (utilise POST /attendances/{id}/approve)
  Future<Map<String, dynamic>> approveAttendance(int attendanceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendances/$attendanceId/approve'),
        headers: ApiService.headers(jsonContent: true),
        body: jsonEncode({}), // Le backend n'attend pas de body pour approve
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Pointage approuvé avec succès',
          'data':
              data['data'] != null
                  ? AttendancePunchModel.fromJson(data['data'])
                  : null,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors de l\'approbation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors de l\'approbation: ${e.toString()}',
      };
    }
  }

  // Rejeter un pointage (utilise POST /attendances/{id}/reject avec reason)
  Future<Map<String, dynamic>> rejectAttendance(
    int attendanceId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendances/$attendanceId/reject'),
        headers: ApiService.headers(jsonContent: true),
        body: jsonEncode({
          'reason': reason,
        }), // Le backend attend 'reason' dans le body
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Pointage rejeté avec succès',
          'data':
              data['data'] != null
                  ? AttendancePunchModel.fromJson(data['data'])
                  : null,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Erreur lors du rejet',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur lors du rejet: ${e.toString()}',
      };
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
      return null;
    }
  }
}
