import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'tela_reautenticacao.dart';
import 'package:app/theme/text_styles.dart';

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
      titulo: 'Confirmar logoff',
      mensagem: 'Você tem certeza que deseja sair?',
    );

    if (confirmar == true && mounted) {
      await FirebaseAuth.instance.signOut();
      // O AuthPage cuidará de levar para a tela de login
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _excluirConta() async {
    // 1. Navega para a tela de reautenticação e espera um resultado
    final bool? reautenticado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const TelaReautenticacao()),
    );

    // 2. Se a reautenticação foi bem-sucedida (retornou 'true')...
    if (reautenticado == true && mounted) {
      // 3. ...mostra o pop-up final de confirmação.
      final confirmarExclusao = await _mostrarPopupConfirmacao(
        titulo: 'Excluir conta permanentemente?',
        mensagem: 'ATENÇÃO: Esta ação é irreversível. Todos os seus campeonatos e dados serão perdidos para sempre.',
        textoConfirmar: 'Sim, excluir',
      );

      // 4. Se o usuário confirmar no pop-up...
      if (confirmarExclusao == true && mounted) {
        try {
          // 5. ...exclui a conta.
          await FirebaseAuth.instance.currentUser?.delete();
          // E remove todas as telas da pilha para voltar ao login.
          Navigator.of(context).popUntil((route) => route.isFirst);
        } on FirebaseAuthException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir conta: ${e.message}'), backgroundColor: Colors.red),
          );
        }
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
              style: AppTextStyles.screenTitle,
            ),
          ),

          // Conteúdo Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 150), // Espaço para o título não sobrepor
                  // --- LISTA DE BOTÕES NO TOPO ---
                  SelectionButton(
                    text: 'Trocar senha',
                    svgAsset: 'assets/icons/senha.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaTrocarSenha()));
                    },
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Trocar e-mail',
                    svgAsset: 'assets/icons/email.svg',
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
                    text: 'Excluir conta',
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