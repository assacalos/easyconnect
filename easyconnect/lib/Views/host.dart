import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Controllers/host_controller.dart';
import 'package:easyconnect/Views/Commercial/client_list_page.dart';
import 'package:easyconnect/Views/Components/bottomBar.dart';
import 'package:easyconnect/Views/Components/sideBar.dart';
import 'package:easyconnect/Views/Users/user_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Host extends StatelessWidget {
  const Host({super.key});

  @override
  Widget build(BuildContext context) {
    final HostController hostController = Get.find();
    final AuthController authController = Get.find();
    return Scaffold(
      appBar: AppBar(foregroundColor: Colors.black, title: Text("EasyConnect")),
      drawer: SidebarWidget(
        customWidgets: [
          UserAccountsDrawerHeader(
            accountName: Text(
              "${authController.userAuth.value?.nom ?? 'Utilisateur'}",
            ),
            accountEmail: Text(
              "${authController.userAuth.value?.email ?? 'Email'}",
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blueGrey.shade900),
            ),
            decoration: BoxDecoration(color: Colors.blueGrey.shade800),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 1, // Admin
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.people_alt_outlined, color: Colors.white),
              title: Text(
                "Gestion des utilisateurs",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 1,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(
                Icons.roller_shades_closed_outlined,
                color: Colors.white,
              ),
              title: Text(
                "Gestion des rôles",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => print("Gestion des rôles"),
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 2, // Commercial
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.people, color: Colors.white),
              title: Text(
                "Gestion des clients",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => ClientsPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 2,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.request_quote, color: Colors.white),
              title: Text(
                "Gestion des proformas",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 2,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(
                Icons.insert_drive_file_outlined,
                color: Colors.white,
              ),
              title: Text(
                "Gestion des bordereaux",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 2,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.book_online_rounded, color: Colors.white),
              title: Text(
                "Gestion des bons de commande",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 3, // Comptable
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.inventory_outlined, color: Colors.white),
              title: Text(
                "Gestion des factures",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 3,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.paid, color: Colors.white),
              title: Text(
                "Gestion des paiements",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 3,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.table_view, color: Colors.white),
              title: Text(
                "Gestion des Taxes & Impôts",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 3,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.fence_outlined, color: Colors.white),
              title: Text(
                "Gestion des fournisseurs",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 4, // RH
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.work, color: Colors.white),
              title: Text(
                "Gestion des employés",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 4,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.paid, color: Colors.white),
              title: Text(
                "Gestion des salaires",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 4,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.receipt, color: Colors.white),
              title: Text(
                "Gestion des recrutements",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 4,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.holiday_village, color: Colors.white),
              title: Text(
                "Gestion des congés",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 5, // Technicien
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.manage_accounts, color: Colors.white),
              title: Text(
                "Gestion des interventions",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 5,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(
                Icons.precision_manufacturing_rounded,
                color: Colors.white,
              ),
              title: Text(
                "Gestion des equipements",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6, // Patron
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.people, color: Colors.white),
              title: Text(
                "Validation Client",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.request_quote, color: Colors.white),
              title: Text(
                "Validation Proforma",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(
                Icons.insert_drive_file_outlined,
                color: Colors.white,
              ),
              title: Text(
                "Validation Bordereau",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.book_online_rounded, color: Colors.white),
              title: Text(
                "Validation Bon de commande",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.inventory_outlined, color: Colors.white),
              title: Text(
                "Validation facture",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.book_online_rounded, color: Colors.white),
              title: Text(
                "Validation Paiements",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.fence_outlined, color: Colors.white),
              title: Text(
                "Validation des fournisseurs",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.paid, color: Colors.white),
              title: Text(
                "Validation des salaires",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.receipt, color: Colors.white),
              title: Text(
                "Validation des recrutements",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.table_view, color: Colors.white),
              title: Text(
                "Validation des Taxes & Impôts",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),
          Visibility(
            visible: authController.userAuth.value?.role == 6,
            replacement: SizedBox.shrink(),
            child: ListTile(
              leading: Icon(Icons.manage_accounts, color: Colors.white),
              title: Text(
                "Validation des interventions",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => UserPage());
              },
            ),
          ),

          ListTile(
            leading: Icon(Icons.present_to_all, color: Colors.white),
            title: Text("Pointage", style: TextStyle(color: Colors.white)),
            onTap: () => print("Pointage"),
          ),
          ListTile(
            leading: Icon(Icons.report, color: Colors.white),
            title: Text("Rapports", style: TextStyle(color: Colors.white)),
            onTap: () => print("Rapports"),
          ),
          ListTile(
            leading: Icon(Icons.note, color: Colors.white),
            title: Text("Bloc Notes", style: TextStyle(color: Colors.white)),
            onTap: () => print("Bloc Notes"),
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text("Parametre", style: TextStyle(color: Colors.white)),
            onTap: () => print("Parametre"),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.white),
            title: Text("Profil", style: TextStyle(color: Colors.white)),
            onTap: () => print("Profil"),
          ),
          Divider(color: Colors.white54),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Déconnexion", style: TextStyle(color: Colors.red)),
            onTap: () {
              authController.logout();
            },
          ),
        ],
      ),

      bottomNavigationBar: BottomBarWidget(
        items: [
          BottomBarItem(icon: Icons.home, label: "Accueil"),
          BottomBarItem(icon: Icons.search, label: "Rechercher"),
          BottomBarItem(icon: Icons.notifications, label: "Notifications"),
          BottomBarItem(icon: Icons.message_rounded, label: "Chat"),
          BottomBarItem(icon: Icons.print, label: "Scanner"),
        ],
      ),
      body: Obx(() {
        switch (hostController.currentIndex.value) {
          case 0:
            return Center(child: Text("Accueil"));
          case 1:
            return Center(child: Text("Rechercher"));
          case 2:
            return Center(child: Text("Notifications"));
          case 3:
            return Center(child: Text("Chat"));
          case 4:
            return Center(child: Text("Scanner"));
          default:
            return Center(child: Text("Accueil"));
        }
      }),
    );
  }
}
