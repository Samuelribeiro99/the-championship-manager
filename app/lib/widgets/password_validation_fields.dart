import 'package:flutter/material.dart';

// Este é um widget reutilizável para os campos de senha e suas validações.
class PasswordValidationFields extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const PasswordValidationFields({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<PasswordValidationFields> createState() => _PasswordValidationFieldsState();
}

class _PasswordValidationFieldsState extends State<PasswordValidationFields> {
  bool _tem8Caracteres = false;
  bool _temLetraMaiuscula = false;
  bool _temNumero = false;
  bool _temCaractereEspecial = false;
  bool _senhasConferem = true;
  bool _novaSenhaObscura = true;
  bool _confirmarSenhaObscura = true;

  @override
  void initState() {
    super.initState();
    widget.passwordController.addListener(_validarSenhaEmTempoReal);
    widget.confirmPasswordController.addListener(_validarConfirmacaoSenha);
  }

  @override
  void dispose() {
    widget.passwordController.removeListener(_validarSenhaEmTempoReal);
    widget.confirmPasswordController.removeListener(_validarConfirmacaoSenha);
    super.dispose();
  }

  void _validarSenhaEmTempoReal() {
    final password = widget.passwordController.text;
    setState(() {
      _tem8Caracteres = password.length >= 8;
      _temLetraMaiuscula = password.contains(RegExp(r'[A-Z]'));
      _temNumero = password.contains(RegExp(r'[0-9]'));
      _temCaractereEspecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _senhasConferem = password == widget.confirmPasswordController.text;
    });
  }

  void _validarConfirmacaoSenha() {
    setState(() {
      _senhasConferem = widget.passwordController.text == widget.confirmPasswordController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool todosRequisitosAtendidos = _tem8Caracteres && _temLetraMaiuscula && _temNumero && _temCaractereEspecial;

    return Column(
      children: [
        TextField(
          controller: widget.passwordController,
          obscureText: _novaSenhaObscura, // Usa a variável de estado
          decoration: InputDecoration(
            labelText: 'Senha', // Ajustado para ser mais genérico
            // Adiciona o ícone de olho aqui
            suffixIcon: IconButton(
              icon: Icon(
                _novaSenhaObscura ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _novaSenhaObscura = !_novaSenhaObscura;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.passwordController.text.isNotEmpty && !todosRequisitosAtendidos)
          _buildRequisitosSenha(),
        
        TextField(
          controller: widget.confirmPasswordController,
          obscureText: _confirmarSenhaObscura, // Usa a variável de estado
          decoration: InputDecoration(
            labelText: 'Confirmar senha',
            // Adiciona o ícone de olho aqui também
            suffixIcon: IconButton(
              icon: Icon(
                _confirmarSenhaObscura ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _confirmarSenhaObscura = !_confirmarSenhaObscura;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.confirmPasswordController.text.isNotEmpty)
          _buildLinhaRequisito('As senhas devem ser iguais', _senhasConferem),
      ],
    );
  }

  // Widgets auxiliares para a UI de validação
  Widget _buildRequisitosSenha() {
    // ... (código do _buildRequisitosSenha de tela_cadastro.dart)
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
          // --- AJUSTE AQUI: Trocamos SvgPicture.asset por Image.asset ---
          Image.asset(
            // A lógica para escolher o arquivo continua a mesma
            atendido
                ? 'assets/icons/vai_colorido.png' // <<< Use seu arquivo .png aqui
                : 'assets/icons/cartao_amarelo.png', // <<< Use seu arquivo .png aqui

            width: 20, // Define a largura e altura da imagem
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(
              // A cor do texto pode continuar mudando dinamicamente
              color: atendido ? Colors.green : Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}