import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ThankYouPage.dart';

class ConfirmationPage extends StatelessWidget {
  final List<dynamic> panier;

  const ConfirmationPage({super.key, required this.panier});

  /// Calcule le total (prix * quantité) pour chaque produit
  double _calculateTotal() {
    double total = 0.0;
    for (var produit in panier) {
      // Convertir le prix en double
      final double prix = double.tryParse(produit['prix'].toString()) ?? 0.0;
      final int quantite = produit['quantite'] ?? 1;
      total += prix * quantite;
    }
    return total;
  }

  Future<void> _confirmerCommande(BuildContext context) async {
    try {
      // 1) Récupérer l'email depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');

      if (email == null || email.isEmpty) {
        // Pas d'email => pas connecté ?
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Aucun email trouvé, vous n'êtes pas connecté.")),
        );
        return;
      }

      // 2) Construire la liste cart
      final cartItems = panier
          .map((p) => {
                'id_produit': p['id_produit'],
                'quantite': p['quantite'],
              })
          .toList();

      // 3) Appel à l'API confirmCart
      final response = await http.post(
        Uri.parse('http://localhost:3002/api/cart/confirmCart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'cart': cartItems,
        }),
      );

      if (response.statusCode == 200) {
        // OK : On affiche un message puis on va sur la page "Merci"
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Commande validée !")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouPage()),
        );
      } else {
        // Erreur côté serveur
        final errorBody = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $errorBody")),
        );
      }
    } catch (e) {
      // Erreur (réseau, JSON, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double totalPanier = _calculateTotal();

    return Scaffold(
      appBar: AppBar(title: const Text("Confirmation du panier")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Récapitulatif de votre panier :",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Liste des produits
            Expanded(
              child: ListView.builder(
                itemCount: panier.length,
                itemBuilder: (context, index) {
                  final produit = panier[index];
                  final double prix =
                      double.tryParse(produit['prix'].toString()) ?? 0.0;
                  final int quantite = produit['quantite'] ?? 1;

                  return ListTile(
                    title: Text(produit['nom']),
                    subtitle: Text('$prix € • Qté : $quantite'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Afficher le total
            Text(
              "Total : $totalPanier €",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _confirmerCommande(context),
              icon: const Icon(Icons.payment),
              label: const Text("Payer / Confirmer"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
