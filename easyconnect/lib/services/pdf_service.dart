import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  // Cache pour les images
  pw.MemoryImage? _logoImage;
  pw.MemoryImage? _signatureImage;

  // Charger les images depuis les assets
  Future<void> _loadImages() async {
    try {
      // Charger le logo de l'entreprise (pour l'en-tête)
      final logoBytes = await rootBundle.load(
        'assets/images/logo_top_left.png',
      );
      _logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Charger l'image de signature et coordonnées (pour le footer)
      final signatureBytes = await rootBundle.load(
        'assets/images/logo_bottom_right.jpg',
      );
      _signatureImage = pw.MemoryImage(signatureBytes.buffer.asUint8List());
    } catch (e) {
      // Si les images ne sont pas trouvées, on continue sans elles
      print('Attention: Impossible de charger les images pour les PDF: $e');
      print('Assurez-vous que les fichiers existent dans assets/images/');
    }
  }

  // Générer un PDF de devis
  Future<void> generateDevisPdf({
    required Map<String, dynamic> devis,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    try {
      await _loadImages();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('DEVIS', devis['reference']),
                pw.SizedBox(height: 20),
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
                _buildItemsTable(items),
                pw.SizedBox(height: 20),
                _buildTotals(devis),
                pw.SizedBox(height: 30),
                _buildFooter(commercial),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(pdf, 'devis_${devis['reference']}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF devis: $e');
    }
  }

  // Générer un PDF de bordereau
  Future<void> generateBordereauPdf({
    required Map<String, dynamic> bordereau,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    try {
      await _loadImages();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('BORDEREAU', bordereau['reference']),
                pw.SizedBox(height: 20),
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
                _buildItemsTable(items),
                pw.SizedBox(height: 20),
                _buildTotals(bordereau),
                pw.SizedBox(height: 30),
                _buildFooter(commercial),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(pdf, 'bordereau_${bordereau['reference']}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF bordereau: $e');
    }
  }

  // Générer un PDF de bon de commande
  Future<void> generateBonCommandePdf({
    required Map<String, dynamic> bonCommande,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> fournisseur,
  }) async {
    try {
      await _loadImages();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('BON DE COMMANDE', bonCommande['reference']),
                pw.SizedBox(height: 20),
                _buildSupplierInfo(fournisseur),
                pw.SizedBox(height: 20),
                _buildItemsTable(items),
                pw.SizedBox(height: 20),
                _buildTotals(bonCommande),
                pw.SizedBox(height: 30),
                _buildFooter(null),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(
        pdf,
        'bon_commande_${bonCommande['reference']}.pdf',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la génération du PDF bon de commande: $e',
      );
    }
  }

  // Générer un PDF de facture
  Future<void> generateFacturePdf({
    required Map<String, dynamic> facture,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    try {
      await _loadImages();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('FACTURE', facture['reference']),
                pw.SizedBox(height: 20),
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
                _buildItemsTable(items),
                pw.SizedBox(height: 20),
                _buildTotals(facture),
                pw.SizedBox(height: 30),
                _buildFooter(commercial),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(pdf, 'facture_${facture['reference']}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF facture: $e');
    }
  }

  // Générer un PDF de paiement
  Future<void> generatePaiementPdf({
    required Map<String, dynamic> paiement,
    required Map<String, dynamic> facture,
    required Map<String, dynamic> client,
  }) async {
    try {
      await _loadImages();
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('REÇU DE PAIEMENT', paiement['reference']),
                pw.SizedBox(height: 20),
                _buildClientInfo(client),
                pw.SizedBox(height: 20),
                _buildPaymentInfo(paiement, facture),
                pw.SizedBox(height: 30),
                _buildFooter(null),
              ],
            );
          },
        ),
      );

      await _saveAndOpenPdf(pdf, 'paiement_${paiement['reference']}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF paiement: $e');
    }
  }

  // Construire l'en-tête du document
  pw.Widget _buildHeader(String documentType, String reference) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo de l'entreprise
              if (_logoImage != null) ...[
                pw.Image(
                  _logoImage!,
                  width: 80,
                  height: 80,
                  fit: pw.BoxFit.contain,
                ),
                pw.SizedBox(height: 10),
              ],
              pw.Text(
                documentType,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue600,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Référence: $reference',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Construire les informations client
  pw.Widget _buildClientInfo(Map<String, dynamic> client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS CLIENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Nom: ${client['nom']} ${client['prenom']}'),
          if (client['nom_entreprise'] != null)
            pw.Text('Entreprise: ${client['nom_entreprise']}'),
          if (client['email'] != null) pw.Text('Email: ${client['email']}'),
          if (client['contact'] != null)
            pw.Text('Contact: ${client['contact']}'),
          if (client['adresse'] != null)
            pw.Text('Adresse: ${client['adresse']}'),
        ],
      ),
    );
  }

  // Construire les informations fournisseur
  pw.Widget _buildSupplierInfo(Map<String, dynamic> fournisseur) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS FOURNISSEUR',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Nom: ${fournisseur['nom']}'),
          if (fournisseur['email'] != null)
            pw.Text('Email: ${fournisseur['email']}'),
          if (fournisseur['contact'] != null)
            pw.Text('Contact: ${fournisseur['contact']}'),
          if (fournisseur['adresse'] != null)
            pw.Text('Adresse: ${fournisseur['adresse']}'),
        ],
      ),
    );
  }

  // Construire le tableau des articles
  pw.Widget _buildItemsTable(List<Map<String, dynamic>> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Désignation',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Qté',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Prix U.',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                'Total',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        // Lignes des articles
        ...items.map(
          (item) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(item['designation'] ?? ''),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${item['quantite'] ?? 0}',
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(item['prix_unitaire'] ?? 0)} FCFA',
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(item['montant_total'] ?? 0)} FCFA',
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Construire les totaux
  pw.Widget _buildTotals(Map<String, dynamic> document) {
    final montantHT = document['montant_ht'] ?? 0.0;
    final tva = document['tva'] ?? 20.0;
    final montantTVA = montantHT * (tva / 100);
    final montantTTC = montantHT + montantTVA;

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Sous-total HT:'),
              pw.Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(montantHT)} FCFA',
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TVA ($tva%):'),
              pw.Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(montantTVA)} FCFA',
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              border: pw.Border.all(color: PdfColors.blue300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL TTC:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                  '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(montantTTC)} FCFA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Construire les informations de paiement
  pw.Widget _buildPaymentInfo(
    Map<String, dynamic> paiement,
    Map<String, dynamic> facture,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAILS DU PAIEMENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Montant payé:'),
              pw.Text(
                '${NumberFormat.currency(locale: 'fr_FR', symbol: '').format(paiement['montant'] ?? 0)} FCFA',
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Mode de paiement:'),
              pw.Text(paiement['mode_paiement'] ?? ''),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Date de paiement:'),
              pw.Text(
                DateFormat(
                  'dd/MM/yyyy',
                ).format(DateTime.parse(paiement['date_paiement'])),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Facture associée: ${facture['reference']}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Construire le pied de page
  pw.Widget _buildFooter(Map<String, dynamic>? commercial) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.white),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          // Informations commerciales à gauche
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (commercial != null) ...[
                  pw.Text(
                    'Commercial: ${commercial['nom']} ${commercial['prenom']}',
                  ),
                  if (commercial['email'] != null)
                    pw.Text('Email: ${commercial['email']}'),
                ] else
                  pw.Text(
                    'Merci pour votre confiance !',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
              ],
            ),
          ),
          // Signature en bas à droite
          if (_signatureImage != null)
            pw.Image(
              _signatureImage!,
              width: 150,
              height: 150,
              fit: pw.BoxFit.contain,
            ),
        ],
      ),
    );
  }

  // Sauvegarder et ouvrir le PDF
  Future<void> _saveAndOpenPdf(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Ouvrir le fichier
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du PDF: $e');
    }
  }

  // Partager le PDF
  Future<void> sharePdf(String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');

      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)]);
      }
    } catch (e) {
      throw Exception('Erreur lors du partage du PDF: $e');
    }
  }
}
