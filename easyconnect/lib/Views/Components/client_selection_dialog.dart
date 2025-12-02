import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class ClientSelectionDialog extends StatefulWidget {
  final Function(Client) onClientSelected;

  const ClientSelectionDialog({super.key, required this.onClientSelected});

  @override
  State<ClientSelectionDialog> createState() => _ClientSelectionDialogState();
}

class _ClientSelectionDialogState extends State<ClientSelectionDialog> {
  final _searchController = TextEditingController();
  final _clientService = ClientService();
  final _clients = <Client>[].obs;
  final _isLoading = false.obs;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadClients() async {
    try {
      _isLoading.value = true;

      // Réinitialiser la liste pour éviter les problèmes de colonnes
      _clients.value = [];

      final clients = await _clientService.getClients(
        status: 1,
      ); // Status 1 = Validé

      _clients.value = clients;

      // Vérifier si des clients ont été chargés
      if (clients.isEmpty) {
        // Ne pas afficher de snackbar automatiquement pour éviter le spam
        // L'utilisateur verra le message dans le dialog
      }
    } catch (e) {
      // Ne pas afficher de snackbar dans le dialog pour éviter les messages d'erreur répétés
      // L'erreur sera affichée dans le dialog lui-même
      print('⚠️ [CLIENT_SELECTION_DIALOG] Erreur lors du chargement: $e');
      _clients.value = []; // S'assurer que la liste est vide en cas d'erreur
    } finally {
      _isLoading.value = false;
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        _loadClients();
      } else {
        final filteredClients =
            _clients.where((client) {
              final searchLower = query.toLowerCase();
              final nomEntrepriseLower =
                  (client.nomEntreprise ?? '').toLowerCase();
              final nomLower = (client.nom ?? '').toLowerCase();
              final prenomLower = (client.prenom ?? '').toLowerCase();
              final emailLower = (client.email ?? '').toLowerCase();
              final contactLower = (client.contact ?? '').toLowerCase();
              return nomEntrepriseLower.contains(searchLower) ||
                  nomLower.contains(searchLower) ||
                  prenomLower.contains(searchLower) ||
                  emailLower.contains(searchLower) ||
                  contactLower.contains(searchLower);
            }).toList();
        _clients.value = filteredClients;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Sélectionner un client',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (_isLoading.value) {
                  return const SkeletonSearchResults(itemCount: 4);
                }

                if (_clients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun client validé disponible',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualiser'),
                          onPressed: _loadClients,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    // Prioriser nom entreprise
                    final nameToDisplay =
                        client.nomEntreprise?.isNotEmpty == true
                            ? client.nomEntreprise!
                            : '${client.nom ?? ''} ${client.prenom ?? ''}'
                                .trim()
                                .isNotEmpty
                            ? '${client.nom ?? ''} ${client.prenom ?? ''}'
                                .trim()
                            : 'Client #${client.id}';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: client.statusColor,
                          child: Icon(
                            client.statusIcon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          nameToDisplay,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Afficher nom/prénom si nom entreprise est affiché en titre
                            if (client.nomEntreprise?.isNotEmpty == true &&
                                '${client.nom ?? ''} ${client.prenom ?? ''}'
                                    .trim()
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  'Contact: ${client.nom ?? ''} ${client.prenom ?? ''}'
                                      .trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            if (client.email != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  'Email: ${client.email}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            if (client.contact != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  'Tél: ${client.contact}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                'Statut: ${client.statusText}',
                                style: TextStyle(
                                  color: client.statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        dense: true,
                        onTap: () {
                          widget.onClientSelected(client);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
