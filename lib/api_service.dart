import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:3002/api";
  
  static Future<Map<String, dynamic>> login(String email, String motdepasse) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'motdepasse': motdepasse,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur de connexion');
    }
  }

  // Récupérer la liste des produits
  static Future<List<dynamic>> getProduits() async {
    final response = await http.get(Uri.parse('$baseUrl/products/'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors du chargement des produits");
    }
  }

  // Récupérer les infos d'un utilisateur par ID
  static Future<Map<String, dynamic>> getUser(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/utilisateur?id=$id'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Utilisateur introuvable");
    }
  }

  // Mettre à jour les informations d'un utilisateur
  static Future<void> updateUser(int id, String email, String? password) async {
    final response = await http.put(
      Uri.parse('$baseUrl/edit'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "id": id,
        "email": email,
        "motdepasse": password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la mise à jour");
    }
  }

  // Changer le mot de passe d'un utilisateur
  static Future<void> changePassword(String email, String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/changePassword'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "email": email,
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors du changement de mot de passe");
    }
  }

  // Récupérer tous les utilisateurs
  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors de la récupération des utilisateurs");
    }
  }


  // 🔥 Récupérer le panier d'un utilisateur
  static Future<List<dynamic>> getPanier(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/cart/getCart?id_utilisateur=$userId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Erreur lors du chargement du panier");
    }
  }

  // 🔥 Supprimer un produit du panier
  static Future<bool> supprimerDuPanier(int userId, int idProduit) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/removeFromCart?id_utilisateur=$userId&id_produit=$idProduit'),
    );

    return response.statusCode == 200;
  }

  // 🔥 Mettre à jour la quantité d'un produit dans le panier
  static Future<bool> updateQuantity(int userId, int idProduit, int nouvelleQuantite) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/cart/updateQuantity'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'id_utilisateur': userId,
        'id_produit': idProduit,
        'nouvelleQuantite': nouvelleQuantite,
      }),
    );

    return response.statusCode == 200;
  }
}

