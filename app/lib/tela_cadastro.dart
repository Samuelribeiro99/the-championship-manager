import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/password_validation_fields.dart';
import 'package:app/utils/validators.dart';
import 'package:app/theme/text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/utils/popup_utils.dart';

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
    FocusScope.of(context).unfocus();
    
    // Validações locais (continuam as mesmas)
    final String? erroEmail = Validators.validateEmail(_emailController.text.trim());
    if (erroEmail != null) {
      mostrarPopupAlerta(context, erroEmail);
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      mostrarPopupAlerta(context, 'As senhas não conferem.');
      return;
    }

    setState(() { _loading = true; });

    try {
      final temConexao = await _verificarConexaoFirebase();
      if (!temConexao) {
        mostrarPopupAlerta(context, 'Não foi possível se conectar ao nosso serviço. Verifique sua conexão com a internet.');
        return; // O finally cuidará de desativar o loading
      }
      
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- ADICIONE ESTA NAVEGAÇÃO DE VOLTA ---
      // Se o cadastro deu certo, o AuthPage já trocou a tela por baixo.
      // Esta linha remove as telas de login/cadastro da pilha para revelar a tela principal.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro ao cadastrar.';
      if (e.code == 'weak-password') {
        mensagemErro = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        mensagemErro = 'Este e-mail já está em uso por outra conta.';
      } else {
        mensagemErro = e.message ?? mensagemErro;
      }
      if (mounted) mostrarPopupAlerta(context, mensagemErro);
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  // Função local para verificar a conexão, já que não estamos usando o assistente
  Future<bool> _verificarConexaoFirebase() async {
    try {
      await FirebaseFirestore.instance
          .collection('connectivityCheck')
          .doc('check')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
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
                            ? CircularProgressIndicator(color: AppColors.borderYellow) 
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