/// Remplacé par patronReportsProvider (Riverpod). Stub pour compatibilité.
class PatronReportsController {
  static final PatronReportsController _instance = PatronReportsController._();
  static PatronReportsController get to => _instance;
  factory PatronReportsController() => _instance;
  PatronReportsController._();

  DateTime get startDate => DateTime.now().subtract(const Duration(days: 30));
  DateTime get endDate => DateTime.now();
  bool get isLoading => false;
  int get devisCount => 0;
  double get devisTotal => 0.0;
  int get bordereauxCount => 0;
  double get bordereauxTotal => 0.0;
  int get facturesCount => 0;
  double get facturesTotal => 0.0;
  int get paiementsCount => 0;
  double get paiementsTotal => 0.0;
  int get depensesCount => 0;
  double get depensesTotal => 0.0;
  int get salairesCount => 0;
  double get salairesTotal => 0.0;
  double get beneficeNet => 0.0;
  Future<void> loadReports() async {}
  Future<void> updateDateRange(DateTime start, DateTime end) async {}
}
