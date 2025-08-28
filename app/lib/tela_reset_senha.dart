import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/utils/connectivity_utils.dart';
import 'package:app/utils/popup_utils.dart';
import 'package:app/utils/validators.dart';

class TelaResetSenha extends StatefulWidget {
  const TelaResetSenha({super.key});

  @override
  State<TelaResetSenha> createState() => _TelaResetSenhaState();
}

class _TelaResetSenhaState extends State<TelaResetSenha> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmailReset() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final erroEmail = Validators.validateEmail(email);
    if (erroEmail != null) {
      mostrarPopupAlerta(context, erroEmail);
      return;
    }

    await executarComVerificacaoDeInternet(
      context,
      acao: () async {
        try {
          await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

          // Sucesso
          if (mounted) {
            Navigator.of(context).pop(); // Fecha o loading
            await mostrarPopupAlerta(
              context,
              'Se este e-mail estiver cadastrado, um link para redefinição de senha foi enviado. Verifique sua caixa de entrada e spam.',
              titulo: 'Verifique seu E-mail',
            );
            if (mounted) {
              Navigator.of(context).pop(); // Volta para a tela de login
            }
          }
        } on FirebaseAuthException catch (e) {
          if (mounted) Navigator.of(context).pop(); // Fecha o loading
          
          // Mesmo em caso de erro "usuário não encontrado", mostramos a mesma mensagem de sucesso
          // para evitar que pessoas mal-intencionadas descubram quais e-mails estão cadastrados.
          if (e.code == 'user-not-found') {
             await mostrarPopupAlerta(
              context,
              'Se este e-mail estiver cadastrado, um link para redefinição de senha foi enviado. Verifique sua caixa de entrada e spam.',
              titulo: 'Verifique seu E-mail',
            );
            if (mounted) Navigator.of(context).pop();
          } else {
            mostrarPopupAlerta(context, 'Ocorreu um erro: ${e.message}');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Align(
            alignment: Alignment(0.0, -0.8),
            child: Text(
              'Redefinir Senha',
              style: AppTextStyles.screenTitle,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Digite seu e-mail cadastrado para enviarmos um link de redefinição.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton(
                      onPressed: _enviarEmailReset,
                      style: OutlinedButton.styleFrom().copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                      ),
                      child: const Text('Enviar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
