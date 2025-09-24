import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';

class ClientForm extends StatelessWidget {
  final Client? client;
  final Function(Client) onSubmit;
  final bool isEditing;

  ClientForm({
    super.key,
    this.client,
    required this.onSubmit,
    this.isEditing = false,
  });

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _adresseController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (isEditing && client != null) {
      _nomController.text = client!.nom ?? '';
      _emailController.text = client!.email ?? '';
      _contactController.text = client!.contact ?? '';
      _adresseController.text = client!.adresse ?? '';
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nomController,
            decoration: const InputDecoration(
              labelText: 'Nom',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un email';
              }
              if (!GetUtils.isEmail(value)) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactController,
            decoration: const InputDecoration(
              labelText: 'Contact',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un numéro de contact';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _adresseController,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une adresse';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final clientData = Client(
                  id: isEditing ? client!.id : null,
                  nom: _nomController.text,
                  email: _emailController.text,
                  contact: _contactController.text,
                  adresse: _adresseController.text,
                  status: isEditing ? client!.status : 0,
                );
                onSubmit(clientData);
              }
            },
            child: Text(isEditing ? 'Modifier' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}
