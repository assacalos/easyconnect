import 'package:easyconnect/utils/roles.dart';

class Permission {
  final String code;
  final String description;
  final List<int> allowedRoles;

  const Permission({
    required this.code,
    required this.description,
    required this.allowedRoles,
  });
}

class Permissions {
  // Permissions générales
  static const VIEW_DASHBOARD = Permission(
    code: 'view_dashboard',
    description: 'Accéder au tableau de bord',
    allowedRoles: [
      Roles.ADMIN,
      Roles.PATRON,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.RH,
      Roles.TECHNICIEN,
    ],
  );

  static const MANAGE_SETTINGS = Permission(
    code: 'manage_settings',
    description: 'Gérer les paramètres système',
    allowedRoles: [Roles.ADMIN],
  );

  // Permissions Clients/Commercial
  static const MANAGE_CLIENTS = Permission(
    code: 'manage_clients',
    description: 'Gérer les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const VIEW_CLIENTS = Permission(
    code: 'view_clients',
    description: 'Voir les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const CREATE_CLIENTS = Permission(
    code: 'create_clients',
    description: 'Créer les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const UPDATE_CLIENTS = Permission(
    code: 'update_clients',
    description: 'Mettre à jour les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const DELETE_CLIENTS = Permission(
    code: 'delete_clients',
    description: 'Supprimer les clients',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );

  static const VIEW_SALES = Permission(
    code: 'view_sales',
    description: 'Voir les ventes',
    allowedRoles: [
      Roles.ADMIN,
      Roles.COMMERCIAL,
      Roles.PATRON,
      Roles.COMPTABLE,
    ],
  );

  // Permissions Comptabilité
  /*  static const MANAGE_INVOICES = Permission(
    code: 'manage_invoices',
    description: 'Gérer les factures',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  ); */

  static const VIEW_FINANCES = Permission(
    code: 'view_finances',
    description: 'Voir les données financières',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const MANAGE_EXPENSES = Permission(
    code: 'manage_expenses',
    description: 'Gérer les dépenses',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  );

  // Permissions RH
  static const MANAGE_EMPLOYEES = Permission(
    code: 'manage_employees',
    description: 'Gérer les employés',
    allowedRoles: [Roles.ADMIN, Roles.RH],
  );

  static const MANAGE_LEAVES = Permission(
    code: 'manage_leaves',
    description: 'Gérer les congés',
    allowedRoles: [Roles.ADMIN, Roles.RH, Roles.PATRON],
  );

  static const VIEW_ATTENDANCE = Permission(
    code: 'view_attendance',
    description: 'Voir les présences',
    allowedRoles: [Roles.ADMIN, Roles.RH, Roles.PATRON],
  );

  // Permissions Facturation
  static const MANAGE_INVOICES = Permission(
    code: 'manage_invoices',
    description: 'Gérer les factures',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  );

  static const VIEW_INVOICES = Permission(
    code: 'view_invoices',
    description: 'Voir les factures',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const APPROVE_INVOICES = Permission(
    code: 'approve_invoices',
    description: 'Approuver les factures',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  // Permissions Paiements
  static const MANAGE_PAYMENTS = Permission(
    code: 'manage_payments',
    description: 'Gérer les paiements',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE],
  );

  static const VIEW_PAYMENTS = Permission(
    code: 'view_payments',
    description: 'Voir les paiements',
    allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
  );

  static const APPROVE_PAYMENTS = Permission(
    code: 'approve_payments',
    description: 'Approuver les paiements',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  static const MANAGE_RECRUITMENT = Permission(
    code: 'manage_recruitment',
    description: 'Gérer le recrutement',
    allowedRoles: [Roles.ADMIN, Roles.RH],
  );

  // Permissions Technicien
  static const MANAGE_TICKETS = Permission(
    code: 'manage_tickets',
    description: 'Gérer les tickets',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN],
  );

  static const MANAGE_EQUIPMENT = Permission(
    code: 'manage_equipment',
    description: 'Gérer le matériel',
    allowedRoles: [Roles.ADMIN, Roles.TECHNICIEN],
  );

  // Permissions Patron
  static const APPROVE_DECISIONS = Permission(
    code: 'approve_decisions',
    description: 'Approuver les décisions importantes',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );

  static const VIEW_ANALYTICS = Permission(
    code: 'view_analytics',
    description: 'Voir les analyses globales',
    allowedRoles: [Roles.ADMIN, Roles.PATRON],
  );
  static const VIEW_DEVIS = Permission(
    code: 'view_devis',
    description: 'Voir les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const CREATE_DEVIS = Permission(
    code: 'create_devis',
    description: 'Créer les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const UPDATE_DEVIS = Permission(
    code: 'update_devis',
    description: 'Mettre à jour les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const DELETE_DEVIS = Permission(
    code: 'delete_devis',
    description: 'Supprimer les devis',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  static const VIEW_STATS = Permission(
    code: 'view_stats',
    description: 'Voir les statistiques',
    allowedRoles: [Roles.ADMIN, Roles.COMMERCIAL],
  );
  // Chat et Communication
  static const USE_CHAT = Permission(
    code: 'use_chat',
    description: 'Utiliser le chat interne',
    allowedRoles: [
      Roles.ADMIN,
      Roles.PATRON,
      Roles.COMMERCIAL,
      Roles.COMPTABLE,
      Roles.RH,
      Roles.TECHNICIEN,
    ],
  );

  // Méthodes utilitaires
  static List<Permission> getAllPermissions() {
    return [
      VIEW_DASHBOARD,
      MANAGE_SETTINGS,
      MANAGE_CLIENTS,
      VIEW_CLIENTS,
      CREATE_CLIENTS,
      UPDATE_CLIENTS,
      DELETE_CLIENTS,
      VIEW_SALES,
      MANAGE_INVOICES,
      VIEW_FINANCES,
      MANAGE_EXPENSES,
      MANAGE_EMPLOYEES,
      MANAGE_LEAVES,
      VIEW_ATTENDANCE,
      MANAGE_INVOICES,
      VIEW_INVOICES,
      APPROVE_INVOICES,
      MANAGE_PAYMENTS,
      VIEW_PAYMENTS,
      APPROVE_PAYMENTS,
      MANAGE_RECRUITMENT,
      MANAGE_TICKETS,
      MANAGE_EQUIPMENT,
      APPROVE_DECISIONS,
      VIEW_ANALYTICS,
      USE_CHAT,
    ];
  }

  static List<Permission> getPermissionsForRole(int role) {
    return getAllPermissions()
        .where((permission) => permission.allowedRoles.contains(role))
        .toList();
  }

  static bool hasPermission(int? role, Permission permission) {
    if (role == null) return false;
    return permission.allowedRoles.contains(role);
  }

  static bool hasAnyPermission(int? role, List<Permission> permissions) {
    if (role == null) return false;
    return permissions.any(
      (permission) => permission.allowedRoles.contains(role),
    );
  }

  static bool hasAllPermissions(int? role, List<Permission> permissions) {
    if (role == null) return false;
    return permissions.every(
      (permission) => permission.allowedRoles.contains(role),
    );
  }
}
