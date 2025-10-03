import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientsPage extends StatelessWidget {
  final bool isPatron;
  final int status;

  ClientsPage({super.key, this.isPatron = false, this.status = 1});

  // Fonctions pour convertir le statut int en représentation textuelle
  String _getStatusText(int status) {
    switch (status) {
      case 1:
        return "Validé";
      case 2:
        return "Rejeté";
      default:
        return "En attente";
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.orange; // en attente
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
    final ClientController controller = Get.find<ClientController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Clients'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Validés'),
              Tab(text: 'Rejetés'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.loadClients();
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildClientList(0), // En attente
                _buildClientList(1), // Validés
                _buildClientList(2), // Rejetés
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite (seulement pour commerciaux et patrons)
            RoleBasedWidget(
              allowedRoles: [Roles.ADMIN, Roles.PATRON, Roles.COMMERCIAL],
              child: UniformAddButton(
                onPressed: () => Get.toNamed('/clients/new'),
                label: 'Nouveau Client',
                icon: Icons.person_add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(int status) {
    final ClientController controller = Get.find<ClientController>();
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final clientList =
          controller.clients.where((c) => c.status == status).toList();

      if (clientList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 0
                    ? Icons.access_time
                    : status == 1
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 0
                    ? 'Aucun client en attente'
                    : status == 1
                    ? 'Aucun client validé'
                    : 'Aucun client rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clientList.length,
        itemBuilder: (context, index) {
          final client = clientList[index];
          return _buildClientCard(client);
        },
      );
    });
  }

  Widget _buildClientCard(client) {
    final status = client.status ?? 0;
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${client.prenom} ${client.nom}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Informations client
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    client.email.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(client.contact.toString()),
              ],
            ),

            // Actions selon le statut et le rôle
            if (status == 0) ...[
              const SizedBox(height: 8),
              // Seul le patron peut valider/rejeter
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showValidationDialog(client),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectionDialog(client),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Rejeter'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showValidationDialog(client) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le client'),
        content: const Text('Êtes-vous sûr de vouloir valider ce client ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la validation
              Get.back();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(client) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir rejeter ce client ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                // TODO: Implémenter le rejet
                Get.back();
              } else {
                Get.snackbar('Erreur', 'Veuillez saisir une raison');
              }
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
