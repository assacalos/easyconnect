import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easyconnect/services/client_portal_service.dart';
import 'package:easyconnect/Views/Client/client_dashboard_page.dart';

class ClientContactPage extends StatefulWidget {
  const ClientContactPage({super.key});

  @override
  State<ClientContactPage> createState() => _ClientContactPageState();
}

class _ClientContactPageState extends State<ClientContactPage> {
  List<dynamic> _list = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ClientPortalService.getContact();
      if (!mounted) return;
      setState(() {
        _list = (res['data'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact'),
        backgroundColor: ClientDashboardPage.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(onPressed: _load, child: const Text('Réessayer')),
                        ],
                      ),
                    ),
                  )
                : _list.isEmpty
                    ? const Center(child: Text('Aucune coordonnée renseignée.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _list.length,
                        itemBuilder: (context, i) {
                          final c = _list[i] as Map<String, dynamic>;
                          final key = (c['key'] as String?)?.toLowerCase() ?? '';
                          final label = c['label']?.toString() ?? c['key']?.toString() ?? '';
                          final value = c['value']?.toString() ?? '';
                          IconData icon = Icons.info;
                          if (key.contains('phone') || key.contains('tel')) icon = Icons.phone;
                          else if (key.contains('email')) icon = Icons.email;
                          else if (key.contains('address') || key.contains('adresse')) icon = Icons.location_on;
                          else if (key.contains('web')) icon = Icons.language;
                          final isLink = key.contains('email') || key.contains('web') || key.contains('url') || value.startsWith('http') || value.contains('@');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Icon(icon, color: ClientDashboardPage.primaryColor),
                              title: Text(label),
                              subtitle: Text(value),
                              trailing: isLink ? const Icon(Icons.open_in_new) : null,
                              onTap: isLink ? () => _launchUrl(value) : null,
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
