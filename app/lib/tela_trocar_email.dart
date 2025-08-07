import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/utils/validators.dart';
import 'tela_reautenticacao.dart';
import 'package:app/theme/text_styles.dart';

class TelaTrocarEmail extends StatefulWidget {
  const TelaTrocarEmail({super.key});

  @override
  State<TelaTrocarEmail> createState() => _TelaTrocarEmailState();
}

class _TelaTrocarEmailState extends State<TelaTrocarEmail> {
  final _emailNovoController = TextEditingController();
  final _emailAntigoController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Preenche o campo de e-mail antigo com o e-mail atual do usuário
    _emailAntigoController.text = FirebaseAuth.instance.currentUser?.email ?? '';
  }

  @override
  void dispose() {
    _emailNovoController.dispose();
    _emailAntigoController.dispose();
    super.dispose();
  }

  Future<void> _salvarNovoEmail() async {
    FocusScope.of(context).unfocus();
    
    // 1. Validação do formato do novo e-mail
    final erroEmail = Validators.validateEmail(_emailNovoController.text.trim());
    if (erroEmail != null) {
      _exibirAlerta(erroEmail);
      return;
    }

    setState(() { _loading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não encontrado.');

      // 2. Segurança: Navega para a tela de reautenticação
      final bool? reautenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const TelaReautenticacao()),
      );

      // 3. Se a reautenticação foi bem-sucedida...
      if (reautenticado == true && mounted) {
        // 4. ...tenta atualizar o e-mail.
        // O método verifyBeforeUpdateEmail é mais seguro, pois envia um link de confirmação.
        await user.verifyBeforeUpdateEmail(_emailNovoController.text.trim());
        
        _exibirAlerta(
          'Link de verificação enviado para o seu novo e-mail! Por favor, confirme a alteração.',
          success: true,
        );
        Navigator.of(context).pop(); // Volta para a tela de configurações
      }
    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro.';
      if (e.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está sendo utilizado por outra conta.';
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
              'Trocar e-mail',
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
                    const SizedBox(height: 150),
                    // Campo de e-mail antigo (desabilitado para edição)
                    TextField(
                      controller: _emailAntigoController,
                      enabled: false, // O usuário não pode editar o e-mail antigo
                      decoration: const InputDecoration(labelText: 'E-mail atual'),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailNovoController,
                      decoration: const InputDecoration(labelText: 'Novo e-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _salvarNovoEmail,
                        style: OutlinedButton.styleFrom().copyWith(
                          minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                        ),
                        child: _loading 
                            ? const CircularProgressIndicator(color: Colors.white) 
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