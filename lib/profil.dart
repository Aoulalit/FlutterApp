import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'register_page.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  String? _userEmail;
  bool _isLoading = true;
  List<Map<String, dynamic>> _commandes = []; // Liste des commandes validées

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Charge l'email et les commandes validées
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    setState(() {
      _userEmail = email;
    });

    if (email != null) {
      await _fetchCommandes(email);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Récupère les commandes validées pour l'utilisateur connecté
  Future<void> _fetchCommandes(String email) async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:3002/api/commandes?email=$email"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _commandes = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      print("Erreur: $e");
    }
  }

  /// Déconnexion : supprime l'email et l'id de SharedPreferences
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userEmail');
    await prefs.remove('userId');

    // Redirige vers Login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userEmail == null || _userEmail!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profil'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                child: const Text("Se connecter"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text("S'inscrire"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const Icon(Icons.person, size: 50, color: Colors.orange),
                const SizedBox(height: 10),
                Text(
                  'Bienvenue, $_userEmail',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: _commandes.isEmpty
                ? const Center(child: Text("Aucune commande validée."))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: _commandes.length,
                    itemBuilder: (context, index) {
                      final commande = _commandes[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: const Icon(Icons.shopping_cart,
                              color: Colors.green),
                          title: Text(
                            "Commande #${commande['id_commande']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Date: ${commande['date_validation']}"),
                              Text("Quantité: ${commande['quantite']}"),
                              Text(
                                "Total: ${commande['prix_total']} €",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _logout,
            child: const Text("Déconnexion"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
