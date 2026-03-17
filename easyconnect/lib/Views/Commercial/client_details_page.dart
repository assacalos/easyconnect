import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/client_notifier.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';

class ClientDetailsPage extends ConsumerWidget {
  final int clientId;

  const ClientDetailsPage({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientState = ref.watch(clientProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(fallbackRoute: '/clients'),
        title: const Text('Détails du client'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/clients/$clientId/edit'),
          ),
        ],
      ),
      body: clientState.isLoading
          ? const SkeletonPage(listItemCount: 6)
          : _buildBody(context, ref, clientState.clients),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Client> clients) {
    Client? client;
    final list = clients.where((c) => c.id == clientId).toList();
    if (list.isNotEmpty) client = list.first;
    if (client == null || client.id == null) {
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
                        (client.nomEntreprise?.isNotEmpty == true
                                ? client.nomEntreprise!.substring(0, 1)
                                : client.nom?.substring(0, 1) ?? '?')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      client.nomEntreprise?.isNotEmpty == true
                          ? client.nomEntreprise!
                          : '${client.prenom ?? ''} ${client.nom ?? ''}'
                              .trim()
                              .isNotEmpty
                          ? '${client.prenom ?? ''} ${client.nom ?? ''}'.trim()
                          : 'Client #${client.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (client.nomEntreprise?.isNotEmpty == true &&
                        '${client.prenom ?? ''} ${client.nom ?? ''}'
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${client.prenom ?? ''} ${client.nom ?? ''}'.trim(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
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
                      if (client.numeroContribuable != null &&
                          client.numeroContribuable!.isNotEmpty)
                        _buildInfoRow(
                          Icons.badge,
                          'Numéro contribuable',
                          client.numeroContribuable ?? '',
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
                    const SizedBox(height: 24),
                    _buildSection('Accès portail client', [
                      _buildPortalAccess(context, ref, client),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Entités associées', [
                      _buildEntityButtons(context, client.id!),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _buildPortalAccess(BuildContext context, WidgetRef ref, Client client) {
    final hasAccess = client.portalUserId != null;
    if (hasAccess) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.teal.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ce client a accès au portail',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.teal.shade900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Il peut se connecter à l\'espace client pour demander des interventions, consulter les annonces et le catalogue.',
                    style: TextStyle(color: Colors.teal.shade800, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ce client est enregistré par le commercial. Vous pouvez lui créer un accès au portail client (tickets, annonces, catalogue, contact).',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _createPortalAccess(context, ref, client),
          icon: const Icon(Icons.person_add),
          label: const Text('Créer un accès portail client'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _createPortalAccess(BuildContext context, WidgetRef ref, Client client) async {
    if (client.id == null || client.email == null || client.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le client doit avoir un email pour recevoir un accès portail.')),
      );
      return;
    }
    try {
      final res = await ClientService().createPortalAccess(client.id!);
      if (!context.mounted) return;
      final data = res['data'] as Map<String, dynamic>?;
      final email = data?['email']?.toString() ?? client.email;
      final tempPassword = data?['temporary_password']?.toString();
      final alreadyExisted = data?['already_existed'] == true;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Accès portail créé'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alreadyExisted
                    ? 'Un compte portail existait déjà pour cet email. L\'accès a été lié au client.'
                    : 'Transmettez ces identifiants au client pour qu\'il puisse se connecter à l\'espace client :'),
                const SizedBox(height: 16),
                _dialogRow('Email', email),
                if (tempPassword != null && tempPassword.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _dialogRow('Mot de passe temporaire', tempPassword),
                  const SizedBox(height: 8),
                  Text(
                    'Le client pourra modifier son mot de passe après connexion.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      ref.read(clientProvider.notifier).loadClients(forceRefresh: true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  Widget _dialogRow(String label, String? value) {
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label : ', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
          TextSpan(text: value ?? '', style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildEntityButtons(BuildContext context, int clientId) {
    return Column(
      children: [
        // Première ligne : Devis et Bordereaux
        Row(
          children: [
            Expanded(
              child: _buildEntityButton(
                icon: Icons.description,
                label: 'Devis',
                color: Colors.blue,
                onTap: () {
                  context.go('/devis-page?clientId=$clientId');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEntityButton(
                icon: Icons.assignment,
                label: 'Bordereaux',
                color: Colors.purple,
                onTap: () {
                  context.go('/bordereaux?clientId=$clientId');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Deuxième ligne : Factures et Paiements
        Row(
          children: [
            Expanded(
              child: _buildEntityButton(
                icon: Icons.receipt_long,
                label: 'Factures',
                color: Colors.green,
                onTap: () {
                  context.go('/invoices?clientId=$clientId');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEntityButton(
                icon: Icons.payment,
                label: 'Paiements',
                color: Colors.orange,
                onTap: () {
                  context.go('/payments?clientId=$clientId');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Troisième ligne : Interventions
        Row(
          children: [
            Expanded(
              child: _buildEntityButton(
                icon: Icons.build,
                label: 'Interventions',
                color: Colors.teal,
                onTap: () {
                  context.go('/interventions?clientId=$clientId');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntityButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
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
