import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  // Vérifier et demander les permissions caméra
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  // Vérifier et demander les permissions de stockage
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status == PermissionStatus.granted;
  }

  // Prendre une photo avec la caméra
  Future<File?> takePicture() async {
    try {
      // Vérifier les permissions
      if (!await requestCameraPermission()) {
        throw Exception('Permission caméra refusée');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Sélectionner une image depuis la galerie
  Future<File?> pickImageFromGallery() async {
    try {
      // Vérifier les permissions
      if (!await requestStoragePermission()) {
        throw Exception('Permission stockage refusée');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Vérifier la taille du fichier
  bool isFileSizeValid(File file, {int maxSizeMB = 2}) {
    final fileSize = file.lengthSync();
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSize <= maxSizeBytes;
  }

  // Vérifier le type de fichier
  bool isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  // Valider une image
  Future<bool> validateImage(File file) async {
    if (!isImageFile(file)) {
      throw Exception(
        'Format de fichier non supporté. Utilisez JPG, JPEG ou PNG.',
      );
    }

    if (!isFileSizeValid(file)) {
      throw Exception('Fichier trop volumineux. Taille maximale: 2MB.');
    }

    return true;
  }

  // Obtenir les métadonnées d'une image
  Future<ImageMetadata> getImageMetadata(File file) async {
    final stat = file.statSync();
    return ImageMetadata(
      path: file.path,
      size: stat.size,
      modified: stat.modified,
      created: stat.changed,
    );
  }
}

class ImageMetadata {
  final String path;
  final int size;
  final DateTime modified;
  final DateTime created;

  ImageMetadata({
    required this.path,
    required this.size,
    required this.modified,
    required this.created,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileName {
    return path.split('/').last;
  }

  String get fileExtension {
    return path.split('.').last.toLowerCase();
  }
}
