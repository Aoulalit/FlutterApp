import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_service.dart';
import 'package:diacritic/diacritic.dart';

class Achat extends StatefulWidget {
  const Achat({super.key});

  @override
  State<Achat> createState() => _AchatState();
}

class _AchatState extends State<Achat> {
  List _produits = [];
  List _produitsFiltres = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchProduits();
  }

  Future<void> fetchProduits() async {
    try {
      final data = await ApiService.getProduits();
      setState(() {
        _produits = data.where((p) => p['quantite'] > 0).toList();
        _produitsFiltres = data;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  void _filtrerProduits(String query) {
    if (query.isEmpty) {
      setState(() {
        _produitsFiltres = _produits;
      });
    } else {
      setState(() {
        _produitsFiltres = _produits
            .where((produit) => removeDiacritics(
                  produit['nom'].toString().toLowerCase(),
                ).contains(removeDiacritics(query.toLowerCase())))
            .toList();
      });
    }
  }

  void _resetRecherche() {
    _searchController.clear();
    _filtrerProduits('');
  }

  void _trierAZ() {
    setState(() {
      _produitsFiltres.sort((a, b) {
        final nameA = removeDiacritics(a['nom'].toString().toLowerCase());
        final nameB = removeDiacritics(b['nom'].toString().toLowerCase());
        return nameA.compareTo(nameB);
      });
    });
  }

  void _trierZA() {
    setState(() {
      _produitsFiltres.sort((a, b) {
        final nameA = removeDiacritics(a['nom'].toString().toLowerCase());
        final nameB = removeDiacritics(b['nom'].toString().toLowerCase());
        return nameB.compareTo(nameA);
      });
    });
  }

  void afficherDetailsProduit(
      BuildContext context, Map<String, dynamic> produit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ProductDetailPage(produit: produit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _resetRecherche();
                }
              });
            },
          ),
          title: _isSearching
              ? Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.black),
                      border: InputBorder.none,
                    ),
                    onChanged: _filtrerProduits,
                  ),
                )
              : const Text('Achat'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.dehaze),
              onSelected: (value) {
                if (value == 'az') {
                  _trierAZ();
                } else if (value == 'za') {
                  _trierZA();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'az', child: Text('Trier A-Z')),
                const PopupMenuItem(value: 'za', child: Text('Trier Z-A')),
              ],
            ),
          ],
        ),
        body: _produitsFiltres.isEmpty
            ? const Center(child: Text("Aucun produit trouvé"))
            : GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: _produitsFiltres.length,
                itemBuilder: (context, index) {
                  final produit = _produitsFiltres[index];
                  return InkWell(
                    onTap: () => afficherDetailsProduit(context, produit),
                    borderRadius: BorderRadius.circular(15),
                    child: Card(
                      color: Colors.white,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/ecran.png',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              produit['nom'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${produit['prix']} €',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: produit['quantite'] > 0
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                produit['quantite'] > 0
                                    ? 'Disponible'
                                    : 'Indisponible',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: produit['quantite'] > 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ));
  }
}

class _ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> produit;

  const _ProductDetailPage({required this.produit});

  Future<void> ajouterAuPanier(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Veuillez vous connecter pour ajouter au panier.")),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:3002/api/cart/addToCart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id_utilisateur': userId,
          'id_produit': produit['id_produit'],
          'quantite': 1,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Image.asset('assets/images/ecran.png', height: 30, width: 30),
                const SizedBox(width: 10),
                Expanded(child: Text("${produit['nom']} ajouté au panier !")),
              ],
            ),
          ),
        );
      } else {
        throw Exception(
            "Erreur lors de l'ajout au panier (code ${response.statusCode}).");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(produit['nom']), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, 8)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Image.asset(
                      'assets/images/ecran.png',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          produit['nom'],
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${produit['prix']} €',
                          style: const TextStyle(
                              fontSize: 22, color: Colors.green),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          produit['caracteristique'],
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: produit['quantite'] > 0
                                ? () => ajouterAuPanier(context)
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            const Text("Produit indisponible"),
                                        content: const Text(
                                            "Ce produit est actuellement en rupture de stock."),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("OK"),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text("Ajouter au panier"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: produit['quantite'] > 0
                                  ? Colors.orange
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
