import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'tela_principal_campeonato.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/campeonato_models.dart';

class TelaAdicionarJogadores extends StatefulWidget {
  final String nomeDoCampeonato;
  final ModoCampeonato modo;

  const TelaAdicionarJogadores({
    super.key,
    required this.modo,
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

  /// Gera uma lista de partidas estruturada em rodadas (algoritmo Round-robin)
  List<Partida> _gerarPartidasPorRodada(List<String> jogadores) {
    List<String> jogadoresParaSorteio = List.from(jogadores);
    List<Partida> partidasGeradas = [];

    // Se o número de jogadores for ímpar, adiciona um "jogador fantasma" para o cálculo
    if (jogadoresParaSorteio.length % 2 != 0) {
      jogadoresParaSorteio.add("Fantasma");
    }

    int numRodadas = jogadoresParaSorteio.length - 1;
    int jogadoresPorRodada = jogadoresParaSorteio.length ~/ 2;

    for (int rodada = 0; rodada < numRodadas; rodada++) {
      for (int i = 0; i < jogadoresPorRodada; i++) {
        String jogador1 = jogadoresParaSorteio[i];
        String jogador2 = jogadoresParaSorteio[jogadoresParaSorteio.length - 1 - i];

        // Adiciona a partida apenas se não envolver o jogador fantasma
        if (jogador1 != "Fantasma" && jogador2 != "Fantasma") {
          // Embaralha quem joga em casa ou fora para ser mais justo
          if (i % 2 == 1) {
            partidasGeradas.add(Partida(
              id: '',
              rodada: rodada + 1,
              jogador1: jogador1,
              jogador2: jogador2
            ));
          } else {
            partidasGeradas.add(Partida(id: '', rodada: rodada + 1, jogador1: jogador2, jogador2: jogador1));
          }
        }
      }
      // Gira a lista de jogadores para a próxima rodada, mantendo o primeiro fixo
      String ultimoJogador = jogadoresParaSorteio.removeLast();
      jogadoresParaSorteio.insert(1, ultimoJogador);
    }
    return partidasGeradas;
  }

  Future<void> _avancar() async {
    FocusScope.of(context).unfocus();

    // Validações de número de jogadores
    if (_jogadores.length < 4) {
      _mostrarPopupAlerta('É necessário adicionar pelo menos 4 jogadores.');
      return;
    }
    if (_jogadores.length > 32) {
      _mostrarPopupAlerta('O número máximo de jogadores é 32.');
      return;
    }

    // --- LÓGICA DE SALVAR NO FIREBASE ---
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Cria o documento principal do campeonato no Firestore
      DocumentReference campeonatoRef = await FirebaseFirestore.instance.collection('campeonatos').add({
        'nome': widget.nomeDoCampeonato,
        'nome_lowercase': widget.nomeDoCampeonato.toLowerCase(),
        'idCriador': user.uid,
        'status': 'ativo',
        'criadoEm': FieldValue.serverTimestamp(),
        'modo': widget.modo.toString(),
        'jogadores': _jogadores.map((nome) => {'nome': nome}).toList(),
      });

      // 2. Lógica para gerar e salvar as partidas na subcoleção
      List<Partida> partidasGeradas = _gerarPartidasPorRodada(_jogadores);

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var partida in partidasGeradas) {
        DocumentReference partidaRef = campeonatoRef.collection('partidas').doc();
        batch.set(partidaRef, {
          'rodada': partida.rodada, // <<< SALVA O NÚMERO DA RODADA
          'jogador1': partida.jogador1,
          'jogador2': partida.jogador2,
          'placar1': null,
          'placar2': null,
          'finalizada': false,
        });
      }
      await batch.commit();

      // 3. Navega para a tela principal, AGORA PASSANDO O ID
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => TelaPrincipalCampeonato(
              campeonatoId: campeonatoRef.id,
              nomeDoCampeonato: widget.nomeDoCampeonato,
              jogadores: _jogadores,
              modo: widget.modo,
            ),
          ),
          (route) => route.isFirst, // <<< A condição para parar de remover
        );
      }

    } catch (e) {
      _mostrarPopupAlerta('Ocorreu um erro ao criar o campeonato: $e');
    }
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
            child: Text('Adicionar jogadores', style: AppTextStyles.screenTitle),
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
                        maxLength: 25, // Limite para o nome do jogador
                        decoration: const InputDecoration(
                          labelText: 'Nome do Jogador',
                          counterText: "", // Esconde o contador
                        ),
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