import 'package:get/get.dart';
import 'package:easyconnect/Models/media_model.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/logger.dart';

/// Service pour récupérer les médias (images et fichiers) de toutes les entités
class MediaService extends GetxService {
  static MediaService get to => Get.find();

  final AttendancePunchService _attendanceService = AttendancePunchService();
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ExpenseService _expenseService = ExpenseService();

  /// Récupérer tous les médias par catégorie
  Future<Map<String, List<MediaItem>>> getAllMedia() async {
    try {
      final Map<String, List<MediaItem>> mediaByCategory = {
        'attendance': [],
        'bon_commande': [],
        'expense': [],
        'salary': [],
        'other': [],
      };

      // Récupérer les médias de chaque catégorie en parallèle
      await Future.wait([
        _loadAttendanceMedia(mediaByCategory),
        _loadBonCommandeMedia(mediaByCategory),
        _loadExpenseMedia(mediaByCategory),
        _loadSalaryMedia(mediaByCategory),
      ]);

      return mediaByCategory;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération des médias: $e',
        tag: 'MEDIA_SERVICE',
      );
      return {
        'attendance': [],
        'bon_commande': [],
        'expense': [],
        'salary': [],
        'other': [],
      };
    }
  }

  /// Charger les médias des pointages
  Future<void> _loadAttendanceMedia(
    Map<String, List<MediaItem>> mediaByCategory,
  ) async {
    try {
      final attendances = await _attendanceService.getAttendances();
      for (var attendance in attendances) {
        if (attendance.photoPath != null && attendance.photoPath!.isNotEmpty) {
          mediaByCategory['attendance']!.add(
            MediaItem(
              id: 'attendance_${attendance.id}',
              url: attendance.photoUrl,
              fileName: 'Pointage_${attendance.id}.jpg',
              fileType: 'image',
              category: 'attendance',
              entityId: attendance.id?.toString(),
              entityType: 'attendance',
              createdAt: attendance.timestamp,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de pointage: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Charger les médias des bons de commande
  Future<void> _loadBonCommandeMedia(
    Map<String, List<MediaItem>> mediaByCategory,
  ) async {
    try {
      final bonCommandes = await _bonCommandeService.getBonCommandes();
      for (var bonCommande in bonCommandes) {
        for (var fichier in bonCommande.fichiers) {
          if (fichier.isNotEmpty) {
            final isImage = _isImageFile(fichier);
            mediaByCategory['bon_commande']!.add(
              MediaItem(
                id: 'bon_commande_${bonCommande.id}_${fichier.hashCode}',
                url: _buildFileUrl(fichier),
                fileName: fichier.split('/').last,
                fileType: isImage ? 'image' : 'document',
                category: 'bon_commande',
                entityId: bonCommande.id?.toString(),
                entityType: 'bon_commande',
                createdAt: DateTime.now(), // TODO: Récupérer la date réelle
              ),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de bon de commande: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Charger les médias des dépenses
  Future<void> _loadExpenseMedia(
    Map<String, List<MediaItem>> mediaByCategory,
  ) async {
    try {
      final expenses = await _expenseService.getExpenses();
      for (var expense in expenses) {
        if (expense.receiptPath != null && expense.receiptPath!.isNotEmpty) {
          final isImage = _isImageFile(expense.receiptPath!);
          mediaByCategory['expense']!.add(
            MediaItem(
              id: 'expense_${expense.id}',
              url: expense.receiptUrl,
              fileName: expense.receiptPath!.split('/').last,
              fileType: isImage ? 'image' : 'document',
              category: 'expense',
              entityId: expense.id?.toString(),
              entityType: 'expense',
              createdAt: expense.createdAt,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de dépense: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Charger les médias des salaires
  Future<void> _loadSalaryMedia(
    Map<String, List<MediaItem>> mediaByCategory,
  ) async {
    try {
      // TODO: Implémenter quand le service de salaire aura une méthode pour récupérer les fichiers
      // Pour l'instant, on laisse vide
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des médias de salaire: $e',
        tag: 'MEDIA_SERVICE',
      );
    }
  }

  /// Vérifier si un fichier est une image
  bool _isImageFile(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Construire l'URL complète d'un fichier
  String _buildFileUrl(String filePath) {
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }

    String baseUrlWithoutApi = AppConfig.baseUrl;
    if (baseUrlWithoutApi.endsWith('/api')) {
      baseUrlWithoutApi = baseUrlWithoutApi.substring(
        0,
        baseUrlWithoutApi.length - 4,
      );
    }

    String cleanPath = filePath;
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    if (cleanPath.contains('storage/')) {
      return '$baseUrlWithoutApi/$cleanPath';
    }

    return '$baseUrlWithoutApi/storage/$cleanPath';
  }
}
