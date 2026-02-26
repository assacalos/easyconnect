import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/besoin_controller.dart';
import 'package:easyconnect/Models/besoin_model.dart';
import 'package:easyconnect/Views/Technicien/besoin_form_page.dart';
import 'package:intl/intl.dart';

class BesoinListPage extends StatefulWidget {
  const BesoinListPage({super.key});

  @override
  State<BesoinListPage> createState() => _BesoinListPageState();
}

class _BesoinListPageState extends State<BesoinListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.put(BesoinController()).loadBesoins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BesoinController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Besoins / Rappels patron'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadBesoins(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Obx(() => Wrap(
              spacing: 8,
              children: [
                _chip(context, controller, 'all', 'Tous'),
                _chip(context, controller, 'pending', 'En attente'),
                _chip(context, controller, 'treated', 'Traités'),
              ],
            )),
          ),
          Expanded(child: Obx(() {
        if (controller.isLoading.value && controller.besoins.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.besoins.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun besoin',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Créez un besoin pour que le patron soit rappelé automatiquement',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.besoins.length,
          itemBuilder: (context, index) {
            final besoin = controller.besoins[index];
            return _BesoinCard(besoin: besoin, controller: controller);
          },
        );
      })),
        ],
      ),
      floatingActionButton: controller.isTechnicien
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Get.to(() => const BesoinFormPage());
                controller.loadBesoins(forceRefresh: true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouveau besoin'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _chip(BuildContext context, BesoinController controller, String value, String label) {
    final selected = controller.selectedStatus.value == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          controller.selectedStatus.value = value;
          controller.loadBesoins(forceRefresh: true);
        },
      ),
    );
  }
}

class _BesoinCard extends StatelessWidget {
  final Besoin besoin;
  final BesoinController controller;

  const _BesoinCard({required this.besoin, required this.controller});

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          besoin.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (besoin.description != null && besoin.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  besoin.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    besoin.reminderFrequencyLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor: besoin.isPending ? Colors.orange.shade100 : Colors.green.shade100,
                  label: Text(
                    besoin.isPending ? 'En attente' : 'Traité',
                    style: const TextStyle(fontSize: 12),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Créé le ${format.format(besoin.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: controller.canMarkTreated && besoin.isPending
            ? IconButton(
                icon: const Icon(Icons.check_circle),
                tooltip: 'Marquer comme traité',
                onPressed: () => _showMarkTreatedDialog(context),
              )
            : null,
      ),
    );
  }

  void _showMarkTreatedDialog(BuildContext context) {
    final noteController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Marquer comme traité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Note optionnelle :'),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Commentaire...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.markTreated(
                besoin.id!,
                note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              );
            },
            child: const Text('Marquer traité'),
          ),
        ],
      ),
    );
  }
}
