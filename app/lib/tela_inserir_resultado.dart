import 'package:app/models/modo_campeonato.dart';
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
import 'package:app/utils/popup_utils.dart';

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
  final _placar1PenaltisKey = GlobalKey<PlacarJogadorWidgetState>();
  final _placar2PenaltisKey = GlobalKey<PlacarJogadorWidgetState>();

  bool _loading = false;
  ModoCampeonato? _modoCampeonato;
  bool _mostrarPenaltis = false;


  @override
  void initState() {
    super.initState();
    // Busca o modo do campeonato para lógicas futuras
    _fetchModoCampeonato();

    // CORREÇÃO: Mostrar pênaltis se for uma final empatada (ou ainda não jogada)
    if (widget.partida.tipo == 'final') {
      final bool isDraw = widget.partida.finalizada && widget.partida.placar1 == widget.partida.placar2;
      final bool isNotPlayed = !widget.partida.finalizada && widget.partida.placar1 == null;
      if (isDraw || isNotPlayed) {
        setState(() {
          _mostrarPenaltis = true;
        });
      }
    }
  }

  Future<void> _fetchModoCampeonato() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId).get();
      final modoString = doc.data()?['modo'];
      if (modoString != null) {
        setState(() {
          _modoCampeonato = ModoCampeonato.values.firstWhere((e) => e.toString() == modoString);
        });
      }
    } catch (e) {
      // Lida com o erro se não conseguir buscar o modo
    }
  }

  void _verificarMostrarPenaltis() {
    // Atraso mínimo para garantir que os widgets de placar tenham seus estados atualizados
    Future.delayed(const Duration(milliseconds: 100), () {
      final placar1 = _placar1Key.currentState?.placarAtual;
      final placar2 = _placar2Key.currentState?.placarAtual;
      final bool deveMostrar = widget.partida.tipo == 'final' && placar1 == placar2;

      if (deveMostrar != _mostrarPenaltis) {
        setState(() {
          _mostrarPenaltis = deveMostrar;
        });
      }
    });
  }


  Future<void> _finalizarPartida() async {
    final placar1 = _placar1Key.currentState?.placarAtual;
    final placar2 = _placar2Key.currentState?.placarAtual;
    if (placar1 == null || placar2 == null) return;

    // CORREÇÃO: Validação para não permitir finalizar uma final com empate sem pênaltis
    if (widget.partida.tipo == 'final' && placar1 == placar2) {
      final placar1Penaltis = _placar1PenaltisKey.currentState?.placarAtual;
      final placar2Penaltis = _placar2PenaltisKey.currentState?.placarAtual;
      if (placar1Penaltis == null || placar2Penaltis == null) {
        mostrarPopupAlerta(context, 'A partida final empatou. Por favor, insira o resultado dos pênaltis.');
        return;
      }
      if (placar1Penaltis == placar2Penaltis) {
        mostrarPopupAlerta(context, 'O placar dos pênaltis não pode ser um empate.');
        return;
      }
    }

    int? placar1Penaltis;
    int? placar2Penaltis;
    if (_mostrarPenaltis) {
      placar1Penaltis = _placar1PenaltisKey.currentState?.placarAtual;
      placar2Penaltis = _placar2PenaltisKey.currentState?.placarAtual;
    }

    setState(() { _loading = true; });

    try {
      // Verificação de internet antes de prosseguir
      final temConexao = await _verificarConexaoFirebase();
      if (!temConexao) {
        _mostrarPopupAlerta('Não foi possível se conectar ao nosso serviço. Verifique sua conexão com a internet.');
        return; // O finally abaixo cuidará de desativar o loading
      }
      final campeonatoRef = FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId);
      // Busca todos os dados necessários de uma vez
      final responses = await Future.wait([
        campeonatoRef.get(),
        campeonatoRef.collection('partidas').get(),
      ]);
      
      final campeonatoSnapshot = responses[0] as DocumentSnapshot;
      final todasAsPartidasSnapshot = responses[1] as QuerySnapshot;

      final dadosCampeonato = campeonatoSnapshot.data() as Map<String, dynamic>?;
      if (dadosCampeonato == null) throw Exception('Campeonato não encontrado.');

      // Pega o modo do estado ou busca novamente se ainda for nulo
      final modo = _modoCampeonato ?? ModoCampeonato.values.firstWhere((e) => e.toString() == dadosCampeonato['modo']);

      // --- LÓGICA DE ALERTA DE RESET DA FINAL ---
      bool resetarFinal = false;

      // CORREÇÃO: LÓGICA PARA PRESERVAR CAMPEÃO OU RESETAR A FINAL
      if (widget.partida.tipo == 'regular' && modo == ModoCampeonato.pontosCorridosIdaComFinal && dadosCampeonato['status'] == 'finalizado') {
          // 1. Pega os finalistas antigos
          final classificacaoAntigaRaw = (dadosCampeonato['classificacao'] as List);
          final finalistasAntigos = {classificacaoAntigaRaw[0]['nome'], classificacaoAntigaRaw[1]['nome']};

          // 2. Cria uma cópia profunda da classificação para simulação
          List<JogadorNaClassificacao> classificacaoSimulada = (dadosCampeonato['classificacao'] as List).map((dadosJogador) {
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

          // 3. Simula a mudança de resultado
          final jogador1Simulado = classificacaoSimulada.firstWhere((j) => j.nome == widget.partida.jogador1);
          final jogador2Simulado = classificacaoSimulada.firstWhere((j) => j.nome == widget.partida.jogador2);

          // Reverte o placar antigo
          if (widget.partida.finalizada) {
              jogador1Simulado.jogos--;
              jogador2Simulado.jogos--;
              jogador1Simulado.golsPro -= widget.partida.placar1!;
              jogador1Simulado.golsContra -= widget.partida.placar2!;
              jogador2Simulado.golsPro -= widget.partida.placar2!;
              jogador2Simulado.golsContra -= widget.partida.placar1!;
              if (widget.partida.placar1! > widget.partida.placar2!) {
                  jogador1Simulado.pontos -= 3;
                  jogador1Simulado.vitorias--;
                  jogador2Simulado.derrotas--;
              } else if (widget.partida.placar2! > widget.partida.placar1!) {
                  jogador2Simulado.pontos -= 3;
                  jogador2Simulado.vitorias--;
                  jogador1Simulado.derrotas--;
              } else {
                  jogador1Simulado.pontos -= 1;
                  jogador2Simulado.pontos -= 1;
                  jogador1Simulado.empates--;
                  jogador2Simulado.empates--;
              }
          }

          // Aplica o novo placar
          jogador1Simulado.jogos++;
          jogador2Simulado.jogos++;
          jogador1Simulado.golsPro += placar1;
          jogador1Simulado.golsContra += placar2;
          jogador2Simulado.golsPro += placar2;
          jogador2Simulado.golsContra += placar1;
          if (placar1 > placar2) {
              jogador1Simulado.pontos += 3;
              jogador1Simulado.vitorias++;
              jogador2Simulado.derrotas++;
          } else if (placar2 > placar1) {
              jogador2Simulado.pontos += 3;
              jogador2Simulado.vitorias++;
              jogador1Simulado.derrotas++;
          } else {
              jogador1Simulado.pontos += 1;
              jogador2Simulado.pontos += 1;
              jogador1Simulado.empates++;
              jogador2Simulado.empates++;
          }

          // 4. Reordena a classificação simulada
          classificacaoSimulada.sort((a, b) {
              int compPontos = b.pontos.compareTo(a.pontos);
              if (compPontos != 0) return compPontos;
              int compVitorias = b.vitorias.compareTo(a.vitorias);
              if (compVitorias != 0) return compVitorias;
              int compSG = b.saldoDeGols.compareTo(a.saldoDeGols);
              if (compSG != 0) return compSG;
              int compGP = b.golsPro.compareTo(a.golsPro);
              if (compGP != 0) return compGP;
              a.posicaoSorteio ??= Random().nextDouble();
              b.posicaoSorteio ??= Random().nextDouble();
              return b.posicaoSorteio!.compareTo(a.posicaoSorteio!);
          });

          // 5. Compara os finalistas
          final finalistasNovos = {classificacaoSimulada[0].nome, classificacaoSimulada[1].nome};
          
          if (finalistasAntigos.difference(finalistasNovos).isNotEmpty || finalistasNovos.difference(finalistasAntigos).isNotEmpty) {
              final confirmar = await mostrarPopupConfirmacao(
                  context,
                  titulo: 'Atenção',
                  mensagem: 'Alterar este resultado irá mudar os finalistas e resetar a partida final. Deseja continuar?',
                  textoConfirmar: 'Sim, continuar',
              );
              if (confirmar != true) {
                  setState(() { _loading = false; });
                  return;
              }
              resetarFinal = true;
          } else {
              // FINALISTAS NÃO MUDARAM: Este é o caso do bug.
              // Apenas atualizamos a partida e a classificação, sem mexer no campeão.
              WriteBatch batch = FirebaseFirestore.instance.batch();
              batch.update(campeonatoRef.collection('partidas').doc(widget.partida.id), {
                'placar1': placar1, 'placar2': placar2, 'finalizada': true,
              });
              
              final classificacaoSimuladaParaSalvar = classificacaoSimulada.map((j) => {
                'nome': j.nome, 'pontos': j.pontos, 'jogos': j.jogos, 'vitorias': j.vitorias,
                'empates': j.empates, 'derrotas': j.derrotas, 'golsPro': j.golsPro,
                'golsContra': j.golsContra, 'posicaoSorteio': j.posicaoSorteio,
              }).toList();
              batch.update(campeonatoRef, {'classificacao': classificacaoSimuladaParaSalvar});

              await batch.commit();
              if (mounted) Navigator.of(context).pop();
              return; // Sai da função para não reprocessar o campeão indevidamente.
          }
      }

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
        // Reverte os gols sempre

        jogador1.golsPro -= widget.partida.placar1!;
        jogador1.golsContra -= widget.partida.placar2!;
        jogador2.golsPro -= widget.partida.placar2!;
        jogador2.golsContra -= widget.partida.placar1!;

        // Só reverte pontos/jogos se não for a final
        if (widget.partida.tipo != 'final') {
          jogador1.jogos--;
          jogador2.jogos--;
          if (widget.partida.placar1! > widget.partida.placar2!) {
          jogador1.pontos -= 3;
          jogador1.vitorias--;
          jogador2.derrotas--;
          } else if (widget.partida.placar2! > widget.partida.placar1!) {
            jogador2.pontos -= 3;
            jogador2.vitorias--;
            jogador1.derrotas--;
          } else {
            jogador1.pontos -= 1;
            jogador2.pontos -= 1;
            jogador1.empates--;
            jogador2.empates--;
          }
        }
      }

      // Aplica os novos status
      jogador1.golsPro += placar1;
      jogador1.golsContra += placar2;
      jogador2.golsPro += placar2;
      jogador2.golsContra += placar1;

      // Só aplica pontos/jogos se não for a final
      if (widget.partida.tipo != 'final') {
        jogador1.jogos++;
        jogador2.jogos++;
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
      }

      final todasAsPartidas = todasAsPartidasSnapshot.docs.map((doc) {
        final dados = doc.data() as Map<String, dynamic>;
        return Partida(
          id: doc.id, rodada: dados['rodada'], jogador1: dados['jogador1'], jogador2: dados['jogador2'], tipo: dados['tipo'] ?? 'regular',
        )..placar1 = dados['placar1']..placar2 = dados['placar2']..finalizada = dados['finalizada'];
      }).toList();

      final indexPartidaAtual = todasAsPartidas.indexWhere((p) => p.id == widget.partida.id);
      if(indexPartidaAtual != -1) {
        todasAsPartidas[indexPartidaAtual].placar1 = placar1;
        todasAsPartidas[indexPartidaAtual].placar2 = placar2;
      }

      final partidasRegulares = todasAsPartidas.where((p) => p.tipo == 'regular').toList();

      final bool isFinal = widget.partida.tipo == 'final';
      final bool todasRegularesFinalizadas = partidasRegulares.where((p) => p.id != widget.partida.id).every((p) => p.finalizada);
      final bool isUltimaPartidaRegular = todasRegularesFinalizadas && !isFinal;


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

        // Critério 5: Confronto Direto
        if (isUltimaPartidaRegular){
          Partida? confrontoDireto;
          try {
            confrontoDireto = partidasRegulares.firstWhere(
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
        }

        // Critério 6: Sorteio (persistente)
        a.posicaoSorteio ??= Random().nextDouble();
        b.posicaoSorteio ??= Random().nextDouble();
        return b.posicaoSorteio!.compareTo(a.posicaoSorteio!);
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
      batch.update(partidaRef, {
        'placar1': placar1,
        'placar2': placar2,
        'finalizada': true,
        'placar1Penaltis': placar1Penaltis,
        'placar2Penaltis': placar2Penaltis,
      });

      if (isUltimaPartidaRegular && modo == ModoCampeonato.pontosCorridosIdaComFinal) {
          final finalDocQuery = await campeonatoRef.collection('partidas').where('tipo', isEqualTo: 'final').limit(1).get();
          if (finalDocQuery.docs.isNotEmpty) {
              final finalistas = [classificacaoAtual[0].nome, classificacaoAtual[1].nome];
              batch.update(finalDocQuery.docs.first.reference, {
                  'jogador1': finalistas[0],
                  'jogador2': finalistas[1],
              });
          }
      }

      if (isUltimaPartidaRegular || isFinal) {
        String nomeCampeao;
        if (isFinal) {
          if (placar1 > placar2) {
            nomeCampeao = widget.partida.jogador1;
          } else if (placar2 > placar1) {
            nomeCampeao = widget.partida.jogador2;
          } else { 
            nomeCampeao = ((placar1Penaltis ?? 0) > (placar2Penaltis ?? 0)) ? widget.partida.jogador1 : widget.partida.jogador2;
          }
        } else { // Pontos corridos simples
          nomeCampeao = classificacaoAtual[0].nome;
        }

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
          'campeaoNome': nomeCampeao,
        });
      }

      // Se a edição de um resultado resetou a final
      if (resetarFinal) {
          final finalDoc = await campeonatoRef.collection('partidas').where('tipo', isEqualTo: 'final').limit(1).get();
          if (finalDoc.docs.isNotEmpty) {
              batch.update(finalDoc.docs.first.reference, {
                  'jogador1': '1º Colocado',
                  'jogador2': '2º Colocado',
                  'placar1': null,
                  'placar2': null,
                  'placar1Penaltis': null,
                  'placar2Penaltis': null,
                  'finalizada': false,
              });
              batch.update(campeonatoRef, {'status': 'ativo', 'campeaoNome': null, 'trofeuUrl': null});
          }
      }
          
      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        mostrarPopupAlerta(context, 'Ocorreu um erro: $e');
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

  Widget _buildPenaltisCard() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(8),
       decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderYellow, width: 5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text('Pênaltis', style: AppTextStyles.screenTitle.copyWith(fontSize: 30)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PlacarJogadorWidget(
              key: _placar1PenaltisKey,
              nomeJogador: widget.partida.jogador1,
              placarInicial: widget.partida.placar1Penaltis,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('X', style: TextStyle(fontFamily: 'PostNoBillsColombo', fontSize: 60, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ),
          SizedBox(
            height: 200,
            child: PlacarJogadorWidget(
              key: _placar2PenaltisKey,
              nomeJogador: widget.partida.jogador2,
              placarInicial: widget.partida.placar2Penaltis,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final bool isFinal = widget.partida.tipo == 'final';
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.9),
            child: Text(isFinal ? 'Final' : 'Rodada ${widget.partida.rodada}', style: AppTextStyles.screenTitle),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 100, 16, 120),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 200,
                      child: PlacarJogadorWidget(
                        key: _placar1Key,
                        nomeJogador: widget.partida.jogador1,
                        placarInicial: widget.partida.placar1,
                        onPlacarChanged: _verificarMostrarPenaltis,
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
                        onPlacarChanged: _verificarMostrarPenaltis,
                      ),
                    ),
                    
                    if (_mostrarPenaltis) _buildPenaltisCard(),

                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _loading ? null : _finalizarPartida,
                      style: OutlinedButton.styleFrom().copyWith(
                        fixedSize: WidgetStateProperty.all(const Size(200, 50)), 
                      ),
                      child: _loading
                      ? const CircularProgressIndicator(color: AppColors.borderYellow)
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