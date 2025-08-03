import 'package:app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/password_validation_fields.dart';
import 'package:app/theme/text_styles.dart'; // Ajuste o caminho

class TelaTrocarSenha extends StatefulWidget {
  const TelaTrocarSenha({super.key});

  @override
  State<TelaTrocarSenha> createState() => _TelaTrocarSenhaState();
}

class _TelaTrocarSenhaState extends State<TelaTrocarSenha> {
  final _senhaAntigaController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _senhaAntigaController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    super.dispose();
  }

  Future<void> _salvarNovaSenha() async {
    FocusScope.of(context).unfocus();
    
    // Validação final antes de continuar
    if (_novaSenhaController.text != _confirmarNovaSenhaController.text) {
      _exibirAlerta('A nova senha e a confirmação não são iguais.');
      return;
    }

    setState(() { _loading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuário não encontrado.');
      }

      // 1. Reautentica o usuário com a senha antiga
      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: _senhaAntigaController.text.trim(),
      );
      await user.reauthenticateWithCredential(credencial);

      // 2. Se a reautenticação deu certo, atualiza para a nova senha
      await user.updatePassword(_novaSenhaController.text.trim());

      if (mounted) {
        _exibirAlerta('Senha alterada com sucesso!', success: true);
        Navigator.of(context).pop(); // Volta para a tela de configurações
      }

    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensagemErro = 'A senha antiga está incorreta.';
      } else if (e.code == 'weak-password') {
        mensagemErro = 'A nova senha é muito fraca.';
      }
      _exibirAlerta(mensagemErro);
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  void _exibirAlerta(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BackgroundScaffold(
      body: Stack(
        children: [
          const Align(
            alignment: Alignment(0.0, -0.8),
            child: Text(
              'Trocar senha',
              style: AppTextStyles.screenTitle,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 120),
                    TextField(
                      controller: _senhaAntigaController,
                      decoration: const InputDecoration(labelText: 'Senha Antiga'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),

                    // --- USANDO NOSSO WIDGET REUTILIZÁVEL ---
                    PasswordValidationFields(
                      passwordController: _novaSenhaController,
                      confirmPasswordController: _confirmarNovaSenhaController,
                    ),
                    // ------------------------------------------

                    const SizedBox(height: 32),
                    Center(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _salvarNovaSenha,
                        style: OutlinedButton.styleFrom().copyWith(
                          minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                        ),
                        child: _loading 
                            ? const CircularProgressIndicator(color: AppColors.borderYellow) 
                            : const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: isKeyboardVisible ? 8 : 60,
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