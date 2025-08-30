import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/password_validation_fields.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/utils/connectivity_utils.dart';
import 'package:app/utils/popup_utils.dart';
import 'tela_reset_senha.dart';

class TelaTrocarSenha extends StatefulWidget {
  const TelaTrocarSenha({super.key});

  @override
  State<TelaTrocarSenha> createState() => _TelaTrocarSenhaState();
}

class _TelaTrocarSenhaState extends State<TelaTrocarSenha> {
  final _senhaAntigaController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarNovaSenhaController = TextEditingController();

  bool _senhaAntigaObscura = true;

  @override
  void initState() {
    super.initState();
    // Adiciona um listener para reconstruir a tela quando o texto mudar
    _senhaAntigaController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _senhaAntigaController.dispose();
    _novaSenhaController.dispose();
    _confirmarNovaSenhaController.dispose();
    super.dispose();
  }

  void _irParaTelaReset() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaResetSenha()),
    );
  }

  Future<void> _salvarNovaSenha() async {
    FocusScope.of(context).unfocus();
    
    // Validação final antes de continuar
    if (_novaSenhaController.text != _confirmarNovaSenhaController.text) {
      mostrarPopupAlerta(context, 'A nova senha e a confirmação não são iguais.');
      return;
    }

    if (_senhaAntigaController.text.trim().isEmpty ||
        _novaSenhaController.text.trim().isEmpty ||
        _confirmarNovaSenhaController.text.trim().isEmpty) {
      mostrarPopupAlerta(context, 'Todos os campos devem ser preenchidos.');
      return;
    }

    await executarComVerificacaoDeInternet(
      context,
      acao: () async {
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
            Navigator.of(context).pop(); // Fecha o loading

            // USA 'await' PARA ESPERAR O USUÁRIO FECHAR O POP-UP
            await mostrarPopupAlerta(context, 'Senha alterada com sucesso!');
            
            // SÓ DEPOIS de o pop-up ser fechado, fecha a tela de Trocar Senha
            if (mounted) { // Verificação extra de 'mounted' é uma boa prática após um 'await'
              Navigator.of(context).pop();
            }
          }
        } on FirebaseAuthException catch (e) {
          // --- AQUI CAPTURAMOS OS ERROS ESPECÍFICOS DO FIREBASE ---
          
          // Primeiro, garantimos que o loading seja fechado
          if (mounted) Navigator.of(context).pop();

          // Agora, mostramos a mensagem customizada
          String mensagemErro = 'Ocorreu um erro.';
          if (e.code == 'weak-password') {
            mensagemErro = 'A nova senha é muito fraca.';
          } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            mensagemErro = 'A senha antiga está incorreta.';
            if (mounted) {
              // --- AQUI ESTÁ A MUDANÇA ---
              mostrarPopupAlerta(
                context,
                mensagemErro,
                acoesExtras: [
                  TextButton(
                    child: const Text('Esqueceu a senha?'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Fecha o alerta
                      _irParaTelaReset();
                    },
                  ),
                ],
              );
            }
          } else if (e.code == 'weak-password') {
            mensagemErro = 'A nova senha é muito fraca.';
            if (mounted) mostrarPopupAlerta(context, mensagemErro);
          } else {
            mensagemErro = e.message ?? mensagemErro;
            if (mounted) mostrarPopupAlerta(context, mensagemErro);
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
            alignment: Alignment(0.0, -0.85),
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
                    const SizedBox(height: 130),
                    TextField(
                      controller: _senhaAntigaController,
                      obscureText: _senhaAntigaObscura,
                      decoration: InputDecoration(
                        labelText: 'Senha antiga',
                        // *** LÓGICA CONDICIONAL DO SUFIXO ***
                        suffixIcon: _senhaAntigaController.text.isEmpty
                            ? TextButton(
                                onPressed: _irParaTelaReset,
                                child: const Text('Esqueceu?'),
                              )
                            : IconButton(
                                icon: Icon(
                                  _senhaAntigaObscura ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _senhaAntigaObscura = !_senhaAntigaObscura;
                                  });
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- USANDO NOSSO WIDGET REUTILIZÁVEL ---
                    PasswordValidationFields(
                      passwordController: _novaSenhaController,
                      confirmPasswordController: _confirmarNovaSenhaController,
                    ),
                    // ------------------------------------------

                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton(
                        onPressed: _salvarNovaSenha,
                        style: OutlinedButton.styleFrom().copyWith(
                          minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                        ),
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
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