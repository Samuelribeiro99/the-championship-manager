import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_cadastro.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/utils/popup_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tela_reset_senha.dart';
import 'package:app/utils/validators.dart';

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
  void initState() {
    super.initState();
    // Adiciona um listener para reconstruir a tela quando o texto mudar
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _irParaTelaReset() {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TelaResetSenha()),
    );
  }

  // 2. A FUNÇÃO _login VOLTA A TER A LÓGICA DE LOADING E TRY/CATCH
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    // CORREÇÃO: Adiciona a validação de formato de e-mail
    final erroEmail = Validators.validateEmail(_emailController.text.trim());
    if (erroEmail != null) {
      mostrarPopupAlerta(context, erroEmail);
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      mostrarPopupAlerta(context, 'Por favor, preencha a senha.');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // Verificação de internet antes de tentar o login
      final temConexao = await _verificarConexaoFirebase();
      if (!temConexao) {
        mostrarPopupAlerta(context, 'Não foi possível se conectar ao nosso serviço. Verifique sua conexão com a internet.');
        return;
      }

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // *** NOVA VERIFICAÇÃO DE E-MAIL CONFIRMADO ***
      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        // Se o e-mail não foi verificado, desloga o usuário imediatamente
        await FirebaseAuth.instance.signOut();
        // E mostra um alerta
        if (mounted) {
          mostrarPopupAlerta(
            context,
            'Seu e-mail ainda não foi verificado. Por favor, clique no link que enviamos para sua caixa de entrada.',
            titulo: 'E-mail não verificado'
          );
        }
      }
      // Se o e-mail estiver verificado, o AuthPage cuidará da navegação.

    } on FirebaseAuthException catch (e) {
      String mensagemErro = 'Ocorreu um erro ao fazer login.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensagemErro = 'E-mail ou senha inválidos.';
        if (mounted) {
          // --- AQUI ESTÁ A MUDANÇA ---
          // Usa a nova função de pop-up com uma ação extra
          mostrarPopupAlerta(
            context,
            mensagemErro,
            acoesExtras: [
              TextButton(
                child: const Text('Esqueceu a senha?'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _irParaTelaReset();
                },
              ),
            ],
          );
        }
      } else {
        mensagemErro = e.message ?? mensagemErro;
        if (mounted) mostrarPopupAlerta(context, mensagemErro);
      }
    } finally {
      // Garante que o loading seja desativado, não importa o que aconteça
      if (mounted) {
        setState(() {
          _loading = false;
        });
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
                    obscureText: _senhaObscura,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      // *** LÓGICA CONDICIONAL DO SUFIXO ***
                      suffixIcon: _passwordController.text.isEmpty
                          ? TextButton(
                              onPressed: _irParaTelaReset,
                              child: const Text('Esqueceu?'),
                            )
                          : IconButton(
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
                      onPressed: _loading ? null : _login,
                      style: OutlinedButton.styleFrom().copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(150, 50)),
                      ),
                      // Mostra o indicador de progresso ou o texto
                      child: _loading
                          ? const CircularProgressIndicator(color: AppColors.borderYellow)
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
          const Align(
            alignment: Alignment(-0.0, -0.85),
            child: Text(
              'Login',
              style: AppTextStyles.screenTitle,
            ),
          ),
        ],
      ),
    );
  }
}