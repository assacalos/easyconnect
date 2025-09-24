import 'package:easyconnect/Controllers/userController.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/Views/Users/dashboard_section.dart';
import 'package:easyconnect/Views/Users/log_section.dart';
import 'package:easyconnect/Views/Users/security_section.dart';
import 'package:easyconnect/Views/Users/setting_section.dart';
import 'package:easyconnect/Views/Users/user_form.dart';
import 'package:easyconnect/Views/Users/user_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Sections enum
enum DashboardSection { dashboard, users, security, settings, logs }

class AdminDashboardFull extends StatefulWidget {
  @override
  _AdminDashboardFullState createState() => _AdminDashboardFullState();
}

class _AdminDashboardFullState extends State<AdminDashboardFull> {
  final UserController userController = Get.put(UserController());
  final AuthController authController = Get.find<AuthController>();
  final Rx<DashboardSection> currentSection = DashboardSection.dashboard.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: Colors.blueGrey.shade900,
          child: Column(
            children: [
              SizedBox(height: 50),
              Text(
                "EasyConnect Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),
              buildSidebarButton(
                "Tableau de bord",
                Icons.dashboard,
                section: DashboardSection.dashboard,
              ),
              buildSidebarButton(
                "Gestion des utilisateurs",
                Icons.people,
                section: DashboardSection.users,
              ),
              buildSidebarButton(
                "Sécurité",
                Icons.security,
                section: DashboardSection.security,
              ),
              buildSidebarButton(
                "Paramètres système",
                Icons.settings,
                section: DashboardSection.settings,
              ),
              buildSidebarButton(
                "Logs d’activité",
                Icons.list_alt,
                section: DashboardSection.logs,
              ),
              Spacer(),
              buildSidebarButton(
                "Déconnexion",
                Icons.logout,
                onTap: () {
                  authController.logout();
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        title: Obx(() => Text(getSectionTitle(currentSection.value))),
        actions: [
          Icon(Icons.notifications),
          SizedBox(width: 20),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.blueGrey.shade800),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          switch (currentSection.value) {
            case DashboardSection.dashboard:
              return buildDashboardOverview();
            case DashboardSection.users:
              return buildUsersSection();
            case DashboardSection.security:
              return buildSecuritySection();
            case DashboardSection.settings:
              return buildSettingsSection();
            case DashboardSection.logs:
              return buildLogsSection();
            default:
              return Center(child: Text("Section inconnue"));
          }
        }),
      ),
      floatingActionButton: Obx(() {
        return currentSection.value == DashboardSection.users
            ? FloatingActionButton(
              onPressed: () => Get.to(() => UserForm()),
              child: Icon(Icons.add),
              backgroundColor: Colors.blueGrey.shade800,
              tooltip: "Ajouter Utilisateur",
            )
            : SizedBox.shrink(); // widget vide si ce n'est pas la section users
      }),
    );
  }

  // ---------------- Sidebar Button ---------------- //
  Widget buildSidebarButton(
    String label,
    IconData icon, {
    DashboardSection? section,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: TextStyle(color: Colors.white)),
      selected: section != null && section == currentSection.value,
      selectedTileColor: Colors.blueGrey.shade700,
      onTap: () {
        Navigator.pop(context); // Ferme le drawer
        if (section != null) {
          currentSection.value = section;
        } else if (onTap != null) {
          onTap(); // Action personnalisée (ex: déconnexion)
        }
      },
    );
  }

  // ---------------- Helper ---------------- //
  String getSectionTitle(DashboardSection section) {
    switch (section) {
      case DashboardSection.dashboard:
        return "Tableau de bord";
      case DashboardSection.users:
        return "Gestion des utilisateurs";
      case DashboardSection.security:
        return "Sécurité";
      case DashboardSection.settings:
        return "Paramètres système";
      case DashboardSection.logs:
        return "Logs d’activité";
      default:
        return "";
    }
  }

  // ---------------- Sections ---------------- //
  Widget buildDashboardOverview() {
    return Center(
      child: Text(
        "Bienvenue dans le tableau de bord EasyConnect!\n\nRésumé des informations clés ici.",
        style: TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildUsersSection() {
    if (userController.isLoading.value) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.blueGrey,
          strokeWidth: 6,
        ),
      );
    }
    if (userController.users.isEmpty) {
      return Center(
        child: Text("Aucun utilisateur trouvé", style: TextStyle(fontSize: 18)),
      );
    }

    double width = MediaQuery.of(context).size.width;
    int crossAxisCount =
        width >= 1200
            ? 3
            : width >= 800
            ? 2
            : 1;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3.2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: userController.users.length,
      itemBuilder: (context, index) {
        final user = userController.users[index];
        return UserCard(user: user, controller: userController);
      },
    );
  }

  Widget buildSecuritySection() {
    return Center(
      child: Text(
        "Section Sécurité\n\nGestion des rôles, permissions et authentification.",
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildSettingsSection() {
    return Center(
      child: Text(
        "Section Paramètres Système\n\nConfiguration générale de l’application.",
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget buildLogsSection() {
    return Center(
      child: Text(
        "Section Logs d’activité\n\nHistorique des actions effectuées par les utilisateurs.",
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ---------------- UserCard ---------------- //
class UserCard extends StatelessWidget {
  final UserModel user;
  final UserController controller;

  const UserCard({required this.user, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.blueGrey.shade200,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // User info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${user.nom} ${user.prenom}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  "${user.email}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        user.isActive
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.isActive ? "Actif" : "Inactif",
                    style: TextStyle(
                      color:
                          user.isActive
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blueGrey),
                  onPressed: () => Get.to(() => UserForm(user: user)),
                  tooltip: "Modifier",
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade400),
                  onPressed: () => _confirmDelete(context, user.id.toString()),
                  tooltip: "Supprimer",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    Get.defaultDialog(
      title: "Supprimer",
      middleText: "Voulez-vous vraiment supprimer cet utilisateur ?",
      textConfirm: "Oui",
      textCancel: "Non",
      onConfirm: () {
        controller.deleteUser(id);
        Get.back();
      },
    );
  }
}
