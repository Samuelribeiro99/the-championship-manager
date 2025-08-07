import 'package:app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/match_result_selection.dart';
import 'package:app/theme/text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'tela_cronometro.dart';
import 'dart:math';

class TelaInserirResultado extends StatefulWidget {
  final String campeonatoId;
  final Partida partida;

  const TelaInserirResultado({
    super.key,
    required this.campeonatoId,
    required this.partida,
  });

  @override
  State<TelaInserirResultado> createState() => _TelaInserirResultadoState();
}

class _TelaInserirResultadoState extends State<TelaInserirResultado> {
  // Chaves para acessar o estado dos widgets de placar
  final _placar1Key = GlobalKey<PlacarJogadorWidgetState>();
  final _placar2Key = GlobalKey<PlacarJogadorWidgetState>();

  Future<void> _finalizarPartida() async {
    final placar1 = _placar1Key.currentState?.placarAtual;
    final placar2 = _placar2Key.currentState?.placarAtual;
    if (placar1 == null || placar2 == null) return;

    final campeonatoRef = FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId);
    final campeonatoSnapshot = await campeonatoRef.get();
    final dadosCampeonato = campeonatoSnapshot.data();
    if (dadosCampeonato == null) return;

    List<JogadorNaClassificacao> classificacaoAtual;

    // Verifica se o campo 'classificacao' já existe no banco
    if (dadosCampeonato.containsKey('classificacao') && dadosCampeonato['classificacao'] != null) {
      // Se sim (não é a primeira partida), carrega os dados salvos
      classificacaoAtual = (dadosCampeonato['classificacao'] as List).map((dadosJogador) {
        final j = JogadorNaClassificacao(nome: dadosJogador['nome']);
        j.pontos = dadosJogador['pontos'] ?? 0;
        j.jogos = dadosJogador['jogos'] ?? 0;
        j.vitorias = dadosJogador['vitorias'] ?? 0;
        j.empates = dadosJogador['empates'] ?? 0;
        j.derrotas = dadosJogador['derrotas'] ?? 0;
        j.golsPro = dadosJogador['golsPro'] ?? 0;
        j.golsContra = dadosJogador['golsContra'] ?? 0;
        return j;
      }).toList();
    } else {
      // Se não (é a primeira partida), cria a classificação do zero a partir da lista de 'jogadores'
      classificacaoAtual = (dadosCampeonato['jogadores'] as List)
          .map((j) => JogadorNaClassificacao(nome: j['nome']))
          .toList();
    }
    final jogador1 = classificacaoAtual.firstWhere((j) => j.nome == widget.partida.jogador1);
    final jogador2 = classificacaoAtual.firstWhere((j) => j.nome == widget.partida.jogador2);

    // TODO: Adicionar lógica para reverter o resultado antigo se estiver editando

    // Aplica o novo resultado
    jogador1.jogos++;
    jogador2.jogos++;
    jogador1.golsPro += placar1;
    jogador1.golsContra += placar2;
    jogador2.golsPro += placar2;
    jogador2.golsContra += placar1;

    if (placar1 > placar2) {
      jogador1.pontos += 3;
      jogador1.vitorias++;
      jogador2.derrotas++;
    } else if (placar2 > placar1) {
      jogador2.pontos += 3;
      jogador2.vitorias++;
      jogador1.derrotas++;
    } else {
      jogador1.pontos += 1;
      jogador2.pontos += 1;
      jogador1.empates++;
      jogador2.empates++;
    }

    // Ordena a classificação por pontos e depois por saldo de gols
    classificacaoAtual.sort((a, b) {
      // Critério 1: Mais Pontos
      int comparacaoPontos = b.pontos.compareTo(a.pontos);
      if (comparacaoPontos != 0) return comparacaoPontos;

      // Critério 2: Maior Saldo de Gols (SG)
      int comparacaoSG = b.saldoDeGols.compareTo(a.saldoDeGols);
      if (comparacaoSG != 0) return comparacaoSG;

      // Critério 3: Mais Gols Pró (GP) - Gols Marcados
      int comparacaoGP = b.golsPro.compareTo(a.golsPro);
      if (comparacaoGP != 0) return comparacaoGP;

      // Se tudo continuar empatado, por enquanto mantém a ordem
      return 0;
    });
    
    // Converte de volta para um formato que o Firestore entende (Map)
    final novaClassificacaoParaSalvar = classificacaoAtual.map((j) => {
      'nome': j.nome,
      'pontos': j.pontos,
      'jogos': j.jogos,
      'vitorias': j.vitorias,
      'empates': j.empates,
      'derrotas': j.derrotas,
      'golsPro': j.golsPro,
      'golsContra': j.golsContra,
    }).toList();

    WriteBatch batch = FirebaseFirestore.instance.batch();

    final partidasNaoFinalizadasSnapshot = await campeonatoRef
    .collection('partidas')
    .where('finalizada', isEqualTo: false)
    .get();

    if (partidasNaoFinalizadasSnapshot.docs.length == 1) {
      // Lista de troféus disponíveis
      final listaDeTrofeus = [
        'assets/trofeus/trofeu1.png',
        'assets/trofeus/trofeu2.png',
        'assets/trofeus/trofeu3.png',
        'assets/trofeus/trofeu4.png',
        'assets/trofeus/trofeu5.png',
        'assets/trofeus/trofeu6.png',
        'assets/trofeus/trofeu7.png',
        'assets/trofeus/trofeu8.png',
      ];
      final trofeuUrlSorteado = listaDeTrofeus[Random().nextInt(listaDeTrofeus.length)];
      batch.update(campeonatoRef, {
        'status': 'finalizado',
        'trofeuUrl': trofeuUrlSorteado,
      });
    }

    batch.update(campeonatoRef, {'classificacao': novaClassificacaoParaSalvar});

    // Atualiza a partida na subcoleção
    DocumentReference partidaRef = campeonatoRef.collection('partidas').doc(widget.partida.id);
    batch.update(partidaRef, {'placar1': placar1, 'placar2': placar2, 'finalizada': true});
    
    await batch.commit();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }


  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.9),
            child: Text('Rodada ${widget.partida.rodada}', style: AppTextStyles.screenTitle),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    child: PlacarJogadorWidget(
                      key: _placar1Key,
                      nomeJogador: widget.partida.jogador1,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('X',
                      style: TextStyle(
                        fontFamily: 'PostNoBillsColombo',
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      )
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: PlacarJogadorWidget(
                      key: _placar2Key,
                      nomeJogador: widget.partida.jogador2,
                    ),
                  ),
                  const SizedBox(height: 70),
                  OutlinedButton(
                    onPressed: _finalizarPartida,
                    style: OutlinedButton.styleFrom().copyWith(
                      fixedSize: WidgetStateProperty.all(const Size(200, 50)), 
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Finalizar'),
                        const SizedBox(width: 8),
                        SvgPicture.asset(
                          'assets/icons/apito.svg',
                          height: 36,
                        ),
                      ],
                    ),
                  ),
                ],
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
              svgAsset: 'assets/icons/cronometro.svg',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TelaCronometro()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}