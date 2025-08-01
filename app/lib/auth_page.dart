import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_login.dart'; // Tela de Login
import 'tela_menu_principal.dart'; // Importa o arquivo main para acessar a MyHomePage

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
            return const TelaMenuPrincipal();
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