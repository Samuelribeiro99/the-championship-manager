import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tela_cadastro.dart'; // Importa a tela de cadastro para navegação
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/theme/app_colors.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() { _loading = true; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // A navegação para a tela principal será feita automaticamente
      // pelo nosso "Gerenciador de Autenticação" (Parte 3)
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }

  void _irParaTelaCadastro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TelaCadastro()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Agora não passamos mais uma AppBar para o nosso layout de fundo
    return BackgroundScaffold(
      body: Stack(
        children: [
          // --- ITEM 1: O CONTEÚDO PRINCIPAL (CAMPOS E BOTÕES) ---
          // Colocamos o conteúdo principal dentro de um SafeArea para evitar
          // que ele fique atrás da barra de status do celular.
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
                    decoration: const InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: OutlinedButton(
                      onPressed: _loading ? null : _login,
                      style: OutlinedButton.styleFrom().copyWith(
                        minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                      ),
                      child: _loading 
                          ? CircularProgressIndicator(color: AppColors.borderYellow) 
                          : const Text('ENTRAR'),
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
                    child: const Text('CADASTRE-SE'),
                  ),
                ],
              ),
            ),
          ),

          // --- ITEM 2: O TÍTULO "LOGIN" POSICIONADO LIVREMENTE ---
          // O Align nos permite posicionar seu filho dentro do Stack.
          Align(
            // Alignment(x, y): x=-1.0 (esquerda), x=1.0 (direita)
            //                  y=-1.0 (topo),    y=1.0 (fundo)
            alignment: const Alignment(-0.0, -0.85), // Centralizado horizontalmente, um pouco abaixo do topo
            child: const Text(
              'Login',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}