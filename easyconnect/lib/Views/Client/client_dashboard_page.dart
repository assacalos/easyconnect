import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/providers/auth_notifier.dart';
import 'package:easyconnect/Views/Components/user_profile_card.dart';

/// Dashboard portail client : accès aux demandes de ticket, annonces, catalogue, offres, contact.
class ClientDashboardPage extends ConsumerStatefulWidget {
  const ClientDashboardPage({super.key});

  static const String title = 'Espace Client';
  static const Color primaryColor = Color(0xFF0D9488);

  @override
  ConsumerState<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends ConsumerState<ClientDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ClientDashboardPage.title),
        backgroundColor: ClientDashboardPage.primaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UserProfileCard(showPermissions: false),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Demander une intervention',
                subtitle: 'Créer un ticket pour une intervention technique',
                icon: Icons.build_circle,
                color: ClientDashboardPage.primaryColor,
                onTap: () => context.push('/client/request-ticket'),
              ),
              _SectionCard(
                title: 'Mes demandes',
                subtitle: 'Suivre l\'état de vos tickets',
                icon: Icons.list_alt,
                color: Colors.blue,
                onTap: () => context.push('/client/my-tickets'),
              ),
              _SectionCard(
                title: 'Annonces & Promotions',
                subtitle: 'Actualités et offres spéciales',
                icon: Icons.campaign,
                color: Colors.orange,
                onTap: () => context.push('/client/announcements'),
              ),
              _SectionCard(
                title: 'Catalogue & Articles',
                subtitle: 'Nos articles avec prix',
                icon: Icons.inventory_2,
                color: Colors.indigo,
                onTap: () => context.push('/client/catalog'),
              ),
              _SectionCard(
                title: 'Offres',
                subtitle: 'Promotions en cours',
                icon: Icons.local_offer,
                color: Colors.deepOrange,
                onTap: () => context.push('/client/offers'),
              ),
              _SectionCard(
                title: 'Contact',
                subtitle: 'Téléphone, email, adresse',
                icon: Icons.contact_phone,
                color: Colors.teal,
                onTap: () => context.push('/client/contact'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
