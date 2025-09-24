import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class RoleBasedWidget extends StatelessWidget {
  final Widget child;
  final List<int> allowedRoles;
  final Widget? fallback;
  final List<String>? requiredPermissions;

  const RoleBasedWidget({
    Key? key,
    required this.child,
    required this.allowedRoles,
    this.fallback,
    this.requiredPermissions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      final userRole = authController.userAuth.value?.role;
      
      // Vérifier si l'utilisateur a le rôle requis
      bool hasRole = allowedRoles.contains(userRole);
      
      // Vérifier les permissions si spécifiées
      bool hasPermissions = true;
      if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
        final rolePermissions = Roles.getRolePermissions()[userRole] ?? [];
        hasPermissions = requiredPermissions!.every(
          (permission) => rolePermissions.contains(permission)
        );
      }

      if (hasRole && hasPermissions) {
        return child;
      }

      return fallback ?? const SizedBox.shrink();
    });
  }
}
