import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart'; // Importe ta page de login si tu veux y retourner après
// import 'profil.dart'; // Ou ta page Profil si tu préfères

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs pour chaque champ
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();
  final TextEditingController _villeCtrl = TextEditingController();
  final TextEditingController _cpCtrl = TextEditingController();

  bool _isLoading = false;

  Future<void> _signup() async {
    // Vérifie que le formulaire est valide
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Appel à la route /register_mobile
      final response = await http.post(
        Uri.parse('http://localhost:3002/api/auth/register_mobile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailCtrl.text.trim(),
          'motdepasse': _passwordCtrl.text.trim(),
          // admin: 0 si tu veux, ou 1 si c'est un admin
          'admin': 0,
          'nom': _nomCtrl.text.trim(),
          'prenom': _prenomCtrl.text.trim(),
          'adresse': _adresseCtrl.text.trim(),
          'ville': _villeCtrl.text.trim(),
          'code_postal': _cpCtrl.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // Succès
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Inscription réussie !")),
        );
        // Redirige vers la page Login ou Profil
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      } else {
        // Erreur
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: ${error['error']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscription"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, 
          child: Column(
            children: [
              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (val) => val == null || val.isEmpty ? "Entrez un email" : null,
              ),
              // Mot de passe
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: "Mot de passe"),
                obscureText: true,
                validator: (val) =>
                    val == null || val.length < 4 ? "Mot de passe trop court" : null,
              ),
              // Nom
              TextFormField(
                controller: _nomCtrl,
                decoration: const InputDecoration(labelText: "Nom"),
                validator: (val) => val == null || val.isEmpty ? "Entrez un nom" : null,
              ),
              // Prénom
              TextFormField(
                controller: _prenomCtrl,
                decoration: const InputDecoration(labelText: "Prénom"),
                validator: (val) => val == null || val.isEmpty ? "Entrez un prénom" : null,
              ),
              // Adresse
              TextFormField(
                controller: _adresseCtrl,
                decoration: const InputDecoration(labelText: "Adresse"),
                validator: (val) => val == null || val.isEmpty ? "Entrez une adresse" : null,
              ),
              // Ville
              TextFormField(
                controller: _villeCtrl,
                decoration: const InputDecoration(labelText: "Ville"),
                validator: (val) => val == null || val.isEmpty ? "Entrez une ville" : null,
              ),
              // Code postal
              TextFormField(
                controller: _cpCtrl,
                decoration: const InputDecoration(labelText: "Code postal"),
                validator: (val) => val == null || val.isEmpty ? "Entrez un code postal" : null,
              ),

              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signup,
                      child: const Text("S'inscrire"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}