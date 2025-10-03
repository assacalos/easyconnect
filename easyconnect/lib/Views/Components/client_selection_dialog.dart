import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';

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
      final clients = await _clientService.getClients(
        status: 1,
      ); // Status 1 = Validé
      _clients.value = clients;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les clients validés',
        snackPosition: SnackPosition.BOTTOM,
      );
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
              final nomLower = client.nom?.toLowerCase() ?? '';
              final emailLower = client.email?.toLowerCase() ?? '';
              final contactLower = client.contact?.toLowerCase() ?? '';
              return nomLower.contains(searchLower) ||
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
                const Text(
                  'Sélectionner un client',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Get.back(),
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
              child: Obx(
                () =>
                    _isLoading.value
                        ? const Center(child: CircularProgressIndicator())
                        : _clients.isEmpty
                        ? const Center(child: Text('Aucun client trouvé'))
                        : ListView.builder(
                          itemCount: _clients.length,
                          itemBuilder: (context, index) {
                            final client = _clients[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: client.statusColor,
                                  child: Icon(
                                    client.statusIcon,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  '${client.nom ?? ''} ${client.prenom ?? ''}'
                                      .trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (client.nomEntreprise != null)
                                      Text(
                                        'Entreprise: ${client.nomEntreprise}',
                                      ),
                                    if (client.email != null)
                                      Text('Email: ${client.email}'),
                                    if (client.contact != null)
                                      Text('Contact: ${client.contact}'),
                                    Text(
                                      'Statut: ${client.statusText}',
                                      style: TextStyle(
                                        color: client.statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  widget.onClientSelected(client);
                                  Get.back();
                                },
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
