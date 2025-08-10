import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/password_validation_fields.dart';
import 'package:app/utils/validators.dart';
import 'package:app/theme/text_styles.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  // --- Controladores e Estado ---
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Lógica de Cadastro ---
  Future<void> _cadastrar() async {
    // Valida email
    final String? erroEmail = Validators.validateEmail(_emailController.text.trim());
    if (erroEmail != null) {
      _exibirAlerta(erroEmail);
      return; // Para a execução se o e-mail for inválido
    }
    // Valida senha
    if (_passwordController.text != _confirmPasswordController.text) {
      _exibirAlerta('As senhas não conferem.');
      return;
    }
    // --- Fim da validação ---

    setState(() { _loading = true; });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Se o widget ainda estiver montado, faz a navegação
      if (mounted) {
        // Navega para a AuthPage (que vai mostrar a tela principal)
        // e remove todas as telas anteriores (login, cadastro) do histórico.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _exibirAlerta('Erro ao cadastrar: ${e.message}');
      }
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

  // --- Construção da Interface (UI) ---

  @override
  Widget build(BuildContext context) {

    // A estrutura principal agora é um Stack, dentro do nosso BackgroundScaffold
    return BackgroundScaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // --- ITEM 1: TÍTULO "CADASTRE-SE" POSICIONADO LIVREMENTE NO TOPO ---
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: const Text(
              'Cadastre-se',
              style: AppTextStyles.screenTitle,
            ),
          ),

          // --- ITEM 2: CONTEÚDO PRINCIPAL (O FORMULÁRIO) ---
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Espaço para não ficar atrás do título flutuante
                    const SizedBox(height: 130),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    PasswordValidationFields(
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                    ),
                    const SizedBox(height: 12),
                    
                    // Converti seu ElevatedButton para um OutlinedButton para manter o estilo
                    Center(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _cadastrar,
                        style: OutlinedButton.styleFrom().copyWith(
                          minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                        ),
                        child: _loading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Cadastrar'),
                      ),
                    ),
                    const SizedBox(height: 50), // Espaço antes do botão de voltar
                  ],
                ),
              ),
            ),
          ),

          // --- ITEM 3: BOTÃO DE VOLTAR POSICIONADO NO CANTO INFERIOR ESQUERDO ---
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg', // <<< Apenas muda o ícone
              onPressed: () => Navigator.of(context).pop(), // <<< E a ação
            ),
          ),
        ],
      ),
    );
  }
}