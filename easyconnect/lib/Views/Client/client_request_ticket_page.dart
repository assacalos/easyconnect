import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/services/client_portal_service.dart';
import 'package:easyconnect/Views/Client/client_dashboard_page.dart';

class ClientRequestTicketPage extends StatefulWidget {
  const ClientRequestTicketPage({super.key});

  @override
  State<ClientRequestTicketPage> createState() => _ClientRequestTicketPageState();
}

class _ClientRequestTicketPageState extends State<ClientRequestTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _problemController = TextEditingController();

  String _selectedType = 'on_site';
  String _selectedPriority = 'medium';
  DateTime? _scheduledDate;
  bool _isSubmitting = false;

  static const _types = [
    {'value': 'external', 'label': 'Externe'},
    {'value': 'on_site', 'label': 'Sur place'},
  ];
  static const _priorities = [
    {'value': 'low', 'label': 'Faible'},
    {'value': 'medium', 'label': 'Moyenne'},
    {'value': 'high', 'label': 'Élevée'},
    {'value': 'urgent', 'label': 'Urgente'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _equipmentController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _scheduledDate == null) {
      if (_scheduledDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une date.')),
        );
      }
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final res = await ClientPortalService.createInterventionRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        scheduledDate: DateFormat('yyyy-MM-dd').format(_scheduledDate!),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        equipment: _equipmentController.text.trim().isEmpty ? null : _equipmentController.text.trim(),
        problemDescription: _problemController.text.trim().isEmpty ? null : _problemController.text.trim(),
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Demande envoyée.')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Erreur lors de l\'envoi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demander une intervention'),
        backgroundColor: ClientDashboardPage.primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _types.map((t) => DropdownMenuItem(value: t['value'] as String, child: Text(t['label'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedType = v ?? 'on_site'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priorité *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items: _priorities.map((p) => DropdownMenuItem(value: p['value'] as String, child: Text(p['label'] as String))).toList(),
                onChanged: (v) => setState(() => _selectedPriority = v ?? 'medium'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _scheduledDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date souhaitée *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _scheduledDate != null ? DateFormat('dd/MM/yyyy').format(_scheduledDate!) : 'Choisir une date',
                    style: TextStyle(color: _scheduledDate != null ? Colors.black : Colors.grey[600]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu / Adresse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(
                  labelText: 'Équipement concerné',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _problemController,
                decoration: const InputDecoration(
                  labelText: 'Description du problème',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info_outline),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: ClientDashboardPage.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Envoi...' : 'Envoyer la demande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
