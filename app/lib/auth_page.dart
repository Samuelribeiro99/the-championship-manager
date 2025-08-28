import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_login.dart';
import 'tela_menu_principal.dart';
import 'tela_verificar_email.dart'; // Importa a nova tela

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Ouve as mudanças no estado de autenticação do Firebase
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Se o usuário está logado...
          if (snapshot.hasData) {
            // ...verifica se o e-mail foi confirmado.
            return snapshot.data!.emailVerified
                ? const TelaMenuPrincipal() // Se sim, vai para o menu.
                : const TelaVerificarEmail(); // Se não, vai para a tela de verificação.
          } 
          // Se não está logado, mostra a tela de login.
          else {
            return const TelaLogin();
          }
        },
      ),
    );
  }
}