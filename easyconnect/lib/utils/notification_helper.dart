import 'package:easyconnect/services/notification_service_enhanced.dart';

/// Helper pour faciliter l'intégration des notifications dans les contrôleurs
class NotificationHelper {
  static final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced();

  /// Notifier la soumission d'une entité
  static Future<void> notifySubmission({
    required String entityType,
    required String entityName,
    required String entityId,
    String? route,
  }) async {
    // Exécution asynchrone non-bloquante
    _notificationService
        .notifyEntitySubmitted(
          entityType: entityType,
          entityName: entityName,
          entityId: entityId,
          route: route,
        )
        .catchError((e) {
          // Erreur silencieuse pour ne pas bloquer l'application
        });
  }

  /// Notifier la validation d'une entité
  static Future<void> notifyValidation({
    required String entityType,
    required String entityName,
    required String entityId,
    String? route,
  }) async {
    // Exécution asynchrone non-bloquante
    _notificationService
        .notifyEntityValidated(
          entityType: entityType,
          entityName: entityName,
          entityId: entityId,
          route: route,
        )
        .catchError((e) {
          // Erreur silencieuse pour ne pas bloquer l'application
        });
  }

  /// Notifier le rejet d'une entité
  static Future<void> notifyRejection({
    required String entityType,
    required String entityName,
    required String entityId,
    String? reason,
    String? route,
  }) async {
    // Exécution asynchrone non-bloquante
    _notificationService
        .notifyEntityRejected(
          entityType: entityType,
          entityName: entityName,
          entityId: entityId,
          reason: reason,
          route: route,
        )
        .catchError((e) {
          // Erreur silencieuse pour ne pas bloquer l'application
        });
  }

  /// Obtenir le nom d'entité formaté
  static String getEntityDisplayName(String entityType, dynamic entity) {
    // Helper pour obtenir une valeur depuis un Map ou un objet
    dynamic getValue(dynamic obj, String key, [String? altKey]) {
      if (obj == null) return null;

      // Si c'est un Map, accéder directement
      if (obj is Map) {
        return obj[key] ?? (altKey != null ? obj[altKey] : null);
      }

      // Si ce n'est pas un Map, essayer d'accéder comme propriété d'objet
      // Note: En Dart, on ne peut pas accéder dynamiquement aux propriétés
      // Donc on retourne null si ce n'est pas un Map
      return null;
    }

    // Helper pour obtenir l'ID
    dynamic getId(dynamic obj) {
      if (obj == null) return null;

      if (obj is Map) {
        return obj['id'];
      }

      try {
        // Si c'est un objet avec une propriété id
        return obj.id;
      } catch (e) {
        return null;
      }
    }

    final id = getId(entity) ?? '?';

    switch (entityType.toLowerCase()) {
      case 'invoice':
      case 'facture':
        final invoiceNumber = getValue(
          entity,
          'invoice_number',
          'invoiceNumber',
        );
        return 'Facture #${invoiceNumber ?? id}';
      case 'devis':
        final reference = getValue(entity, 'reference');
        return 'Devis ${reference ?? '#$id'}';
      case 'bordereau':
        final reference = getValue(entity, 'reference');
        return 'Bordereau ${reference ?? '#$id'}';
      case 'bon_commande':
      case 'bon de commande':
        return 'Bon de commande #$id';
      case 'payment':
      case 'paiement':
        final paymentNumber = getValue(
          entity,
          'payment_number',
          'paymentNumber',
        );
        return 'Paiement ${paymentNumber ?? '#$id'}';
      case 'expense':
      case 'depense':
        final title = getValue(entity, 'title');
        return 'Dépense ${title ?? '#$id'}';
      case 'salary':
      case 'salaire':
        final employeeName = getValue(entity, 'employee_name', 'employeeName');
        return 'Salaire ${employeeName ?? '#$id'}';
      case 'stock':
        final name = getValue(entity, 'name');
        return 'Stock ${name ?? '#$id'}';
      case 'tax':
      case 'taxe':
        final name = getValue(entity, 'name');
        return 'Taxe ${name ?? '#$id'}';
      case 'intervention':
        return 'Intervention #$id';
      case 'client':
        if (entity is Map) {
          final nomEntreprise = getValue(
            entity,
            'nom_entreprise',
            'nomEntreprise',
          );
          if (nomEntreprise != null && nomEntreprise.toString().isNotEmpty) {
            return nomEntreprise.toString();
          }
          final prenom = getValue(entity, 'prenom');
          final nom = getValue(entity, 'nom');
          return '${prenom ?? ''} ${nom ?? ''}'.trim();
        }
        try {
          return entity.nomEntreprise?.isNotEmpty == true
              ? entity.nomEntreprise!
              : '${entity.prenom ?? ''} ${entity.nom ?? ''}'.trim();
        } catch (e) {
          return 'Client #$id';
        }
      case 'supplier':
      case 'fournisseur':
        final nom = getValue(entity, 'nom', 'name');
        return nom ?? 'Fournisseur #$id';
      default:
        return '$entityType #$id';
    }
  }

  /// Obtenir la route selon le type d'entité
  static String? getEntityRoute(String entityType, String entityId) {
    switch (entityType.toLowerCase()) {
      case 'invoice':
      case 'facture':
        return '/invoices/$entityId';
      case 'devis':
        return '/devis/$entityId';
      case 'bordereau':
        return '/bordereaux/$entityId';
      case 'bon_commande':
      case 'bon de commande':
        return '/bon-commandes/$entityId';
      case 'payment':
      case 'paiement':
        return '/payments/detail';
      case 'expense':
      case 'depense':
        return null; // Route à définir
      case 'salary':
      case 'salaire':
        return null; // Route à définir
      case 'stock':
        return '/stocks/$entityId';
      case 'tax':
      case 'taxe':
        return '/taxes/$entityId';
      case 'intervention':
        return '/interventions/$entityId';
      case 'equipment':
      case 'equipement':
        return '/equipments/$entityId';
      case 'recruitment':
      case 'recrutement':
        return '/recruitments/$entityId';
      case 'contract':
      case 'contrat':
        return '/contracts/$entityId';
      case 'leave':
      case 'conge':
        return '/leaves/$entityId';
      case 'client':
        return '/clients/$entityId';
      default:
        return null;
    }
  }
}
