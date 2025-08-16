import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/selectable_player_button.dart';
import 'package:app/theme/text_styles.dart';

class TelaJogadoresExistentes extends StatefulWidget {
  final List<String> jogadoresJaAdicionados;

  const TelaJogadoresExistentes({super.key, required this.jogadoresJaAdicionados});

  @override
  State<TelaJogadoresExistentes> createState() => _TelaJogadoresExistentesState();
}

class _TelaJogadoresExistentesState extends State<TelaJogadoresExistentes> {
  late Future<List<String>> _jogadoresUnicosFuture;
  List<String> _jogadoresSelecionados = [];

  @override
  void initState() {
    super.initState();
    _jogadoresUnicosFuture = _buscarJogadoresUnicos();
  }

  Future<List<String>> _buscarJogadoresUnicos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .get();

    if (snapshot.docs.isEmpty) return [];

    // Usa um Set para garantir que cada jogador apareça apenas uma vez
    final Set<String> jogadoresUnicos = {};
    for (var doc in snapshot.docs) {
      final dados = doc.data();
      if (dados.containsKey('jogadores')) {
        final jogadoresDoCampeonato = (dados['jogadores'] as List).map((j) => j['nome'] as String);
        jogadoresUnicos.addAll(jogadoresDoCampeonato);
      }
    }

    return jogadoresUnicos.toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _toggleSelecaoJogador(String nome) {
    setState(() {
      if (_jogadoresSelecionados.contains(nome)) {
        _jogadoresSelecionados.remove(nome);
      } else {
        _jogadoresSelecionados.add(nome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Jogadores Existentes', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 140),
              child: FutureBuilder<List<String>>(
                future: _jogadoresUnicosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum jogador encontrado em campeonatos anteriores.'));
                  }

                  final todosJogadores = snapshot.data!;
                  // Filtra os jogadores que já foram adicionados na tela anterior
                  final jogadoresParaExibir = todosJogadores
                      .where((j) => !widget.jogadoresJaAdicionados.any((ja) => ja.toLowerCase() == j.toLowerCase()))
                      .toList();

                  if (jogadoresParaExibir.isEmpty) {
                    return const Center(child: Text('Todos os jogadores existentes já foram adicionados.'));
                  }

                  return ListView.builder(
                    itemCount: jogadoresParaExibir.length,
                    itemBuilder: (context, index) {
                      final nomeJogador = jogadoresParaExibir[index];
                      final isSelected = _jogadoresSelecionados.contains(nomeJogador);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: SelectablePlayerButton(
                          text: nomeJogador,
                          isSelected: isSelected,
                          onPressed: () => _toggleSelecaoJogador(nomeJogador),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(), // Volta sem retornar nada
            ),
          ),
          Positioned(
            right: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/check.svg',
              onPressed: () {
                // Volta para a tela anterior, retornando a lista de jogadores selecionados
                Navigator.of(context).pop(_jogadoresSelecionados);
              },
            ),
          ),
        ],
      ),
    );
  }
}