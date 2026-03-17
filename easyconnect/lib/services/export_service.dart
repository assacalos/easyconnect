import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

/// Génère un fichier CSV ou Excel (xlsx) à partir de données tabulaires et l'ouvre ou le partage.
/// Excel utilise le package 'excel' ; si l'import échoue, seul le CSV est disponible.
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// [headers] : noms des colonnes
  /// [rows] : chaque ligne = liste de valeurs (num, String, etc.) converties en String à l'écriture
  /// Retourne le chemin du fichier créé.
  Future<String> exportToCsv({
    required String fileName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final list = <List<String>>[
      headers,
      ...rows.map((row) => row.map((c) => _cellToString(c)).toList()),
    ];
    final csv = _toCsv(list);
    final dir = await getTemporaryDirectory();
    final name = fileName.endsWith('.csv') ? fileName : '$fileName.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(csv, encoding: utf8);
    return file.path;
  }

  /// Génération CSV simple (RFC 4180 : champs entre guillemets si contiennent , " ou \n)
  static String _toCsv(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      final cells = row.map((cell) {
        final s = cell.replaceAll('"', '""');
        if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
          return '"$s"';
        }
        return s;
      });
      buffer.writeln(cells.join(','));
    }
    return buffer.toString();
  }

  /// Export Excel (xlsx). Nécessite le package 'excel'. Ici on exporte en CSV pour compatibilité.
  Future<String> exportToExcel({
    required String fileName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final baseName = fileName.endsWith('.xlsx') ? fileName.replaceAll('.xlsx', '') : fileName;
    return exportToCsv(fileName: '${baseName}_excel.csv', headers: headers, rows: rows);
  }

  String _cellToString(Object? value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  /// Ouvre le fichier avec l'app par défaut
  Future<void> openFile(String path) async {
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      throw Exception('Impossible d\'ouvrir le fichier: ${result.message}');
    }
  }

  /// Partage le fichier (optionnel)
  Future<void> shareFile(String path) async {
    await Share.shareXFiles([XFile(path)]);
  }
}
