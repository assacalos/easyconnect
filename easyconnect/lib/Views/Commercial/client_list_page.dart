import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class ClientsPage extends StatefulWidget {
  final bool isPatron;
  final int status;

  const ClientsPage({super.key, this.isPatron = false, this.status = 1});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  void initState() {
    super.initState();
    // Récupérer l'index de l'onglet depuis les paramètres de la route
    final tabParam = Get.parameters['tab'];
    final initialIndex = tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Charger les données au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<ClientController>();
      controller.loadClients(status: null);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ClientController controller = Get.find<ClientController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Validés'),
            Tab(text: 'Rejetés'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.loadClients(status: null);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
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
    );
  }

  Widget _buildClientList(int status) {
    final ClientController controller = Get.find<ClientController>();
    return Obx(() {
      if (controller.isLoading.value) {
        return const SkeletonSearchResults(itemCount: 6);
      }

      // Filtrer les clients par statut
      // Si status est null, on le traite comme 0 (en attente)
      final clientList =
          controller.clients.where((c) {
            final clientStatus = c.status ?? 0; // null = en attente
            return clientStatus == status;
          }).toList();

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
      child: InkWell(
        onTap: () => Get.toNamed('/clients/${client.id}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom entreprise (prioritaire) et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.nomEntreprise?.isNotEmpty == true
                          ? client.nomEntreprise!
                          : "${client.prenom ?? ''} ${client.nom ?? ''}"
                              .trim()
                              .isNotEmpty
                          ? "${client.prenom ?? ''} ${client.nom ?? ''}".trim()
                          : 'Client #${client.id}',
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
              if (client.nomEntreprise?.isNotEmpty == true &&
                  "${client.prenom ?? ''} ${client.nom ?? ''}"
                      .trim()
                      .isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${client.prenom ?? ''} ${client.nom ?? ''}".trim(),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
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

              // Raison du rejet
              if (status == 2 &&
                  (client.commentaire != null &&
                      client.commentaire!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison du rejet: ${client.commentaire}',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

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
      ),
    );
  }

  void _showValidationDialog(client) {
    final ClientController controller = Get.find<ClientController>();
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le client'),
        content: const Text('Êtes-vous sûr de vouloir valider ce client ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.approveClient(client.id);
              // Recharger tous les clients après validation
              await controller.loadClients(status: null);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(client) {
    final ClientController controller = Get.find<ClientController>();
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
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                Get.back();
                await controller.rejectClient(
                  client.id,
                  reasonController.text.trim(),
                );
                // Recharger tous les clients après rejet
                await controller.loadClients(status: null);
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
