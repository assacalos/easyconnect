import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/Models/salary_model.dart';
import 'package:intl/intl.dart';

/// Construit les en-têtes et lignes pour l'export (Excel/CSV) par entité.
class ExportDataBuilder {
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _numberFormat = NumberFormat('#,##0.00', 'fr_FR');

  // --- CLIENTS ---
  static const clientHeaders = [
    'Id', 'Nom', 'Prénom', 'Email', 'Contact', 'Adresse', 'Entreprise',
    'Situation géo', 'N° contribuable', 'Statut', 'Commentaire', 'Créé le',
  ];

  static List<List<Object?>> clientsToRows(List<Client> list) {
    return list.map((c) {
      final status = c.status == 1 ? 'Validé' : (c.status == 2 ? 'Rejeté' : 'En attente');
      return [
        c.id,
        c.nom ?? '',
        c.prenom ?? '',
        c.email ?? '',
        c.contact ?? '',
        c.adresse ?? '',
        c.nomEntreprise ?? '',
        c.situationGeographique ?? '',
        c.numeroContribuable ?? '',
        status,
        c.commentaire ?? '',
        c.createdAt ?? '',
      ];
    }).toList();
  }

  // --- FACTURES ---
  static const invoiceHeaders = [
    'Id', 'N° facture', 'Client', 'Email client', 'Date facture', 'Échéance',
    'Statut', 'HT', 'TVA', 'TTC', 'Devise', 'Créé le',
  ];

  static List<List<Object?>> invoicesToRows(List<InvoiceModel> list) {
    return list.map((i) => [
      i.id,
      i.invoiceNumber,
      i.clientName,
      i.clientEmail,
      _dateFormat.format(i.invoiceDate),
      _dateFormat.format(i.dueDate),
      i.status,
      _numberFormat.format(i.subtotal),
      _numberFormat.format(i.taxAmount),
      _numberFormat.format(i.totalAmount),
      i.currency,
      _dateTimeFormat.format(i.createdAt),
    ]).toList();
  }

  // --- PAIEMENTS ---
  static const paymentHeaders = [
    'Id', 'N° paiement', 'Client', 'Montant', 'Mode', 'Statut', 'Date paiement',
    'Référence', 'Créé le',
  ];

  static List<List<Object?>> paymentsToRows(List<PaymentModel> list) {
    return list.map((p) => [
      p.id,
      p.paymentNumber,
      p.clientName,
      _numberFormat.format(p.amount),
      p.paymentMethod,
      p.status,
      _dateFormat.format(p.paymentDate),
      p.reference ?? '',
      _dateTimeFormat.format(p.createdAt),
    ]).toList();
  }

  // --- DÉPENSES ---
  static const expenseHeaders = [
    'Id', 'Titre', 'Description', 'Montant', 'Catégorie', 'Statut', 'Date dépense',
    'Notes', 'Créé le',
  ];

  static List<List<Object?>> expensesToRows(List<Expense> list) {
    return list.map((e) => [
      e.id,
      e.title,
      e.description,
      _numberFormat.format(e.amount),
      e.category,
      e.status,
      _dateFormat.format(e.expenseDate),
      e.notes ?? '',
      _dateTimeFormat.format(e.createdAt),
    ]).toList();
  }

  // --- SALAIRES ---
  static const salaryHeaders = [
    'Id', 'Employé', 'Email', 'Période', 'Salaire base', 'Primes', 'Déductions',
    'Net', 'Statut', 'Créé le',
  ];

  static List<List<Object?>> salariesToRows(List<Salary> list) {
    return list.map((salary) {
      return [
        salary.id,
        salary.employeeName ?? '',
        salary.employeeEmail ?? '',
        salary.periodText,
        _numberFormat.format(salary.baseSalary),
        _numberFormat.format(salary.bonus),
        _numberFormat.format(salary.deductions),
        _numberFormat.format(salary.netSalary),
        salary.statusText,
        salary.createdAt != null ? _dateTimeFormat.format(salary.createdAt!) : '',
      ];
    }).toList();
  }

  // --- JOURNAL COMPTABLE (lignes) ---
  static const journalHeaders = [
    'Id', 'Date', 'Référence', 'Libellé', 'Catégorie', 'Mode paiement',
    'Entrée', 'Sortie', 'Solde', 'Notes',
  ];

  static List<List<Object?>> journalToRows(List<dynamic> lignes) {
    return lignes.map((line) {
      final map = line is Map ? line as Map<String, dynamic> : <String, dynamic>{};
      final id = map['id'];
      final date = map['date']?.toString() ?? '';
      final ref = map['reference']?.toString() ?? '';
      final libelle = map['libelle']?.toString() ?? '';
      final categorie = map['categorie']?.toString() ?? '';
      final mode = map['mode_paiement']?.toString() ?? map['mode_paiement_libelle']?.toString() ?? '';
      final entree = map['entree'] is num ? (map['entree'] as num).toDouble() : 0.0;
      final sortie = map['sortie'] is num ? (map['sortie'] as num).toDouble() : 0.0;
      final solde = map['solde'] is num ? (map['solde'] as num).toDouble() : 0.0;
      final notes = map['notes']?.toString() ?? '';
      return [id, date, ref, libelle, categorie, mode, _numberFormat.format(entree), _numberFormat.format(sortie), _numberFormat.format(solde), notes];
    }).toList();
  }

  // --- RAPPORTS PATRON (résumé période) ---
  static const patronReportHeaders = [
    'Période début', 'Période fin', 'Devis (nb)', 'Devis (total)', 'Bordereaux (nb)', 'Bordereaux (total)',
    'Factures (nb)', 'Factures (total)', 'Paiements (nb)', 'Paiements (total)',
    'Dépenses (nb)', 'Dépenses (total)', 'Salaires (nb)', 'Salaires (total)', 'Bénéfice net',
    'Encaissements', 'Décaissements', 'Solde trésorerie',
    'Créances 0-30 j', 'Créances 31-60 j', 'Créances 61-90 j', 'Créances >90 j',
  ];

  static List<List<Object?>> patronReportToRows({
    required DateTime startDate,
    required DateTime endDate,
    required int devisCount,
    required double devisTotal,
    required int bordereauxCount,
    required double bordereauxTotal,
    required int facturesCount,
    required double facturesTotal,
    required int paiementsCount,
    required double paiementsTotal,
    required int depensesCount,
    required double depensesTotal,
    required int salairesCount,
    required double salairesTotal,
    required double beneficeNet,
    double encaissements = 0,
    double decaissements = 0,
    double soldeTresorerie = 0,
    double receivables0_30 = 0,
    double receivables31_60 = 0,
    double receivables61_90 = 0,
    double receivablesOver90 = 0,
  }) {
    return [
      [
        _dateFormat.format(startDate),
        _dateFormat.format(endDate),
        devisCount,
        _numberFormat.format(devisTotal),
        bordereauxCount,
        _numberFormat.format(bordereauxTotal),
        facturesCount,
        _numberFormat.format(facturesTotal),
        paiementsCount,
        _numberFormat.format(paiementsTotal),
        depensesCount,
        _numberFormat.format(depensesTotal),
        salairesCount,
        _numberFormat.format(salairesTotal),
        _numberFormat.format(beneficeNet),
        _numberFormat.format(encaissements),
        _numberFormat.format(decaissements),
        _numberFormat.format(soldeTresorerie),
        _numberFormat.format(receivables0_30),
        _numberFormat.format(receivables31_60),
        _numberFormat.format(receivables61_90),
        _numberFormat.format(receivablesOver90),
      ],
    ];
  }
}
