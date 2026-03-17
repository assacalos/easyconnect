import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/error_helper.dart';

class JournalController {
  static final JournalController _instance = JournalController._();
  static JournalController get to => _instance;
  factory JournalController() => _instance;

  bool isLoading = false;
  Map<String, dynamic> journalData = <String, dynamic>{};

  int? selectedMonth;
  int? selectedYear;
  String? dateDebut;
  String? dateFin;

  JournalController._() {
    final now = DateTime.now();
    selectedMonth = now.month;
    selectedYear = now.year;
    loadJournal();
  }

  Future<void> loadJournal() async {
    isLoading = true;
    try {
      final res = await ApiService.getJournal(
        mois: selectedMonth,
        annee: selectedYear,
        dateDebut: dateDebut,
        dateFin: dateFin,
      );
      if (res['success'] == true && res['data'] != null) {
        journalData = Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
    } finally {
      isLoading = false;
    }
  }

  void setMonthYear(int month, int year) {
    selectedMonth = month;
    selectedYear = year;
    dateDebut = null;
    dateFin = null;
    loadJournal();
  }

  void setDateRange(String debut, String fin) {
    dateDebut = debut;
    dateFin = fin;
    selectedMonth = null;
    selectedYear = null;
    loadJournal();
  }

  List<dynamic> get lignes => journalData['lignes'] is List ? journalData['lignes'] as List : [];
  double get soldeInitial => (journalData['solde_initial'] is num) ? (journalData['solde_initial'] as num).toDouble() : 0.0;
  double get soldeFinal => (journalData['solde_final'] is num) ? (journalData['solde_final'] as num).toDouble() : 0.0;
  double get totalEntrees => (journalData['total_entrees'] is num) ? (journalData['total_entrees'] as num).toDouble() : 0.0;
  double get totalSorties => (journalData['total_sorties'] is num) ? (journalData['total_sorties'] as num).toDouble() : 0.0;

  Future<bool> createEntry(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.journalCreate(data);
      if (res['success'] == true) {
        await loadJournal();
        return true;
      }
      errorHelperShowSnackbar?.call('Erreur', res['message']?.toString() ?? 'Échec');
      return false;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    }
  }

  Future<bool> updateEntry(int id, Map<String, dynamic> data) async {
    try {
      final res = await ApiService.journalUpdate(id, data);
      if (res['success'] == true) {
        await loadJournal();
        return true;
      }
      errorHelperShowSnackbar?.call('Erreur', res['message']?.toString() ?? 'Échec');
      return false;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    }
  }

  Future<bool> deleteEntry(int id) async {
    try {
      final res = await ApiService.journalDestroy(id);
      if (res['success'] == true) {
        await loadJournal();
        return true;
      }
      errorHelperShowSnackbar?.call('Erreur', res['message']?.toString() ?? 'Échec');
      return false;
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString());
      return false;
    }
  }
}
