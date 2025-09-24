import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easyconnect/Models/attendance_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/constant.dart';

class AttendanceService extends GetxService {
  static AttendanceService get to => Get.find();
  final ImagePicker _picker = ImagePicker();

  // Vérifier les permissions de géolocalisation
  Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  // Obtenir la position actuelle
  Future<LocationInfo> getCurrentLocation() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Permission de géolocalisation refusée');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Obtenir l'adresse à partir des coordonnées
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address = '${place.street}, ${place.locality}, ${place.country}';
        }
      } catch (e) {
        print('Erreur lors de la récupération de l\'adresse: $e');
      }

      return LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      rethrow;
    }
  }

  // Prendre une photo
  Future<String?> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        // Sauvegarder l'image dans le répertoire de l'application
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String fileName = 'attendance_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String filePath = '${appDir.path}/$fileName';
        
        final File imageFile = File(image.path);
        await imageFile.copy(filePath);
        
        return filePath;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      return null;
    }
  }

  // Pointer l'arrivée
  Future<Map<String, dynamic>> checkIn({
    required int userId,
    required String userName,
    required String userRole,
    String? photoPath,
    String? notes,
  }) async {
    try {
      // Obtenir la position actuelle
      LocationInfo location = await getCurrentLocation();

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-in'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'user_id': userId,
          'user_name': userName,
          'user_role': userRole,
          'location': location.toJson(),
          'photo_path': photoPath,
          'notes': notes,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du pointage d\'arrivée: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.checkIn: $e');
      rethrow;
    }
  }

  // Pointer le départ
  Future<Map<String, dynamic>> checkOut({
    required int userId,
    String? notes,
  }) async {
    try {
      // Obtenir la position actuelle
      LocationInfo location = await getCurrentLocation();

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/check-out'),
        headers: ApiService.headers(),
        body: jsonEncode({
          'user_id': userId,
          'location': location.toJson(),
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du pointage de départ: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.checkOut: $e');
      rethrow;
    }
  }

  // Récupérer l'historique de pointage d'un utilisateur
  Future<List<AttendanceModel>> getUserAttendance({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/attendance/user/$userId';
      
      if (startDate != null && endDate != null) {
        url += '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération du pointage: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.getUserAttendance: $e');
      rethrow;
    }
  }

  // Récupérer tous les pointages (pour le patron)
  Future<List<AttendanceModel>> getAllAttendance({
    DateTime? startDate,
    DateTime? endDate,
    String? userRole,
    int? userId,
  }) async {
    try {
      String url = '$baseUrl/attendance';
      List<String> params = [];

      if (startDate != null) {
        params.add('start_date=${startDate.toIso8601String()}');
      }
      if (endDate != null) {
        params.add('end_date=${endDate.toIso8601String()}');
      }
      if (userRole != null) {
        params.add('user_role=$userRole');
      }
      if (userId != null) {
        params.add('user_id=$userId');
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
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Erreur lors de la récupération des pointages: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.getAllAttendance: $e');
      rethrow;
    }
  }

  // Récupérer les statistiques de pointage
  Future<AttendanceStats> getAttendanceStats({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String url = '$baseUrl/attendance/stats/$userId';
      
      if (startDate != null && endDate != null) {
        url += '?start_date=${startDate.toIso8601String()}&end_date=${endDate.toIso8601String()}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AttendanceStats.fromJson(data);
      } else {
        throw Exception('Erreur lors de la récupération des statistiques: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.getAttendanceStats: $e');
      rethrow;
    }
  }

  // Vérifier si l'utilisateur peut pointer
  Future<Map<String, dynamic>> canCheckIn(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/can-check-in/$userId'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la vérification: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.canCheckIn: $e');
      rethrow;
    }
  }

  // Mettre à jour les paramètres de pointage
  Future<Map<String, dynamic>> updateAttendanceSettings({
    required AttendanceSettings settings,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/attendance/settings'),
        headers: ApiService.headers(),
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors de la mise à jour des paramètres: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.updateAttendanceSettings: $e');
      rethrow;
    }
  }

  // Récupérer les paramètres de pointage
  Future<AttendanceSettings> getAttendanceSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/settings'),
        headers: ApiService.headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AttendanceSettings.fromJson(data);
      } else {
        throw Exception('Erreur lors de la récupération des paramètres: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur AttendanceService.getAttendanceSettings: $e');
      rethrow;
    }
  }
}
