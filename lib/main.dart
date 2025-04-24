import 'package:flutter/material.dart';
import 'package:ap4/accueuil.dart';
import 'package:ap4/achat.dart';
import 'package:ap4/profil.dart';
import 'package:ap4/panier.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Achat',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  /// Le nouvel argument qui permet de choisir l'onglet au démarrage
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  // Les 4 onglets de ta BottomNavigationBar
  final List<Widget> _pages = [
    const Accueil(), // index 0
    const Achat(),   // index 1
    const Panier(),  // index 2
    const Profil(),  // index 3
  ];

  @override
  void initState() {
    super.initState();
    // On démarre sur l'onglet passé en paramètre (ou 0 par défaut)
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // On affiche la page correspondant à l'onglet sélectionné
      body: _pages[_selectedIndex],

      // Barre de navigation en bas
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Achat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}