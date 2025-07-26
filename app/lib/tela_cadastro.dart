import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    // Validação final antes de enviar
    if (!_tem8Caracteres || !_temLetraMaiuscula || !_temNumero || !_temCaractereEspecial) {
      _exibirAlerta('A senha não atende a todos os requisitos.');
      return;
    }
    if (!_senhasConferem) {
      _exibirAlerta('As senhas não conferem.');
      return;
    }

    setState(() { _loading = true; });
    
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) _exibirAlerta('Usuário cadastrado com sucesso!', success: true);
    } on FirebaseAuthException catch (e) {
      if (mounted) _exibirAlerta('Erro ao cadastrar: ${e.message}');
    } finally {
      if (mounted) setState(() { _loading = false; });
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
    // NOVO: Verifica se todos os requisitos da senha foram atendidos
    bool todosRequisitosAtendidos = _tem8Caracteres && _temLetraMaiuscula && _temNumero && _temCaractereEspecial;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Fecha a tela de cadastro e volta para a de login
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Cadastre-se'),
      ),
      body: SingleChildScrollView( // Evita que o teclado cubra os campos
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              
              // NOVO: Renderização condicional da lista de requisitos
              if (_passwordController.text.isNotEmpty && !todosRequisitosAtendidos)
                _buildRequisitosSenha(),
              
              TextField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirmar Senha', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 8),

              // NOVO: Renderização condicional da mensagem de erro de confirmação
              if (_confirmPasswordController.text.isNotEmpty)
                _buildLinhaRequisito('As senhas devem ser iguais', _senhasConferem),            
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _cadastrar,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('CADASTRAR'),
              )
            ],
          ),
        ),
      ),
    );
  }

  // NOVO: Widget para construir a lista de requisitos
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

  // NOVO: Widget para construir cada linha de requisito
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
            style: TextStyle(
              color: atendido ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}