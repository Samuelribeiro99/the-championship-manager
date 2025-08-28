import 'package:app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'tela_confronto_direto.dart';


class TelaSelecaoConfronto extends StatefulWidget {
  const TelaSelecaoConfronto({super.key});

  @override
  State<TelaSelecaoConfronto> createState() => _TelaSelecaoConfrontoState();
}

class _TelaSelecaoConfrontoState extends State<TelaSelecaoConfronto> {
  late Future<List<String>> _jogadoresUnicosFuture;
  final List<String> _jogadoresSelecionados = [];

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
        if (_jogadoresSelecionados.length < 2) {
          _jogadoresSelecionados.add(nome);
        } else {
          // Se já tem 2, remove o primeiro e adiciona o novo
          _jogadoresSelecionados.removeAt(0);
          _jogadoresSelecionados.add(nome);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // O botão de confirmar só fica ativo quando 2 jogadores são selecionados
    final bool isConfirmarAtivo = _jogadoresSelecionados.length == 2;

    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Selecionar confronto', style: AppTextStyles.screenTitle, textAlign: TextAlign.center),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 130),
              child: FutureBuilder<List<String>>(
                future: _jogadoresUnicosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum jogador encontrado.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      )
                    );
                  }

                  final todosJogadores = snapshot.data!;

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: todosJogadores.length,
                    itemBuilder: (context, index) {
                      final nomeJogador = todosJogadores[index];
                      final isSelected = _jogadoresSelecionados.contains(nomeJogador);
                      return OutlinedButton(
                        onPressed: () => _toggleSelecaoJogador(nomeJogador),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? AppColors.borderYellow : Colors.transparent,
                        ),
                        child: Text(nomeJogador, overflow: TextOverflow.ellipsis),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/check.svg',
              // Desabilita o botão se não tiver 2 jogadores selecionados
              onPressed: isConfirmarAtivo ? () {
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => TelaConfrontoDireto(
                    jogador1: _jogadoresSelecionados[0],
                    jogador2: _jogadoresSelecionados[1],
                  ),
                ));
              } : null,
            ),
          ),
        ],
      ),
    );
  }
}
