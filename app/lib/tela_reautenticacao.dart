import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart'; // <<< 1. IMPORTE O BOTÃO
import 'package:app/theme/text_styles.dart';

class TelaReautenticacao extends StatefulWidget {
  const TelaReautenticacao({super.key});

  @override
  State<TelaReautenticacao> createState() => _TelaReautenticacaoState();
}

class _TelaReautenticacaoState extends State<TelaReautenticacao> {
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _reautenticar() async {
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception("Usuário não encontrado ou sem email.");
      }

      final credencial = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credencial);

      if (mounted) {
        Navigator.of(context).pop(true);
      }

    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensagemErro = 'Senha incorreta. Tente novamente.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagemErro), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. DETECTA O TECLADO
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BackgroundScaffold(
      body: Stack(
        children: [
          const Align(
            alignment: Alignment(0.0, -0.7),
            child: Text(
              'Confirme sua identidade',
              textAlign: TextAlign.center,
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
                    'Para continuar, por favor, digite sua senha.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _reautenticar,
                      style: OutlinedButton.styleFrom().copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                      ),
                      child: _loading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. ADICIONA O NOVO BOTÃO DE VOLTAR NO CANTO INFERIOR ESQUERDO
          Positioned(
            left: 20,
            bottom: isKeyboardVisible ? 8 : 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(false), // Retorna 'false' se cancelar
            ),
          ),
        ],
      ),
    );
  }
}