import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Models/client_model.dart';

class ClientValidationPage extends StatelessWidget {
  final ClientController controller = Get.find<ClientController>();

  ClientValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Validation des Clients'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Validés'),
              Tab(text: 'Rejetés'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildClientList(0), // En attente
            _buildClientList(1), // Validés
            _buildClientList(2), // Rejetés
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(int status) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final clients =
          controller.clients.where((c) => c.status == status).toList();

      if (clients.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 0
                    ? Icons.pending
                    : status == 1
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 0
                    ? "Aucun client en attente"
                    : status == 1
                    ? "Aucun client validé"
                    : "Aucun client rejeté",
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clients.length,
        itemBuilder: (context, index) {
          final client = clients[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  title: Text(
                    '${client.nomEntreprise}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    'Ajouté le ${client.createdAt?.substring(0, 10)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: _buildStatusChip(client),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Contact',
                        '${client.prenom} ${client.nom}',
                      ),
                      _buildInfoRow('Email', client.email ?? ''),
                      _buildInfoRow('Téléphone', client.contact ?? ''),
                      _buildInfoRow('Adresse', client.adresse ?? ''),
                      _buildInfoRow(
                        'Situation',
                        client.situationGeographique ?? '',
                      ),
                      if (client.status == 2 && client.commentaire != null)
                        _buildInfoRow(
                          'Motif du rejet',
                          client.commentaire ?? '',
                          color: Colors.red.shade700,
                        ),
                    ],
                  ),
                ),
                if (status == 0)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Rejeter'),
                          onPressed: () => _showRejectDialog(client),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Valider'),
                          onPressed: () => _showApproveDialog(client),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildStatusChip(Client client) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: client.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: client.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(client.statusIcon, size: 16, color: client.statusColor),
          const SizedBox(width: 4),
          Text(
            client.statusText,
            style: TextStyle(
              color: client.statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Client client) {
    final commentController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le client'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir rejeter ce client ? Cette action nécessite un commentaire explicatif.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Motif du rejet',
                border: OutlineInputBorder(),
                hintText: 'Expliquez la raison du rejet...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                controller.rejectClient(client.id ?? 0, commentController.text);
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Client client) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le client'),
        content: const Text(
          'Êtes-vous sûr de vouloir valider ce client ? Cette action permettra au commercial de commencer à travailler avec ce client.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.approveClient(client.id ?? 0);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
