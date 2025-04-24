import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'confirmation_page.dart';

class Panier extends StatefulWidget {
  const Panier({super.key});

  @override
  _PanierState createState() => _PanierState();
}

class _PanierState extends State<Panier> {
  List<dynamic> panier = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchPanier();
  }

  /// Récupère le panier depuis l'API et agrège les lignes par id_produit
  Future<void> fetchPanier() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        // Pas connecté => panier vide
        setState(() {
          panier = [];
          _isLoading = false;
        });
        return;
      }

      // Requête GET /getCart
      final response = await http.get(
        Uri.parse(
            'http://localhost:3002/api/cart/getCart?id_utilisateur=$userId'),
      );

      if (response.statusCode == 200) {
        // On regroupe les lignes par id_produit pour éviter les doublons
        final rawData = json.decode(response.body);
        final Map<int, Map<String, dynamic>> aggregator = {};
        print(rawData);
        for (var line in rawData) {
          final idProd = line['id_produit'];
          if (!aggregator.containsKey(idProd)) {
            aggregator[idProd] = {...line};
          } else {
            aggregator[idProd]!['quantite'] += line['quantite'];
          }
        }

        setState(() {
          panier = aggregator.values.toList();
        });
      } else {
        throw Exception("Erreur lors de la récupération du panier.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Supprime complètement le produit (quelle que soit la quantité)
  Future<void> supprimerDuPanier(int idProduit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) return;

      final response = await http.delete(
        Uri.parse(
          'http://localhost:3002/api/cart/removeFromCart?id_utilisateur=$userId&id_produit=$idProduit',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          panier.removeWhere((item) => item['id_produit'] == idProduit);
        });
      } else {
        throw Exception("Erreur lors de la suppression du produit.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  /// Met à jour la quantité (incrément/décrément).
  /// Si la quantité devient 0 => on supprime le produit.
  Future<void> updateQuantity(int idProduit, int nouvelleQuantite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) return;

      // PATCH /updateQuantity (à implémenter côté serveur)
      final response = await http.patch(
        Uri.parse('http://localhost:3002/api/cart/updateQuantity'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_utilisateur': userId,
          'id_produit': idProduit,
          'nouvelleQuantite': nouvelleQuantite,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          // Mise à jour locale
          for (var item in panier) {
            if (item['id_produit'] == idProduit) {
              item['quantite'] = nouvelleQuantite;
              break;
            }
          }
          // Si la quantité devient 0, on retire l'élément
          panier.removeWhere((item) => item['quantite'] == 0);
        });
      } else {
        final errorBody = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur maj quantité: $errorBody")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  void _validerPanier() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationPage(panier: panier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : panier.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket,
                          size: 50, color: Colors.orange),
                      SizedBox(height: 20),
                      Text('Votre panier est vide.',
                          style: TextStyle(fontSize: 18)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: panier.length,
                  itemBuilder: (context, index) {
                    final produit = panier[index];

                    // Méthodes pour + et -
                    void decrementerQuantite() {
                      final nouvelleQte = (produit['quantite'] as int) - 1;
                      updateQuantity(produit['id_produit'], nouvelleQte);
                    }

                    void incrementerQuantite() {
                      final nouvelleQte = (produit['quantite'] as int) + 1;
                      updateQuantity(produit['id_produit'], nouvelleQte);
                    }

                    void supprimerProduit() {
                      supprimerDuPanier(produit['id_produit']);
                    }

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: Image.network(
                          produit['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        ),
                        title: Text(produit['nom']),
                        subtitle: Text(
                            '${produit['prix']} € • Qté : ${produit['quantite']}'),
                        // On résout l'overflow en plaçant nos boutons dans un FittedBox
                        trailing: FittedBox(
                          child: Row(
                            children: [
                              // Bouton "–" (décrément)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.red),
                                onPressed: decrementerQuantite,
                              ),
                              // Bouton "X" (supprime complètement)
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: supprimerProduit,
                              ),
                              // Bouton "+" (incrémente)
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Colors.green),
                                onPressed: incrementerQuantite,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: panier.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _validerPanier,
              label: const Text("Valider le panier"),
              icon: const Icon(Icons.check),
              backgroundColor: Colors.orange,
            )
          : null,
    );
  }
}
