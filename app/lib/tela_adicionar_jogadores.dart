import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'tela_principal_campeonato.dart';
import 'package:app/widgets/selection_button.dart';

class TelaAdicionarJogadores extends StatefulWidget {
  final String nomeDoCampeonato;

  const TelaAdicionarJogadores({
    super.key,
    required this.nomeDoCampeonato,
  });

  @override
  State<TelaAdicionarJogadores> createState() => _TelaAdicionarJogadoresState();
}

class _TelaAdicionarJogadoresState extends State<TelaAdicionarJogadores> {
  final _nomeJogadorController = TextEditingController();
  final List<String> _jogadores = [];

  @override
  void dispose() {
    _nomeJogadorController.dispose();
    super.dispose();
  }

  // --- LÓGICA DA TELA ---

  void _adicionarJogador() {
    final nome = _nomeJogadorController.text.trim();
    
    if (nome.isEmpty) {
      _mostrarPopupAlerta('Por favor, insira o nome do jogador.');
      return;
    }

    if (_jogadores.any((jogador) => jogador.toLowerCase() == nome.toLowerCase())) {
      _mostrarPopupAlerta('Este jogador já foi adicionado.');
      return;
    }

    setState(() {
      _jogadores.add(nome);
      _nomeJogadorController.clear();
    });
  }

  void _removerJogador(int index) async {
    final confirmar = await _mostrarPopupConfirmacao(
      titulo: 'Remover Jogador',
      mensagem: 'Tem certeza que deseja remover "${_jogadores[index]}"?',
    );
    if (confirmar == true) {
      setState(() {
        _jogadores.removeAt(index);
      });
    }
  }

  void _avancar() {
    FocusScope.of(context).unfocus();

    if (_jogadores.length < 4) {
      _mostrarPopupAlerta('É necessário adicionar pelo menos 4 jogadores.');
      return;
    }
    if (_jogadores.length > 32) {
      _mostrarPopupAlerta('O número máximo de jogadores é 32.');
      return;
    }

    Navigator.push(context, MaterialPageRoute(
      builder: (context) => TelaPrincipalCampeonato(
        nomeDoCampeonato: widget.nomeDoCampeonato,
        jogadores: _jogadores,
      ),
    ));
  }

  // --- WIDGETS AUXILIARES ---

  Future<void> _mostrarPopupAlerta(String mensagem) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _mostrarPopupConfirmacao({required String titulo, required String mensagem}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      resizeToAvoidBottomInset: false, 
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Adicionar Jogadores', style: AppTextStyles.screenTitle),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 120, 24, 140),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nomeJogadorController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Jogador'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SquareIconButton(
                      svgAsset: 'assets/icons/adicionar.svg',
                      onPressed: _adicionarJogador,
                      size: 60,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _jogadores.length,
                    itemBuilder: (context, index) {
                      final jogador = _jogadores[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: SelectionButton(
                          text: jogador, // O nome do jogador
                          svgAsset: 'assets/icons/lixeira.svg',
                          onPressed: () => _removerJogador(index),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
          Positioned(
            right: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/check.svg',
              onPressed: _avancar,
            ),
          ),
        ],
      ),
    );
  }
}