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
  bool _imagesLoaded = false;

  // Charger les images depuis les assets
  Future<void> _loadImages({bool forceReload = false}) async {
    // Si les images sont déjà chargées et qu'on ne force pas le rechargement, ne pas les recharger
    if (!forceReload &&
        _imagesLoaded &&
        _logoImage != null &&
        _signatureImage != null) {
      return;
    }

    // Si on force le rechargement ou si les images ne sont pas chargées, réinitialiser le cache
    if (forceReload || _logoImage == null || _signatureImage == null) {
      _logoImage = null;
      _signatureImage = null;
      _imagesLoaded = false;
    }

    try {
      // Limite de taille raisonnable pour les images (500KB devrait être suffisant pour la plupart des logos)
      const maxImageSize = 500 * 1024; // 500 KB

      // Charger le logo de l'entreprise (pour l'en-tête)
      try {
        final logoBytes = await rootBundle.load(
          'assets/images/logo_top_left.png',
        );
        final logoUint8List = logoBytes.buffer.asUint8List();

        // Vérifier la taille du logo (avertir si trop grand mais charger quand même)
        if (logoUint8List.length > maxImageSize) {
          print(
            '⚠️ Logo volumineux (${(logoUint8List.length / 1024).toStringAsFixed(1)} KB), chargement quand même',
          );
        }

        // Toujours charger le logo, même s'il est un peu volumineux
        _logoImage = pw.MemoryImage(logoUint8List);
        print(
          '✅ Logo chargé avec succès (${(logoUint8List.length / 1024).toStringAsFixed(1)} KB)',
        );
      } catch (e) {
        // Si le logo ne peut pas être chargé, continuer sans
        print('⚠️ Impossible de charger le logo: $e');
        _logoImage = null;
      }

      // Charger l'image de signature et coordonnées (pour le footer)
      try {
        final signatureBytes = await rootBundle.load(
          'assets/images/logo_bottom_right.jpg',
        );
        final signatureUint8List = signatureBytes.buffer.asUint8List();

        // Vérifier la taille de la signature (avertir si trop grande mais charger quand même)
        if (signatureUint8List.length > maxImageSize) {
          print(
            '⚠️ Signature volumineuse (${(signatureUint8List.length / 1024).toStringAsFixed(1)} KB), chargement quand même',
          );
        }

        // Toujours charger la signature, même si elle est un peu volumineuse
        _signatureImage = pw.MemoryImage(signatureUint8List);
        print(
          '✅ Signature chargée avec succès (${(signatureUint8List.length / 1024).toStringAsFixed(1)} KB)',
        );
      } catch (e) {
        // Si la signature ne peut pas être chargée, continuer sans
        print('⚠️ Impossible de charger la signature: $e');
        _signatureImage = null;
      }

      _imagesLoaded = true;
    } catch (e) {
      // Si les images ne sont pas trouvées, on continue sans elles
      print('⚠️ Attention: Impossible de charger les images pour les PDF: $e');
      print('⚠️ Assurez-vous que les fichiers existent dans assets/images/');
      _logoImage = null;
      _signatureImage = null;
      _imagesLoaded = true; // Marquer comme chargé pour éviter de réessayer
    }
  }

  // Générer un PDF de devis
  Future<void> generateDevisPdf({
    required Map<String, dynamic> devis,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('DEVIS', (devis['reference'] ?? 'N/A').toString()),
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

      final reference = devis['reference']?.toString() ?? 'N/A';
      await _saveAndOpenPdf(pdf, 'devis_${reference}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF devis: $e');
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de bordereau
  Future<void> generateBordereauPdf({
    required Map<String, dynamic> bordereau,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('BORDEREAU', (bordereau['reference'] ?? 'N/A').toString()),
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

      await _saveAndOpenPdf(pdf, 'bordereau_${bordereau['reference'] ?? 'N/A'}.pdf');
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF bordereau: $e');
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de bon de commande
  Future<void> generateBonCommandePdf({
    required Map<String, dynamic> bonCommande,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> fournisseur,
    Map<String, dynamic>? client, // Optionnel pour les bons de commande entreprise
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('BON DE COMMANDE', bonCommande['reference'] ?? 'N/A'),
                pw.SizedBox(height: 20),
                // Utiliser _buildClientInfo si c'est un client, sinon _buildSupplierInfo
                client != null
                    ? _buildClientInfo(client)
                    : _buildSupplierInfo(fournisseur),
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

      final reference = bonCommande['reference']?.toString() ?? 'N/A';
      await _saveAndOpenPdf(
        pdf,
        'bon_commande_${reference}.pdf',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la génération du PDF bon de commande: $e',
      );
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de facture
  Future<void> generateFacturePdf({
    required Map<String, dynamic> facture,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> client,
    required Map<String, dynamic> commercial,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

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
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
    }
  }

  // Générer un PDF de paiement
  Future<void> generatePaiementPdf({
    required Map<String, dynamic> paiement,
    required Map<String, dynamic> facture,
    required Map<String, dynamic> client,
  }) async {
    pw.Document? pdf;
    try {
      await _loadImages();
      pdf = pw.Document();

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
    } finally {
      // Libérer la mémoire du document PDF
      pdf = null;
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
                  width: 100, // Augmenté pour meilleure visibilité
                  height: 100, // Augmenté pour meilleure visibilité
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
                'Référence: ${reference.isNotEmpty ? reference : 'N/A'}',
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
          pw.Text('Nom: ${(client['nom'] ?? '')} ${(client['prenom'] ?? '')}'.trim()),
          if (client['nom_entreprise'] != null && client['nom_entreprise'].toString().isNotEmpty)
            pw.Text('Entreprise: ${client['nom_entreprise']}'),
          if (client['email'] != null && client['email'].toString().isNotEmpty)
            pw.Text('Email: ${client['email']}'),
          if (client['contact'] != null && client['contact'].toString().isNotEmpty)
            pw.Text('Contact: ${client['contact']}'),
          if (client['adresse'] != null && client['adresse'].toString().isNotEmpty)
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
          pw.Text('Nom: ${fournisseur['nom'] ?? 'Non spécifié'}'),
          if (fournisseur['email'] != null && fournisseur['email'].toString().isNotEmpty)
            pw.Text('Email: ${fournisseur['email']}'),
          if (fournisseur['contact'] != null && fournisseur['contact'].toString().isNotEmpty)
            pw.Text('Contact: ${fournisseur['contact']}'),
          if (fournisseur['adresse'] != null && fournisseur['adresse'].toString().isNotEmpty)
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
    // Convertir en double de manière sécurisée
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }
    
    final montantHT = parseDouble(document['montant_ht']);
    final tva = parseDouble(document['tva']);
    final tvaPercent = tva > 0 ? tva : 20.0; // Par défaut 20% si null ou 0
    final montantTVA = montantHT * (tvaPercent / 100);
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
              pw.Text('TVA (${tvaPercent.toStringAsFixed(0)}%):'),
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
                _formatPaymentDate(paiement['date_paiement']),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Facture associée: ${facture['reference'] ?? 'N/A'}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Helper pour formater la date de paiement
  String _formatPaymentDate(dynamic dateValue) {
    if (dateValue == null) {
      return 'Non spécifiée';
    }
    
    try {
      DateTime date;
      if (dateValue is DateTime) {
        date = dateValue;
      } else if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else {
        return 'Format invalide';
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Date invalide';
    }
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
          // Espace vide à gauche pour pousser la signature à droite
          pw.Spacer(),
          // Signature en bas à droite
          if (_signatureImage != null)
            pw.Image(
              _signatureImage!,
              width: 150, // Augmenté pour meilleure visibilité
              height: 150, // Augmenté pour meilleure visibilité
              fit: pw.BoxFit.contain,
            ),
        ],
      ),
    );
  }

  // Sauvegarder et ouvrir le PDF (optimisé pour réduire l'utilisation mémoire)
  Future<void> _saveAndOpenPdf(pw.Document pdf, String fileName) async {
    Uint8List? pdfBytes;
    File? file;
    try {
      final output = await getTemporaryDirectory();
      file = File('${output.path}/$fileName');

      // Générer le PDF en mémoire avec compression
      try {
        pdfBytes = await pdf.save();
      } catch (e) {
        // Si erreur de mémoire, lancer une erreur explicite
        if (e.toString().toLowerCase().contains('memory') ||
            e.toString().toLowerCase().contains('out of')) {
          // Réinitialiser les images pour libérer la mémoire
          _logoImage = null;
          _signatureImage = null;
          _imagesLoaded = false;

          throw Exception(
            'Mémoire insuffisante. Veuillez fermer d\'autres applications et réessayer.',
          );
        }

        // Si erreur liée aux images, réinitialiser et continuer sans images
        if (e.toString().toLowerCase().contains('image') ||
            e.toString().toLowerCase().contains('decode')) {
          print('⚠️ Erreur lors du traitement des images: $e');
          // Ne pas relancer l'erreur, continuer sans images
        } else {
          rethrow;
        }
      }

      // Vérifier que pdfBytes n'est pas null
      if (pdfBytes == null) {
        throw Exception('Erreur lors de la génération du PDF: données nulles');
      }

      // Vérifier la taille du PDF (max 50 MB)
      if (pdfBytes.length > 50 * 1024 * 1024) {
        throw Exception(
          'Le PDF généré est trop volumineux (${(pdfBytes.length / 1024 / 1024).toStringAsFixed(1)} MB). Veuillez réduire le nombre d\'éléments.',
        );
      }

      // Écrire le fichier par chunks pour réduire l'utilisation mémoire
      final sink = file.openWrite();
      try {
        // Écrire par chunks de 1 MB
        const chunkSize = 1024 * 1024; // 1 MB
        for (int i = 0; i < pdfBytes.length; i += chunkSize) {
          final end =
              (i + chunkSize < pdfBytes.length)
                  ? i + chunkSize
                  : pdfBytes.length;
          sink.add(pdfBytes.sublist(i, end));
          await sink.flush();
        }
      } finally {
        await sink.close();
      }

      // Libérer la mémoire du PDF immédiatement après sauvegarde
      pdfBytes = null;

      // Attendre un peu pour laisser le système libérer la mémoire
      await Future.delayed(const Duration(milliseconds: 100));

      // Ouvrir le fichier
      final result = await OpenFile.open(file.path);

      // Vérifier le résultat et gérer les erreurs
      if (result.type != ResultType.done) {
        throw Exception(
          'Impossible d\'ouvrir le fichier PDF: ${result.message}',
        );
      }
    } catch (e) {
      // Libérer la mémoire en cas d'erreur
      pdfBytes = null;

      // Nettoyer le fichier partiel si créé
      if (file != null && await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      // Message d'erreur plus explicite
      String errorMessage = 'Erreur lors de la sauvegarde du PDF';
      if (e.toString().toLowerCase().contains('memory') ||
          e.toString().toLowerCase().contains('out of')) {
        errorMessage =
            'Mémoire insuffisante. Veuillez fermer d\'autres applications et réessayer.';
      } else {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      throw Exception(errorMessage);
    } finally {
      // S'assurer que la mémoire est libérée
      pdfBytes = null;
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
