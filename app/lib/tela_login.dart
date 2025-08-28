import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_cadastro.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/utils/popup_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false; 
  bool _senhaObscura = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. A FUNÇÃO _login VOLTA A TER A LÓGICA DE LOADING E TRY/CATCH
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      mostrarPopupAlerta(context, 'Por favor, preencha o e-mail e a senha.');
      return;
    }

    // Ativa o loading
    setState(() { _loading = true; });

    try {
      // Verificação de internet antes de tentar o login
      final temConexao = await _verificarConexaoFirebase();
      if (!temConexao) {
        mostrarPopupAlerta(context, 'Não foi possível se conectar ao nosso serviço. Verifique sua conexão com a internet.');
        return;
      }
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Se o login der certo, o AuthPage navega e esta tela é removida da árvore.
      // O 'finally' abaixo ainda será executado, mas não causará problemas.

    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro ao fazer login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensagemErro = 'E-mail ou senha inválidos.';
      } else {
        mensagemErro = e.message ?? mensagemErro;
      }
      if (mounted) mostrarPopupAlerta(context, mensagemErro);
    } finally {
      // Garante que o loading seja desativado, não importa o que aconteça
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  // Adicionamos a função de verificar conexão aqui, pois não estamos mais usando o assistente
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


  void _irParaTelaCadastro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TelaCadastro()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Seus TextFields e Botões continuam aqui
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _senhaObscura, // Usa a variável de estado
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      // Adiciona o ícone de olho aqui
                      suffixIcon: IconButton(
                        icon: Icon(
                          _senhaObscura ? Icons.visibility_off : Icons.visibility,
                        ),
                          onPressed: () {
                          setState(() {
                            _senhaObscura = !_senhaObscura;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton(
                      // 3. O BOTÃO AGORA USA A VARIÁVEL _loading
                      onPressed: _loading ? null : _login, // Desabilita o botão durante o loading
                      style: OutlinedButton.styleFrom().copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(150, 50)),
                      ),
                      // Mostra o indicador de progresso ou o texto
                      child: _loading
                          ? CircularProgressIndicator(color: AppColors.borderYellow)
                          : const Text('Entrar'),
                    ),
                  ),
                  const SizedBox(height: 100),
                  const Text('Não tem uma conta?'),
                  OutlinedButton(
                    onPressed: _irParaTelaCadastro,
                    style: OutlinedButton.styleFrom().copyWith(
                      // Define um tamanho fixo menor
                      minimumSize: WidgetStateProperty.all(const Size(100, 35)), 
                      // Talvez uma borda um pouco mais fina para ser mais sutil
                      side: WidgetStateProperty.all(
                        const BorderSide(
                          width: 5.0, 
                          color: AppColors.borderYellow,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Cadastre-se',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.0, -0.85), // Centralizado horizontalmente, um pouco abaixo do topo
            child: const Text(
              'Login',
              style: AppTextStyles.screenTitle,
            ),
          ),
        ],
      ),
    );
  }
}