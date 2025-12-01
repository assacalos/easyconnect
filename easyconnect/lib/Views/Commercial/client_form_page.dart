import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientFormPage extends StatefulWidget {
  final bool isEditing;
  final int? clientId;

  const ClientFormPage({super.key, this.isEditing = false, this.clientId});

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ClientController controller = Get.put(ClientController());

  // contrôleurs pour les champs
  late final TextEditingController nomController;
  late final TextEditingController prenomController;
  late final TextEditingController nomEntrepriseController;
  late final TextEditingController situationGeographiqueController;
  late final TextEditingController emailController;
  late final TextEditingController telephoneController;
  late final TextEditingController adresseController;

  @override
  void initState() {
    super.initState();
    nomController = TextEditingController();
    prenomController = TextEditingController();
    nomEntrepriseController = TextEditingController();
    situationGeographiqueController = TextEditingController();
    emailController = TextEditingController();
    telephoneController = TextEditingController();
    adresseController = TextEditingController();

    // Pré-remplir si édition
    if (widget.isEditing && widget.clientId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadClientData();
      });
    }
  }

  void _loadClientData() {
    try {
      final client = controller.clients.firstWhere(
        (c) => c.id == widget.clientId,
      );
      nomController.text = client.nom?.toString() ?? '';
      prenomController.text = client.prenom?.toString() ?? '';
      nomEntrepriseController.text = client.nomEntreprise?.toString() ?? '';
      emailController.text = client.email?.toString() ?? '';
      telephoneController.text = client.contact?.toString() ?? '';
      adresseController.text = client.adresse?.toString() ?? '';
      situationGeographiqueController.text =
          client.situationGeographique?.toString() ?? '';
    } catch (e) {
      // Le client n'est pas encore chargé
    }
  }

  void _clearForm() {
    nomController.clear();
    prenomController.clear();
    nomEntrepriseController.clear();
    situationGeographiqueController.clear();
    emailController.clear();
    telephoneController.clear();
    adresseController.clear();
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    nomEntrepriseController.dispose();
    situationGeographiqueController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.isEditing ? "Modifier un Client" : "Nouveau Client"),
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nom entreprise en premier
                TextFormField(
                  controller: nomEntrepriseController,
                  decoration: InputDecoration(labelText: "Nom Entreprise *"),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Nom Entreprise requis" : null,
                ),
                SizedBox(height: 10),
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
                  validator:
                      (value) => value!.isEmpty ? "Contact requis" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: adresseController,
                  decoration: InputDecoration(labelText: "Adresse"),
                  maxLines: 2,
                ),
                SizedBox(height: 10),
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
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final data = {
                        "nom": nomController.text.trim(),
                        "prenom": prenomController.text.trim(),
                        "nom_entreprise": nomEntrepriseController.text.trim(),
                        "situation_geographique":
                            situationGeographiqueController.text.trim(),
                        "email": emailController.text.trim(),
                        "contact": telephoneController.text.trim(),
                        "adresse": adresseController.text.trim(),
                      };

                      bool success = false;
                      if (widget.isEditing && widget.clientId != null) {
                        success = await controller.updateClient(data);
                      } else {
                        success = await controller.createClientFromMap(data);
                      }

                      if (success) {
                        // Réinitialiser les champs
                        _clearForm();
                        // Attendre un peu pour que le snackbar s'affiche
                        await Future.delayed(const Duration(milliseconds: 500));
                        // Rediriger vers la page de liste des clients
                        if (mounted) {
                          Get.offNamed('/clients');
                        }
                      }
                    }
                  },
                  child: Text(widget.isEditing ? "Modifier" : "Enregistrer"),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
