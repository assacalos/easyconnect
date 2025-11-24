import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';
import 'dart:io';

class BonCommandeFormPage extends StatelessWidget {
  final BonCommandeController controller = Get.put(BonCommandeController());
  final bool isEditing;
  final int? bonCommandeId;

  BonCommandeFormPage({super.key, this.isEditing = false, this.bonCommandeId});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le bon de commande' : 'Nouveau bon de commande',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection du client
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Validés uniquement',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        final selectedClient = controller.selectedClient.value;
                        if (selectedClient != null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedClient.nomEntreprise?.isNotEmpty == true
                                    ? selectedClient.nomEntreprise!
                                    : '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                        .trim()
                                        .isNotEmpty
                                    ? '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                        .trim()
                                    : 'Client #${selectedClient.id}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (selectedClient.nomEntreprise?.isNotEmpty ==
                                      true &&
                                  '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                      .trim()
                                      .isNotEmpty)
                                Text(
                                  'Contact: ${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                                      .trim(),
                                ),
                              if (selectedClient.email != null)
                                Text(selectedClient.email ?? ''),
                              if (selectedClient.contact != null)
                                Text(selectedClient.contact ?? ''),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: controller.clearSelectedClient,
                                child: const Text('Changer de client'),
                              ),
                            ],
                          );
                        }
                        return ElevatedButton(
                          onPressed: () => _showClientSelection(context),
                          child: const Text('Sélectionner un client'),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fichiers scannés
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fichiers scannés',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => controller.selectFiles(),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Ajouter des fichiers'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Formats acceptés: PDF, Images, Documents (max 10 MB par fichier)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        if (controller.selectedFiles.isEmpty) {
                          return const Center(
                            child: Text('Aucun fichier sélectionné'),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.selectedFiles.length,
                          itemBuilder: (context, index) {
                            final file = controller.selectedFiles[index];
                            return _buildFileCard(file, index);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSaveButton(formKey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard(Map<String, dynamic> file, int index) {
    final fileName = file['name'] as String? ?? 'Fichier';
    final filePath = file['path'] as String? ?? '';
    final fileType = file['type'] as String? ?? 'document';
    final fileSize = file['size'] as int? ?? 0;

    IconData fileIcon;
    if (fileType == 'pdf') {
      fileIcon = Icons.picture_as_pdf;
    } else if (fileType == 'image') {
      fileIcon = Icons.image;
    } else {
      fileIcon = Icons.insert_drive_file;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(fileIcon, color: Colors.blue),
        title: Text(fileName),
        subtitle: Text(_formatFileSize(fileSize)),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => controller.removeFile(index),
        ),
        onTap: () {
          // Afficher un aperçu si c'est une image
          if (fileType == 'image' && filePath.isNotEmpty) {
            _showImagePreview(filePath);
          }
        },
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showImagePreview(String imagePath) {
    Get.dialog(
      Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Aperçu'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Flexible(child: Image.file(File(imagePath), fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(GlobalKey<FormState> formKey) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            if (controller.selectedClient.value == null) {
              Get.snackbar(
                'Erreur',
                'Veuillez sélectionner un client validé',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            if (controller.selectedClient.value!.status != 1) {
              Get.snackbar(
                'Erreur',
                'Seuls les clients validés peuvent être sélectionnés',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            if (controller.selectedFiles.isEmpty) {
              Get.snackbar(
                'Erreur',
                'Veuillez ajouter au moins un fichier scanné',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return;
            }

            if (isEditing && bonCommandeId != null) {
              final success = await controller.updateBonCommande(
                bonCommandeId!,
              );
              if (success) {
                Get.back();
              }
            } else {
              final success = await controller.createBonCommande();
              if (success) {
                Get.back();
              }
            }
          }
        },
        icon: const Icon(Icons.save),
        label: const Text('Enregistrer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  void _showClientSelection(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ClientSelectionDialog(
            onClientSelected: (client) {
              controller.selectClient(client);
            },
          ),
    );
  }
}
