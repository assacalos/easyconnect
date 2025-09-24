import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Views/Components/bottom_navigation.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class DashboardWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const DashboardWrapper({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final userRole = authController.userAuth.value?.role;

    return Scaffold(
      body: child,
      bottomNavigationBar: userRole != null && userRole != Roles.PATRON
          ? BottomNavigation(
              currentIndex: currentIndex,
              onTap: (index) => _handleNavigation(index, userRole),
            )
          : null,
    );
  }

  void _handleNavigation(int index, int userRole) {
    switch (userRole) {
      case Roles.COMMERCIAL:
        _handleCommercialNavigation(index);
        break;
      case Roles.COMPTABLE:
        _handleComptableNavigation(index);
        break;
      case Roles.TECHNICIEN:
        _handleTechnicienNavigation(index);
        break;
      case Roles.RH:
        _handleRHNavigation(index);
        break;
      default:
        break;
    }
  }

  void _handleCommercialNavigation(int index) {
    switch (index) {
      case 0:
        Get.toNamed('/commercial');
        break;
      case 1:
        Get.toNamed('/clients-page');
        break;
      case 2:
        Get.toNamed('/devis-page');
        break;
      case 3:
        Get.toNamed('/attendance');
        break;
      case 4:
        Get.toNamed('/reporting');
        break;
    }
  }

  void _handleComptableNavigation(int index) {
    switch (index) {
      case 0:
        Get.toNamed('/comptable');
        break;
      case 1:
        Get.toNamed('/invoices');
        break;
      case 2:
        Get.toNamed('/payments');
        break;
      case 3:
        Get.toNamed('/attendance');
        break;
      case 4:
        Get.toNamed('/reporting');
        break;
    }
  }

  void _handleTechnicienNavigation(int index) {
    switch (index) {
      case 0:
        Get.toNamed('/technicien');
        break;
      case 1:
        Get.toNamed('/tickets');
        break;
      case 2:
        Get.toNamed('/maintenance');
        break;
      case 3:
        Get.toNamed('/attendance');
        break;
      case 4:
        Get.toNamed('/reporting');
        break;
    }
  }

  void _handleRHNavigation(int index) {
    switch (index) {
      case 0:
        Get.toNamed('/rh');
        break;
      case 1:
        Get.toNamed('/employees');
        break;
      case 2:
        Get.toNamed('/leaves');
        break;
      case 3:
        Get.toNamed('/attendance');
        break;
      case 4:
        Get.toNamed('/reporting');
        break;
    }
  }
}
