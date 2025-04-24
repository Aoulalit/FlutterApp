import 'package:flutter/material.dart';

class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar avec un bouton pour revenir à la page précédente
      appBar: AppBar(
        title: const Text('Merci !'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Ferme la page actuelle et revient à la page précédente (accueil)
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Grande icône "check" pour dire merci
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            // Message de remerciement
            const Text(
              'Merci pour votre achat !',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Petit texte ou émojis supplémentaires
            const Text(
              'Nous espérons vous revoir bientôt !',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
