// Em lib/models/campeonato_models.dart

class JogadorNaClassificacao {
  final String nome;
  int pontos = 0;
  int jogos = 0;
  int vitorias = 0;
  int empates = 0;
  int derrotas = 0;
  int golsPro = 0;
  int golsContra = 0;
  double? posicaoSorteio;

  JogadorNaClassificacao({required this.nome});

  int get saldoDeGols => golsPro - golsContra;
}

class Partida {
  final String id;
  final int rodada;
  final String jogador1;
  final String jogador2;
  int? placar1;
  int? placar2;
  bool finalizada = false;

  Partida({
    required this.id,
    required this.rodada,
    required this.jogador1,
    required this.jogador2
  });
}