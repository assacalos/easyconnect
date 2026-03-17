import 'package:flutter/material.dart';
import 'package:easyconnect/services/export_service.dart';

/// Affiche un dialog pour choisir le format (Excel ou CSV) et exporte les données.
/// [title] : titre du dialog
/// [fileName] : nom de base du fichier (sans extension)
/// [headers] : noms des colonnes
/// [rows] : lignes de données (chaque ligne = liste de valeurs)
Future<void> showExportDialog({
  required BuildContext context,
  required String title,
  required String fileName,
  required List<String> headers,
  required List<List<Object?>> rows,
}) async {
  if (headers.isEmpty || rows.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune donnée à exporter')),
      );
    }
    return;
  }

  final exportService = ExportService();
  final chosen = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisir le format d\'export',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Excel (.xlsx)'),
                    onPressed: () => Navigator.pop(ctx, 'xlsx'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.description),
                    label: const Text('CSV'),
                    onPressed: () => Navigator.pop(ctx, 'csv'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    ),
  );

  if (chosen == null || !context.mounted) return;

  try {
    String path;
    if (chosen == 'xlsx') {
      path = await exportService.exportToExcel(
        fileName: fileName,
        headers: headers,
        rows: rows,
      );
    } else {
      path = await exportService.exportToCsv(
        fileName: fileName,
        headers: headers,
        rows: rows,
      );
    }
    if (context.mounted) {
      await exportService.openFile(path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export réussi: $fileName')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur export: $e')),
      );
    }
  }
}
