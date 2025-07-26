import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_login.dart'; // Tela de Login
import 'main.dart'; // Importa o arquivo main para acessar a MyHomePage

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Ouve as mudanças no estado de autenticação do Firebase
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Se o usuário estiver logado, mostra a tela principal
          if (snapshot.hasData) {
            // ATENÇÃO: Substitua 'MyHomePage' pela sua tela principal quando a tiver
            return const MyHomePage(title: 'Página Principal');
          }
          // Se não, mostra a tela de login
          else {
            return const TelaLogin();
          }
        },
      ),
    );
  }
}