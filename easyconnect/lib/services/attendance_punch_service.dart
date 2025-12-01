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
    required String type,
    required File photo,
    String? notes,
  }) async {
    try {
      final locationInfo = await _locationService.getLocationInfo();
      if (locationInfo == null) {
        throw Exception('Impossible d\'obtenir la localisation');
      }

      await _cameraService.validateImage(photo);

      final endpoint =
          type == 'check_in'
              ? '/attendances/check-in'
              : '/attendances/check-out';
      final url = '$baseUrl$endpoint';

      final request = http.MultipartRequest('POST', Uri.parse(url));

      final headers = ApiService.headers();
      headers.remove('Content-Type');
      request.headers.addAll(headers);

      request.fields['latitude'] = locationInfo.latitude.toString();
      request.fields['longitude'] = locationInfo.longitude.toString();
      if (locationInfo.address.isNotEmpty) {
        request.fields['address'] = locationInfo.address;
      }
      request.fields['accuracy'] = locationInfo.accuracy.toString();
      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        filename: 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        AttendancePunchModel? attendanceData;
        if (responseData['data'] != null) {
          try {
            attendanceData = AttendancePunchModel.fromJson(
              responseData['data'],
            );
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        } else if (responseData['attendance'] != null) {
          try {
            attendanceData = AttendancePunchModel.fromJson(
              responseData['attendance'],
            );
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        }

        return {
          'success': true,
          'message':
              responseData['message'] ??
              'Pointage enregistré avec succès et soumis pour validation',
          'data': attendanceData,
        };
      } else {
        String errorMessage = 'Erreur lors du pointage';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;

          // Gestion spécifique de l'erreur 403 (Accès refusé)
          if (response.statusCode == 403) {
            final message = errorData['message'] ?? 'Accès refusé';

            // Si le message contient "rôle" ou "role", c'est probablement un problème de permissions
            if (message.toLowerCase().contains('rôle') ||
                message.toLowerCase().contains('role') ||
                message.toLowerCase().contains('accès refusé')) {
              errorMessage =
                  'Accès refusé. Le pointage est autorisé pour tous les employés. '
                  'Si vous êtes RH, vous devriez pouvoir pointer. '
                  'Vérifiez vos permissions avec l\'administrateur.';
            } else {
              errorMessage = message;
            }
          } else if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorList = errors.values.expand((e) => e as List).join(', ');
            errorMessage = errorList.isNotEmpty ? errorList : errorMessage;
          }
        } catch (e) {
          errorMessage = 'Erreur ${response.statusCode}: ${response.body}';
        }

        return {
          'success': false,
          'message': errorMessage,
          'status_code': response.statusCode,
        };
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
      final url = '$baseUrl/attendances/current-status?type=$type';

      http.Response response;
      try {
        response = await http.get(
          Uri.parse(url),
          headers: ApiService.headers(),
        );
      } catch (e) {
        // En cas d'erreur serveur, autoriser le pointage
        return {
          'success': true,
          'can_punch': true,
          'message': 'Vous pouvez pointer maintenant',
        };
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        bool canPunchValue = false;
        String message = '';
        String? currentStatus;

        if (result['can_punch'] != null) {
          canPunchValue = result['can_punch'] ?? false;
          message =
              result['message'] ??
              (canPunchValue
                  ? 'Vous pouvez pointer maintenant'
                  : 'Vous ne pouvez pas pointer maintenant');
        } else if (result['data'] != null) {
          final data = result['data'];

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
            canPunchValue = type == 'check_in';
            message =
                canPunchValue
                    ? 'Vous pouvez pointer votre arrivée'
                    : 'Vous devez d\'abord pointer votre arrivée';
            currentStatus = 'no_attendance';
          } else {
            final status = data['status'] ?? result['status'];
            currentStatus = status?.toString();

            if (status == null) {
              canPunchValue = type == 'check_in';
              message =
                  canPunchValue
                      ? 'Vous pouvez pointer votre arrivée'
                      : 'Vous devez d\'abord pointer votre arrivée';
            } else {
              final statusStr = status.toString();
              final normalizedStatus = statusStr.toLowerCase().trim();

              if (normalizedStatus == 'pending' ||
                  normalizedStatus == 'en_attente' ||
                  normalizedStatus == 'en attente') {
                canPunchValue = false;
                message =
                    'Vous avez un pointage en attente de validation. Veuillez attendre la validation avant de pointer à nouveau.';
              } else if (normalizedStatus == 'rejected' ||
                  normalizedStatus == 'rejeté' ||
                  normalizedStatus == 'rejete') {
                canPunchValue = type == 'check_in';
                message =
                    canPunchValue
                        ? 'Votre dernier pointage a été rejeté. Vous pouvez pointer votre arrivée.'
                        : 'Votre dernier pointage a été rejeté. Vous devez d\'abord pointer votre arrivée.';
              } else if (normalizedStatus == 'approved' ||
                  normalizedStatus == 'approuvé' ||
                  normalizedStatus == 'approuve' ||
                  normalizedStatus == 'valide' ||
                  normalizedStatus == 'validé') {
                final lastType = data['type']?.toString().toLowerCase() ?? '';
                if (lastType == 'check_in' ||
                    lastType == 'arrivée' ||
                    lastType == 'arrivee') {
                  canPunchValue = type == 'check_out';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre départ'
                          : 'Vous avez déjà pointé votre arrivée. Vous pouvez pointer votre départ.';
                } else if (lastType == 'check_out' ||
                    lastType == 'départ' ||
                    lastType == 'depart') {
                  canPunchValue = type == 'check_in';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre arrivée'
                          : 'Vous avez déjà pointé votre départ. Vous pouvez pointer votre arrivée.';
                } else {
                  canPunchValue = type == 'check_in';
                  message =
                      canPunchValue
                          ? 'Vous pouvez pointer votre arrivée'
                          : 'Vous devez d\'abord pointer votre arrivée';
                }
              } else if (normalizedStatus == 'checked_in' ||
                  normalizedStatus == 'checked_out') {
                if (type == 'check_in') {
                  canPunchValue = normalizedStatus != 'checked_in';
                } else if (type == 'check_out') {
                  canPunchValue = normalizedStatus == 'checked_in';
                }
                message =
                    canPunchValue
                        ? 'Vous pouvez pointer maintenant'
                        : 'Vous ne pouvez pas pointer maintenant';
              } else {
                canPunchValue = type == 'check_in';
                message =
                    canPunchValue
                        ? 'Vous pouvez pointer votre arrivée'
                        : 'Vous devez d\'abord pointer votre arrivée';
              }
            }
          }
        } else {
          canPunchValue = type == 'check_in';
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

        // En cas d'erreur serveur, autoriser le pointage pour éviter les blocages
        return {
          'success': true,
          'can_punch': true,
          'message': 'Vous pouvez pointer maintenant',
        };
      }
    } catch (e) {
      // En cas d'erreur, autoriser le pointage pour éviter les blocages
      return {
        'success': true,
        'can_punch': true,
        'message': 'Vous pouvez pointer maintenant',
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

        if (data is List) {
          attendancesData = data;
        } else if (data is Map && data['data'] != null) {
          final dataField = data['data'];

          if (dataField is List) {
            attendancesData = dataField;
          } else if (dataField is Map && dataField['data'] != null) {
            attendancesData =
                dataField['data'] is List
                    ? dataField['data']
                    : [dataField['data']];
          } else if (dataField is Map) {
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
                    return AttendancePunchModel.fromJson(json);
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

  // Approuver un pointage
  Future<Map<String, dynamic>> approveAttendance(int attendanceId) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl/attendances-validate/$attendanceId'),
        headers: ApiService.headers(jsonContent: true),
        body: jsonEncode({'comment': ''}),
      );

      if (response.statusCode == 500 || response.statusCode == 400) {
        response = await http.put(
          Uri.parse('$baseUrl/attendances/$attendanceId'),
          headers: ApiService.headers(jsonContent: true),
          body: jsonEncode({
            'status': 'valide',
            'validated_by': null,
            'validated_at': null,
          }),
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        AttendancePunchModel? updatedAttendance;
        if (data['data'] != null) {
          try {
            updatedAttendance = AttendancePunchModel.fromJson(data['data']);
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Pointage approuvé avec succès',
          'data': updatedAttendance,
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

  // Rejeter un pointage
  Future<Map<String, dynamic>> rejectAttendance(
    int attendanceId,
    String reason,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendances-reject/$attendanceId'),
        headers: ApiService.headers(jsonContent: true),
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        AttendancePunchModel? updatedAttendance;
        if (data['data'] != null) {
          try {
            updatedAttendance = AttendancePunchModel.fromJson(data['data']);
          } catch (e) {
            // Ignorer l'erreur de parsing
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Pointage rejeté avec succès',
          'data': updatedAttendance,
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
}
