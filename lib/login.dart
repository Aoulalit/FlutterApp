import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Import de HomeScreen pour l'utiliser après la connexion
import 'main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Appel à ton API Node.js (change l'URL si besoin, et remplace localhost par 10.0.2.2 sur Android)
      final response = await http.post(
        Uri.parse('http://localhost:3002/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'motdepasse': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Stocker l'email et l'ID de l'utilisateur pour rester connecté
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', data['email']);
          await prefs.setInt('userId', data['id']);

          _showSuccessDialog();
        } else {
          // Cas où le login échoue (ex: mot de passe incorrect)
          throw Exception(data['error'] ?? 'Erreur de connexion');
        }
      } else {
        throw Exception('Erreur de connexion (code ${response.statusCode})');
      }
    } catch (e) {
      // Affiche l'erreur dans un SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Connexion réussie"),
          content: const Text("Vous êtes maintenant connecté !"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme l'AlertDialog
                // Redirige directement vers HomeScreen, onglet "Achat" (index = 1)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialIndex: 1),
                  ),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Champ Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            // Champ Mot de passe
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Mot de passe"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            // Bouton Se connecter (ou un spinner s'il est en cours)
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text("Se connecter"),
                  ),
          ],
        ),
      ),
    );
  }
}
