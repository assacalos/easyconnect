import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Views/Commercial/client_form_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientsPage extends StatelessWidget {
  final bool isPatron;
  final int status;
  final ClientController controller = Get.put(ClientController());

  ClientsPage({super.key, this.isPatron = false, this.status = 1});

  // Fonctions pour convertir le statut int en représentation textuelle
  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "Validé";
      case 2:
        return "Rejeté";
      default:
        return "Soumis";
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange; // soumis ou en attente
    }
  }

  IconData _getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.check_circle;
      case 2:
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.loadClients();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Mes Clients",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              controller.loadClients();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.grey.shade100],
          ),
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Chargement des clients...",
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ],
              ),
            );
          }
          if (controller.clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucun client trouvé",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Commencez par ajouter votre premier client",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: controller.clients.length,
            itemBuilder: (context, index) {
              final client = controller.clients[index];
              final status = client.status ?? 0; // Valeur par défaut si null
              final statusText = _getStatusText(status);
              final statusColor = _getStatusColor(status);
              final statusIcon = _getStatusIcon(status);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          client.nom.toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      "${client.prenom} ${client.nom}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                client.email.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue.shade700),
                          onPressed: () {
                            Get.to(
                              () => ClientFormPage(
                                isEditing: true,
                                clientId: client.id,
                              ),
                              transition: Transition.rightToLeft,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red.shade600),
                          onPressed: () {
                            Get.defaultDialog(
                              title: "Confirmer la suppression",
                              titleStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                              middleText:
                                  "Êtes-vous sûr de vouloir supprimer ce client ?",
                              textCancel: "Annuler",
                              textConfirm: "Supprimer",
                              confirmTextColor: Colors.white,
                              buttonColor: Colors.red.shade600,
                              cancelTextColor: Colors.blue.shade700,
                              onConfirm: () {
                                controller.deleteClient(client.id ?? 0);
                                Get.back();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Nouveau client",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          Get.to(() => ClientFormPage(), transition: Transition.downToUp);
        },
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
