import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientFormPage extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final bool isEditing;
  final int? clientId;

  // contrôleurs pour les champs
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController nomEntrepriseController = TextEditingController();
  final TextEditingController situationGeographiqueController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();

  ClientFormPage({super.key, this.isEditing = false, this.clientId});

  @override
  Widget build(BuildContext context) {
    final ClientController controller = Get.find();

    if (isEditing && clientId != null) {
      // récupérer le client existant et pré-remplir
      final client = controller.clients.firstWhere((c) => c.id == clientId);
      nomController.text = client.nom.toString();
      prenomController.text = client.prenom.toString();
      nomEntrepriseController.text = client.nomEntreprise.toString();
      emailController.text = client.email.toString();
      telephoneController.text = client.contact.toString();
      adresseController.text = client.adresse.toString();
      situationGeographiqueController.text =
          client.situationGeographique.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Modifier un Client" : "Nouveau Client"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nomController,
                decoration: InputDecoration(labelText: "Nom"),
                validator: (value) => value!.isEmpty ? "Nom requis" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: prenomController,
                decoration: InputDecoration(labelText: "Prénom"),
                validator: (value) => value!.isEmpty ? "Prénom requis" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return "Email requis";
                  if (!GetUtils.isEmail(value)) return "Email invalide";
                  return null;
                },
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: telephoneController,
                decoration: InputDecoration(labelText: "Contact"),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Contact requis" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: adresseController,
                decoration: InputDecoration(labelText: "Adresse"),
                maxLines: 2,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: situationGeographiqueController,
                decoration: InputDecoration(
                  labelText: "Situation Géographique",
                ),
                validator:
                    (value) =>
                        value!.isEmpty
                            ? "Situation Géographique requise"
                            : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: nomEntrepriseController,
                decoration: InputDecoration(labelText: "Nom Entreprise"),
                validator:
                    (value) => value!.isEmpty ? "Nom Entreprise requis" : null,
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      "nom": nomController.text,
                      "prenom": prenomController.text,
                      "nom_entreprise": nomEntrepriseController.text,
                      "situation_geographique":
                          situationGeographiqueController.text,
                      "email": emailController.text,
                      "contact": telephoneController.text,
                      "adresse": adresseController.text,
                    };

                    if (isEditing && clientId != null) {
                      // TODO: appeler update API (si tu veux gérer update côté Laravel)
                      Get.snackbar("Succès", "Client modifié avec succès");
                    } else {
                      await controller.createClientFromMap(data);
                      Get.back(); // retour à la liste
                    }
                  }
                },
                child: Text(isEditing ? "Modifier" : "Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
