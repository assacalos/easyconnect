import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/besoin_controller.dart';

class BesoinFormPage extends StatelessWidget {
  const BesoinFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BesoinController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau besoin / Rappel patron'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Le patron sera rappelé automatiquement à la période que vous choisissez, jusqu\'à ce qu\'il traite le besoin.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller.titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Le titre est obligatoire'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              const Text(
                'Rappeler le patron :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Column(
                  children:
                      BesoinController.reminderOptions.map((opt) {
                        final value = opt['value']!;
                        final label = opt['label']!;
                        return RadioListTile<String>(
                          title: Text(label),
                          value: value,
                          groupValue: controller.reminderFrequency.value,
                          onChanged: (v) => controller.setReminderFrequency(v!),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              Obx(
                () => ElevatedButton.icon(
                  onPressed:
                      controller.isLoading.value
                          ? null
                          : () => controller.createBesoin(),
                  icon:
                      controller.isLoading.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send),
                  label: const Text('Envoyer au patron'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
