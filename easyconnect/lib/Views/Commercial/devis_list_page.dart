import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class DevisListPage extends StatelessWidget {
  final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
  final DevisController controller = Get.find<DevisController>();
  final formatDate = DateFormat('dd/MM/yyyy');

  DevisListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Recharger les devis au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadDevis();
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Devis'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Validés'),
              Tab(text: 'Rejetés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildDevisList(1), // En attente
                _buildDevisList(2), // Validés
                _buildDevisList(3), // Rejetés
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite
            UniformAddButton(
              onPressed: () => Get.toNamed('/devis/new'),
              label: 'Nouveau Devis',
              icon: Icons.description,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevisList(int status) {
    final DevisController controller = Get.find<DevisController>();
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final devisList =
          controller.devis.where((d) => d.status == status).toList();

      if (devisList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 1
                    ? Icons.access_time
                    : status == 2
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 1
                    ? 'Aucun devis en attente'
                    : status == 2
                    ? 'Aucun devis validé'
                    : 'Aucun devis rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: devisList.length,
        itemBuilder: (context, index) {
          final devis = devisList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  title: Row(
                    children: [
                      Text(
                        devis.reference,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: devis.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: devis.statusColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              devis.statusIcon,
                              size: 16,
                              color: devis.statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              devis.statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: devis.statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Créé le ${formatDate.format(devis.dateCreation)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (devis.dateValidite != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.event,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Valide jusqu\'au ${formatDate.format(devis.dateValidite!)}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    formatCurrency.format(devis.totalTTC),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ButtonBar(
                  alignment: MainAxisAlignment.end,
                  children: [
                    if (status == 1) ...[
                      TextButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                        onPressed: () => controller.acceptDevis(devis.id!),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Rejeter'),
                        onPressed: () => _showRejectDialog(devis),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf),
                      onPressed: () => controller.generatePDF(devis.id!),
                      tooltip: 'Générer PDF',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }

  void _showRejectDialog(Devis devis) {
    final commentController = TextEditingController();
    final DevisController controller = Get.put(DevisController());
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le devis'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir rejeter ce devis ? Cette action nécessite un commentaire explicatif.',
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
                controller.rejectDevis(devis.id!, commentController.text);
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
}
