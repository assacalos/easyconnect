import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/media_model.dart';
import 'package:easyconnect/services/media_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easyconnect/utils/logger.dart';

/// Contrôleur pour gérer les médias (images et fichiers)
class MediaController extends GetxController {
  final MediaService _mediaService = MediaService();
  final CameraService _cameraService = CameraService();

  // Médias par catégorie
  final RxMap<String, List<MediaItem>> mediaByCategory =
      <String, List<MediaItem>>{}.obs;

  // Catégorie sélectionnée
  final RxString selectedCategory = 'all'.obs;

  // État de chargement
  final RxBool isLoading = false.obs;

  // Tous les médias (pour recherche)
  final RxList<MediaItem> allMedia = <MediaItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMedia();
  }

  /// Charger tous les médias
  Future<void> loadMedia({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && isLoading.value) return;

      isLoading.value = true;

      final media = await _mediaService.getAllMedia();
      mediaByCategory.value = media;

      // Construire la liste de tous les médias
      allMedia.value = [
        ...media['attendance'] ?? [],
        ...media['bon_commande'] ?? [],
        ...media['expense'] ?? [],
        ...media['salary'] ?? [],
        ...media['other'] ?? [],
      ];

      isLoading.value = false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias: $e',
        tag: 'MEDIA_CONTROLLER',
      );
      isLoading.value = false;
    }
  }

  /// Obtenir les médias de la catégorie sélectionnée
  List<MediaItem> getFilteredMedia() {
    if (selectedCategory.value == 'all') {
      return allMedia;
    }
    return mediaByCategory[selectedCategory.value] ?? [];
  }

  /// Obtenir le nombre de médias par catégorie
  int getMediaCount(String category) {
    return mediaByCategory[category]?.length ?? 0;
  }

  /// Scanner un document (photo ou fichier)
  Future<void> scanDocument() async {
    try {
      final String? selectionType = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Scanner un document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Get.back(result: 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Sélectionner depuis la galerie'),
                onTap: () => Get.back(result: 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Sélectionner un fichier'),
                onTap: () => Get.back(result: 'file'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null) return;

      File? selectedFile;

      if (selectionType == 'camera') {
        selectedFile = await _cameraService.takePicture();
      } else if (selectionType == 'gallery') {
        selectedFile = await _cameraService.pickImageFromGallery();
      } else if (selectionType == 'file') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          selectedFile = File(result.files.single.path!);
        }
      }

      if (selectedFile != null) {
        // Afficher un dialogue pour choisir la catégorie
        await _showCategorySelectionDialog(selectedFile);
      }
    } catch (e) {
      AppLogger.error('Erreur lors du scan: $e', tag: 'MEDIA_CONTROLLER');
      Get.snackbar(
        'Erreur',
        'Impossible de scanner le document: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Afficher le dialogue de sélection de catégorie
  Future<void> _showCategorySelectionDialog(File file) async {
    final String? category = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Choisir une catégorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: const Text('Pointage'),
              onTap: () => Get.back(result: 'attendance'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.orange),
              title: const Text('Bon de commande'),
              onTap: () => Get.back(result: 'bon_commande'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Dépense'),
              onTap: () => Get.back(result: 'expense'),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.purple,
              ),
              title: const Text('Salaire'),
              onTap: () => Get.back(result: 'salary'),
            ),
            ListTile(
              leading: const Icon(Icons.folder, color: Colors.grey),
              title: const Text('Autre'),
              onTap: () => Get.back(result: 'other'),
            ),
          ],
        ),
      ),
    );

    if (category != null) {
      // TODO: Implémenter l'upload du fichier vers la catégorie sélectionnée
      Get.snackbar(
        'Information',
        'Fonctionnalité d\'upload à implémenter pour la catégorie: $category',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategory.value = category;
  }
}
