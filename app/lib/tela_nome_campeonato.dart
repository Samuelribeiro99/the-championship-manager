import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'tela_adicionar_jogadores.dart';
import 'package:app/theme/text_styles.dart';

class TelaNomeCampeonato extends StatefulWidget {
  const TelaNomeCampeonato({super.key});

  @override
  State<TelaNomeCampeonato> createState() => _TelaNomeCampeonatoState();
}

class _TelaNomeCampeonatoState extends State<TelaNomeCampeonato> {
  final _nomeController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _avancarParaAdicionarJogadores() {
    FocusScope.of(context).unfocus(); // Recolhe o teclado

    final nomeCampeonato = _nomeController.text.trim();

    // Validação simples para não deixar o nome em branco
    if (nomeCampeonato.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, dê um nome ao campeonato.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navega para a próxima tela, passando o nome do campeonato
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaAdicionarJogadores(
          nomeDoCampeonato: nomeCampeonato,
        ),
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
            alignment: Alignment(0.0, -0.7),
            child: Text(
              'Nome do campeonato',
              style: AppTextStyles.screenTitle,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Digite o nome aqui'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),
          
          // --- BOTÕES DE NAVEGAÇÃO ---
          Positioned(
            left: 20,
            bottom: isKeyboardVisible ? 20 : 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: 20,
            bottom: isKeyboardVisible ? 20 : 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/check.svg', // <<< SEU ÍCONE DE CONFIRMAR
              onPressed: _avancarParaAdicionarJogadores,
            ),
          ),
        ],
      ),
    );
  }
}