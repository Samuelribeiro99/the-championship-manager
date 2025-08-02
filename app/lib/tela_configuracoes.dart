import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart'; // Ajuste o caminho
import 'package:app/widgets/selection_button.dart'; // Ajuste o caminho
import 'package:app/widgets/square_icon_button.dart';

// Importe as telas que vamos usar
import 'tela_trocar_senha.dart';
import 'tela_trocar_email.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {

  // --- Lógica para os Pop-ups e Ações ---

  Future<void> _fazerLogoff() async {
    final confirmar = await _mostrarPopupConfirmacao(
      titulo: 'Confirmar Logoff',
      mensagem: 'Você tem certeza que deseja sair?',
    );

    if (confirmar == true && mounted) {
      await FirebaseAuth.instance.signOut();
      // O AuthPage cuidará de levar para a tela de login
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _excluirConta() async {
    final confirmar = await _mostrarPopupConfirmacao(
      titulo: 'Excluir Conta',
      mensagem: 'ATENÇÃO: Esta ação é irreversível. Todos os seus dados serão perdidos. Deseja continuar?',
      textoConfirmar: 'EXCLUIR',
    );

    if (confirmar == true && mounted) {
      try {
        await FirebaseAuth.instance.currentUser?.delete();
        // O AuthPage cuidará de levar para a tela de login
      } on FirebaseAuthException catch (e) {
        // Para produção, é preciso tratar o erro de "re-autenticação recente"
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Widget Reutilizável para o Pop-up ---

  Future<bool?> _mostrarPopupConfirmacao({
    required String titulo,
    required String mensagem,
    String textoConfirmar = 'Confirmar',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(textoConfirmar),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          // Título da Página
          const Align(
            alignment: Alignment(0.0, -0.85),
            child: Text(
              'Configurações',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),

          // Conteúdo Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 120), // Espaço para o título não sobrepor

                  // --- LISTA DE BOTÕES NO TOPO ---
                  SelectionButton(
                    text: 'Trocar Senha',
                    svgAsset: 'assets/icons/editar.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaTrocarSenha()));
                    },
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Trocar Email',
                    svgAsset: 'assets/icons/editar.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaTrocarEmail()));
                    },
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Logoff',
                    svgAsset: 'assets/icons/logoff.svg',
                    onPressed: _fazerLogoff,
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Excluir Conta',
                    svgAsset: 'assets/icons/lixeira.svg',
                    onPressed: _excluirConta,
                  ),

                  // O Spacer empurra o conteúdo acima para o topo
                  const Spacer(),
                ],
              ),
            ),
          ),

          // --- BOTÃO DE VOLTAR NO CANTO INFERIOR ESQUERDO ---
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}