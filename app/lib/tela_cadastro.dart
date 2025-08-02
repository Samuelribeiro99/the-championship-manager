import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';

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

  // NOVO: Estado para os requisitos da senha
  bool _tem8Caracteres = false;
  bool _temLetraMaiuscula = false;
  bool _temNumero = false;
  bool _temCaractereEspecial = false;
  bool _senhasConferem = true; // Começa como verdadeiro para não mostrar erro

  @override
  void initState() {
    super.initState();
    // NOVO: Adiciona "ouvintes" para os campos de senha
    _passwordController.addListener(_validarSenhaEmTempoReal);
    _confirmPasswordController.addListener(_validarConfirmacaoSenha);
  }

  @override
  void dispose() {
    // NOVO: Remove os "ouvintes" para evitar vazamento de memória
    _passwordController.removeListener(_validarSenhaEmTempoReal);
    _confirmPasswordController.removeListener(_validarConfirmacaoSenha);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Funções de Validação em Tempo Real ---

  void _validarSenhaEmTempoReal() {
    final password = _passwordController.text;
    setState(() {
      _tem8Caracteres = password.length >= 8;
      _temLetraMaiuscula = password.contains(RegExp(r'[A-Z]'));
      _temNumero = password.contains(RegExp(r'[0-9]'));
      _temCaractereEspecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      // Também valida a confirmação caso a senha principal mude
      _senhasConferem = password == _confirmPasswordController.text;
    });
  }

  void _validarConfirmacaoSenha() {
    setState(() {
      _senhasConferem = _passwordController.text == _confirmPasswordController.text;
    });
  }

  // --- Lógica de Cadastro ---

  Future<void> _cadastrar() async {
    // --- Validação local (continua a mesma) ---
    final String password = _passwordController.text;
    if (!_tem8Caracteres || !_temLetraMaiuscula || !_temNumero || !_temCaractereEspecial) {
      _exibirAlerta('A senha não atende a todos os requisitos.');
      return;
    }
    if (!_senhasConferem) {
      _exibirAlerta('As senhas não conferem.');
      return;
    }
    // --- Fim da validação ---

    setState(() { _loading = true; });

    try {
      final String email = _emailController.text.trim();

      // Esta linha cria o usuário E JÁ FAZ O LOGIN automaticamente
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
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
        setState(() {
          _loading = false;
        });
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
    bool todosRequisitosAtendidos = _tem8Caracteres && _temLetraMaiuscula && _temNumero && _temCaractereEspecial;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // A estrutura principal agora é um Stack, dentro do nosso BackgroundScaffold
    return BackgroundScaffold(
      body: Stack(
        children: [
          // --- ITEM 1: TÍTULO "CADASTRE-SE" POSICIONADO LIVREMENTE NO TOPO ---
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: const Text(
              'Cadastre-se',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
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
                    const SizedBox(height: 120),

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
                    const SizedBox(height: 16),
                    
                    if (_passwordController.text.isNotEmpty && !todosRequisitosAtendidos)
                      _buildRequisitosSenha(),
                    
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirmar Senha'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),

                    if (_confirmPasswordController.text.isNotEmpty)
                      _buildLinhaRequisito('As senhas devem ser iguais', _senhasConferem),
                    
                    const SizedBox(height: 32),
                    
                    // Converti seu ElevatedButton para um OutlinedButton para manter o estilo
                    Center(
                      child: OutlinedButton(
                        onPressed: _loading ? null : _cadastrar,
                        style: OutlinedButton.styleFrom().copyWith(
                          minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                        ),
                        child: _loading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('CADASTRAR'),
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
            bottom: isKeyboardVisible ? 20 : 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg', // <<< Apenas muda o ícone
              onPressed: () => Navigator.of(context).pop(), // <<< E a ação
            ),
          ),
        ],
      ),
    );
  }

  // Seus widgets auxiliares continuam os mesmos
  Widget _buildRequisitosSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLinhaRequisito('Pelo menos 8 caracteres', _tem8Caracteres),
        _buildLinhaRequisito('Pelo menos 1 letra maiúscula', _temLetraMaiuscula),
        _buildLinhaRequisito('Pelo menos 1 número', _temNumero),
        _buildLinhaRequisito('Pelo menos 1 caractere especial', _temCaractereEspecial),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLinhaRequisito(String texto, bool atendido) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            atendido ? Icons.check_circle : Icons.remove_circle_outline,
            color: atendido ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(color: atendido ? Colors.green : Colors.grey),
          ),
        ],
      ),
    );
  }
}