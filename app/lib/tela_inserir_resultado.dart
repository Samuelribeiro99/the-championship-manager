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
    // 1. Pega os placares dos widgets filhos
    final placar1 = _placar1Key.currentState?.placarAtual;
    final placar2 = _placar2Key.currentState?.placarAtual;

    if (placar1 == null || placar2 == null) return;

    // 2. Lógica de atualização da classificação (ex: Pontos Corridos)
    //    Em um app de produção, essa lógica ficaria em um "service" ou "controller"
    //    para ser reutilizada em diferentes modos de jogo.

    // Pega o documento do campeonato
    final campeonatoRef = FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId);
    final campeonatoSnapshot = await campeonatoRef.get();
    final dadosCampeonato = campeonatoSnapshot.data();
    if (dadosCampeonato == null) return;

    // Converte os dados da classificação para nossa classe modelo
    List<JogadorNaClassificacao> classificacaoAtual = (dadosCampeonato['jogadores'] as List)
        .map((j) => JogadorNaClassificacao(nome: j['nome']))
        .toList();
    
    // Encontra os jogadores da partida na lista de classificação
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

    if (placar1 > placar2) { // Vitória do Jogador 1
      jogador1.pontos += 3;
      jogador1.vitorias++;
      jogador2.derrotas++;
    } else if (placar2 > placar1) { // Vitória do Jogador 2
      jogador2.pontos += 3;
      jogador2.vitorias++;
      jogador1.derrotas++;
    } else { // Empate
      jogador1.pontos += 1;
      jogador2.pontos += 1;
      jogador1.empates++;
      jogador2.empates++;
    }

    // Ordena a classificação
    classificacaoAtual.sort((a, b) => b.pontos.compareTo(a.pontos));
    
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


    // 3. Salva os dados no Firestore
    WriteBatch batch = FirebaseFirestore.instance.batch();
    
    // Atualiza a classificação no documento principal
    batch.update(campeonatoRef, {'classificacao': novaClassificacaoParaSalvar});

    // Atualiza a partida na subcoleção
    // TODO: Precisaremos de um ID para a partida
    // DocumentReference partidaRef = campeonatoRef.collection('partidas').doc(widget.partida.id);
    // batch.update(partidaRef, {'placar1': placar1, 'placar2': placar2, 'finalizada': true});
    
    await batch.commit();

    // 4. Volta para a tela principal
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