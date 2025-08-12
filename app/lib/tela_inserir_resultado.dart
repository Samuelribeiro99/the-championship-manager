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
  bool _loading = false;

  Future<void> _finalizarPartida() async {
    final placar1 = _placar1Key.currentState?.placarAtual;
    final placar2 = _placar2Key.currentState?.placarAtual;
    if (placar1 == null || placar2 == null) return;

    setState(() { _loading = true; });

    try {
      // Verificação de internet antes de prosseguir
      final temConexao = await _verificarConexaoFirebase();
      if (!temConexao) {
        _mostrarPopupAlerta('Não foi possível se conectar ao nosso serviço. Verifique sua conexão com a internet.');
        return; // O finally abaixo cuidará de desativar o loading
      }
      final campeonatoRef = FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId);
      final campeonatoSnapshot = await campeonatoRef.get();
      final dadosCampeonato = campeonatoSnapshot.data();
      if (dadosCampeonato == null) throw Exception('Campeonato não encontrado.');

      List<JogadorNaClassificacao> classificacaoAtual;
      if (dadosCampeonato.containsKey('classificacao') && dadosCampeonato['classificacao'] != null) {
        classificacaoAtual = (dadosCampeonato['classificacao'] as List).map((dadosJogador) {
          final j = JogadorNaClassificacao(nome: dadosJogador['nome']);
          j.pontos = dadosJogador['pontos'] ?? 0;
          j.jogos = dadosJogador['jogos'] ?? 0;
          j.vitorias = dadosJogador['vitorias'] ?? 0;
          j.empates = dadosJogador['empates'] ?? 0;
          j.derrotas = dadosJogador['derrotas'] ?? 0;
          j.golsPro = dadosJogador['golsPro'] ?? 0;
          j.golsContra = dadosJogador['golsContra'] ?? 0;
          j.posicaoSorteio = (dadosJogador['posicaoSorteio'] as num?)?.toDouble();
          return j;
        }).toList();
      } else {
        classificacaoAtual = (dadosCampeonato['jogadores'] as List)
            .map((j) => JogadorNaClassificacao(nome: j['nome']))
            .toList();
      }
      final jogador1 = classificacaoAtual.firstWhere((j) => j.nome == widget.partida.jogador1);
      final jogador2 = classificacaoAtual.firstWhere((j) => j.nome == widget.partida.jogador2);

    // --- LÓGICA CORRIGIDA PARA REVERTER RESULTADO ANTIGO (SE FOR EDIÇÃO) ---
      if (widget.partida.finalizada) {
        // Se a partida já estava finalizada, estamos editando.
        // Primeiro, desfazemos os status antigos.
        jogador1.jogos--;
        jogador2.jogos--;
        jogador1.golsPro -= widget.partida.placar1!;
        jogador1.golsContra -= widget.partida.placar2!;
        jogador2.golsPro -= widget.partida.placar2!;
        jogador2.golsContra -= widget.partida.placar1!;

        if (widget.partida.placar1! > widget.partida.placar2!) { // Vitória antiga do Jogador 1
          jogador1.pontos -= 3;
          jogador1.vitorias--;
          jogador2.derrotas--;
        } else if (widget.partida.placar2! > widget.partida.placar1!) { // Vitória antiga do Jogador 2
          jogador2.pontos -= 3;
          jogador2.vitorias--;
          jogador1.derrotas--;
        } else { // Empate antigo
          jogador1.pontos -= 1;
          jogador2.pontos -= 1;
          jogador1.empates--;
          jogador2.empates--;
        }
      }
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

      final partidasNaoFinalizadasSnapshot = await campeonatoRef
      .collection('partidas')
      .where('finalizada', isEqualTo: false)
      .get();

      final bool isUltimaPartida = partidasNaoFinalizadasSnapshot.docs.where((doc) => doc.id != widget.partida.id).isEmpty;

      List<Partida> todasAsPartidas = [];
        if (isUltimaPartida) {
          final partidaAtualAtualizada = Partida(id: widget.partida.id, rodada: widget.partida.rodada, jogador1: widget.partida.jogador1, jogador2: widget.partida.jogador2)
            ..placar1 = placar1
            ..placar2 = placar2
            ..finalizada = true;

          final outrasPartidasSnapshot = await campeonatoRef.collection('partidas').get();
          todasAsPartidas = outrasPartidasSnapshot.docs.map((doc) {
            if (doc.id == widget.partida.id) return partidaAtualAtualizada; // Usa nossa versão atualizada
            final dados = doc.data();
            return Partida(id: doc.id, rodada: dados['rodada'], jogador1: dados['jogador1'], jogador2: dados['jogador2'])
              ..placar1 = dados['placar1']
              ..placar2 = dados['placar2'];
          }).toList();
        }

      classificacaoAtual.sort((a, b) {
        // Critério 1: Pontos
        int compPontos = b.pontos.compareTo(a.pontos);
        if (compPontos != 0) return compPontos;

        // Critério 2: Vitórias
        int compVitorias = b.vitorias.compareTo(a.vitorias);
        if (compVitorias != 0) return compVitorias;

        // Critério 3: Saldo de Gols
        int compSG = b.saldoDeGols.compareTo(a.saldoDeGols);
        if (compSG != 0) return compSG;

        // Critério 4: Gols Pró
        int compGP = b.golsPro.compareTo(a.golsPro);
        if (compGP != 0) return compGP;

        // --- CRITÉRIOS DA ÚLTIMA PARTIDA ---
        if (isUltimaPartida) {
          // Critério 5: Confronto Direto
          Partida? confrontoDireto;
          try {
            confrontoDireto = todasAsPartidas.firstWhere(
              (p) => (p.jogador1 == a.nome && p.jogador2 == b.nome) || (p.jogador1 == b.nome && p.jogador2 == a.nome)
            );
          } catch (e) {
            confrontoDireto = null;
          }
          if (confrontoDireto != null && confrontoDireto.placar1 != null) {
            if (confrontoDireto.jogador1 == a.nome) {
              if (confrontoDireto.placar1! > confrontoDireto.placar2!) return -1;
              if (confrontoDireto.placar1! < confrontoDireto.placar2!) return 1;
            } else {
              if (confrontoDireto.placar1! > confrontoDireto.placar2!) return 1;
              if (confrontoDireto.placar1! < confrontoDireto.placar2!) return -1;
            }
          }

          // Critério 6: Sorteio (persistente)
          a.posicaoSorteio ??= Random().nextDouble();
          b.posicaoSorteio ??= Random().nextDouble();
          return b.posicaoSorteio!.compareTo(a.posicaoSorteio!);
        }
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
        'posicaoSorteio': j.posicaoSorteio,
      }).toList();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.update(campeonatoRef, {'classificacao': novaClassificacaoParaSalvar});

      // Atualiza a partida na subcoleção
      DocumentReference partidaRef = campeonatoRef.collection('partidas').doc(widget.partida.id);
      batch.update(partidaRef, {'placar1': placar1, 'placar2': placar2, 'finalizada': true});
      if (isUltimaPartida) {
        // Lista de troféus disponíveis
        final listaDeTrofeus = [
          'assets/trofeus/trofeu1.png',
          'assets/trofeus/trofeu2.png',
          'assets/trofeus/trofeu3.png',
          'assets/trofeus/trofeu4.png',
          'assets/trofeus/trofeu5.png',
          'assets/trofeus/trofeu6.png',
          'assets/trofeus/trofeu7.png',
        ];
        final trofeuUrlSorteado = listaDeTrofeus[Random().nextInt(listaDeTrofeus.length)];
        batch.update(campeonatoRef, {
          'status': 'finalizado',
          'trofeuUrl': trofeuUrlSorteado,
        });
      }
          
      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        _mostrarPopupAlerta('Ocorreu um erro: $e');
      }
    } finally {
      // 4. Garante que o estado de carregamento seja desativado, não importa o que aconteça
      if (mounted) {
        setState(() { _loading = false; });
      }
    }
  }
  // Adicionamos a função de verificar conexão aqui
  Future<bool> _verificarConexaoFirebase() async {
    try {
      await FirebaseFirestore.instance
          .collection('connectivityCheck')
          .doc('check')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  // Adicionamos a função de pop-up de alerta aqui
  Future<void> _mostrarPopupAlerta(String mensagem) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(mensagem),
        actions: [ TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')) ],
      ),
    );
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
                      placarInicial: widget.partida.placar1,
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
                      placarInicial: widget.partida.placar2,
                    ),
                  ),
                  const SizedBox(height: 70),
                  OutlinedButton(
                    onPressed: _loading ? null : _finalizarPartida,
                    style: OutlinedButton.styleFrom().copyWith(
                      fixedSize: WidgetStateProperty.all(const Size(200, 50)), 
                    ),
                    child: _loading
                    ? CircularProgressIndicator(color: AppColors.borderYellow)
                    : Row(
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