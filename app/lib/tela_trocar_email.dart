import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/utils/validators.dart';
import 'tela_reautenticacao.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/utils/connectivity_utils.dart';
import 'package:app/utils/popup_utils.dart';

class TelaTrocarEmail extends StatefulWidget {
  const TelaTrocarEmail({super.key});

  @override
  State<TelaTrocarEmail> createState() => _TelaTrocarEmailState();
}

class _TelaTrocarEmailState extends State<TelaTrocarEmail> {
  final _emailNovoController = TextEditingController();
  final _emailAntigoController = TextEditingController();

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
      mostrarPopupAlerta(context, erroEmail);
      return;
    }

    await executarComVerificacaoDeInternet(
      context,
      acao: () async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuário não encontrado.');

      // 2. Segurança: Navega para a tela de reautenticação
      final bool? reautenticado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const TelaReautenticacao()),
      );

          // Se a reautenticação foi bem-sucedida...
          if (reautenticado == true && mounted) {
            // Tenta atualizar o e-mail.
            await user.verifyBeforeUpdateEmail(_emailNovoController.text.trim());
            
            // Fecha o loading que o assistente abriu
            Navigator.of(context).pop();
            // Mostra o alerta de sucesso
            await mostrarPopupAlerta(context, 'Link de verificação enviado para o seu novo e-mail! Por favor, confirme a alteração.');
            // Fecha a tela de troca de e-mail
            if (mounted) Navigator.of(context).pop();
          } else {
            // Se o usuário cancelou a reautenticação, apenas fecha o loading
            if (mounted) Navigator.of(context).pop();
          }
        } on FirebaseAuthException catch (e) {
          // Garante que o loading seja fechado antes de mostrar o erro
          if (mounted) Navigator.of(context).pop();
          
          String mensagemErro = 'Ocorreu um erro.';
          if (e.code == 'email-already-in-use') {
            mensagemErro = 'Este e-mail já está sendo utilizado por outra conta.';
          } else {
            mensagemErro = e.message ?? mensagemErro;
          }
          if (mounted) mostrarPopupAlerta(context, mensagemErro);
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
                        onPressed: _salvarNovoEmail, 
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