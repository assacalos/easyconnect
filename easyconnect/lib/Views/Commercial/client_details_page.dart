import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Models/client_model.dart';

class ClientDetailsPage extends StatelessWidget {
  final ClientController controller = Get.find<ClientController>();
  final int clientId;

  ClientDetailsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.toNamed('/clients/$clientId/edit'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final client = controller.clients.firstWhere(
          (c) => c.id == clientId,
          orElse: () => Client(),
        );

        if (client.id == null) {
          return const Center(child: Text('Client non trouvé'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // En-tête avec informations principales
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        client.nom?.substring(0, 1).toUpperCase() ?? '?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${client.prenom} ${client.nom}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      client.nomEntreprise ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: client.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: client.statusColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            client.statusIcon,
                            size: 20,
                            color: client.statusColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            client.statusText,
                            style: TextStyle(
                              color: client.statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Informations détaillées
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Informations de contact', [
                      _buildInfoRow(Icons.email, 'Email', client.email ?? ''),
                      _buildInfoRow(
                        Icons.phone,
                        'Contact',
                        client.contact ?? '',
                      ),
                      _buildInfoRow(
                        Icons.location_on,
                        'Adresse',
                        client.adresse ?? '',
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Informations entreprise', [
                      _buildInfoRow(
                        Icons.business,
                        'Nom entreprise',
                        client.nomEntreprise ?? '',
                      ),
                      _buildInfoRow(
                        Icons.place,
                        'Situation géographique',
                        client.situationGeographique ?? '',
                      ),
                    ]),
                    if (client.status == 2 && client.commentaire != null) ...[
                      const SizedBox(height: 24),
                      _buildSection('Motif du rejet', [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            client.commentaire ?? '',
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
