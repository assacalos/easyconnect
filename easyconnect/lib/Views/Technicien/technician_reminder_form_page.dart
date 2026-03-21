import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/providers/technician_reminder_notifier.dart';
import 'package:easyconnect/Views/Components/app_bar_back_button.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';

class TechnicianReminderFormPage extends ConsumerStatefulWidget {
  const TechnicianReminderFormPage({super.key});

  @override
  ConsumerState<TechnicianReminderFormPage> createState() =>
      _TechnicianReminderFormPageState();
}

class _TechnicianReminderFormPageState extends ConsumerState<TechnicianReminderFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _companyNameController = TextEditingController();

  Client? _selectedClient;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  int _remindDaysBefore = 1;

  static const List<Map<String, dynamic>> remindOptions = [
    {'value': 1, 'label': '1 jour avant'},
    {'value': 2, 'label': '2 jours avant'},
    {'value': 3, 'label': '3 jours avant'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(technicianReminderProvider);
    final notifier = ref.read(technicianReminderProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBarBackButton(
            fallbackRoute: '/mes-rappels', iconColor: Colors.white),
        title: const Text('Nouveau rappel'),
        backgroundColor: const Color(0xFFC2410C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ex. : Piles à recharger, radio en maintenance… Vous serez notifié 1, 2 ou 3 jours avant la date limite.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  hintText: 'Piles à recharger, Radio en maintenance…',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Le titre est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Text(
                'Entreprise / client',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showClientPicker(context),
                icon: const Icon(Icons.business),
                label: Text(
                  _selectedClient != null
                      ? (_selectedClient!.nomEntreprise ?? _selectedClient!.nom ?? 'Client sélectionné')
                      : 'Choisir un client (optionnel)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(
                  labelText: 'Ou nom d\'entreprise (si pas de client)',
                  hintText: 'Nom libre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business_center),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Date limite *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_dueDate.day.toString().padLeft(2, '0')}/${_dueDate.month.toString().padLeft(2, '0')}/${_dueDate.year}',
                  style: const TextStyle(fontSize: 18),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Me rappeler :',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...remindOptions.map((opt) {
                final value = opt['value'] as int;
                final label = opt['label'] as String;
                return RadioListTile<int>(
                  title: Text(label),
                  value: value,
                  groupValue: _remindDaysBefore,
                  onChanged: (v) {
                    if (v != null) setState(() => _remindDaysBefore = v);
                  },
                );
              }),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _submit(notifier),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Enregistrer le rappel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2410C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClientPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ClientSelectionDialog(
        onClientSelected: (client) {
          Navigator.pop(ctx);
          setState(() {
            _selectedClient = client;
            _companyNameController.clear();
          });
        },
      ),
    );
  }

  Future<void> _submit(TechnicianReminderNotifier notifier) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }
    if (_selectedClient == null && _companyNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez un client ou saisissez un nom d\'entreprise'),
        ),
      );
      return;
    }

    final success = await notifier.createReminder(
      title: title,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      clientId: _selectedClient?.id,
      companyName: _selectedClient == null
          ? (_companyNameController.text.trim().isEmpty
              ? null
              : _companyNameController.text.trim())
          : null,
      dueDate: _dueDate,
      remindDaysBefore: _remindDaysBefore,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Rappel enregistré. Vous serez notifié avant la date limite.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/mes-rappels');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
 