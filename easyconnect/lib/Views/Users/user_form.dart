import 'package:easyconnect/Controllers/userController.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserForm extends StatefulWidget {
  final UserModel? user;
  UserForm({this.user});

  @override
  _UserFormState createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  final UserController controller = Get.find();

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  int role = 2;
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user?.nom ?? '');
    lastNameController = TextEditingController(text: widget.user?.prenom ?? '');
    emailController = TextEditingController(text: widget.user?.email ?? '');
    passwordController = TextEditingController();
    role = widget.user?.role ?? 2;
    isActive = widget.user?.isActive ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.user == null ? "Ajouter Utilisateur" : "Modifier Utilisateur",
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(labelText: "Prénom"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: "Nom"),
                validator: (v) => v!.isEmpty ? "Champ requis" : null,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (v) => !v!.contains('@') ? "Email invalide" : null,
              ),
              if (widget.user == null)
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: "Mot de passe"),
                  obscureText: true,
                  validator:
                      (v) => v!.length < 6 ? "Minimum 6 caractères" : null,
                ),
              DropdownButtonFormField<int>(
                value: 2,
                items:
                    [1, 2, 3]
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.toString()),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => role = v!),
                decoration: InputDecoration(labelText: "Rôle"),
              ),
              SwitchListTile(
                title: Text("Actif"),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
              SizedBox(height: 20),
              UniformFormButtons(
                onCancel: () => Get.back(),
                onSubmit: () {
                  if (_formKey.currentState!.validate()) {
                    final user = UserModel(
                      id: widget.user?.id ?? 0,
                      nom: firstNameController.text,
                      prenom: lastNameController.text,
                      email: emailController.text,
                      role: role,
                      isActive: isActive,
                    );
                    if (widget.user == null) {
                      controller.addUser(user, passwordController.text);
                    } else {
                      controller.updateUser(user);
                    }
                  }
                },
                submitText: 'Soumettre',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
