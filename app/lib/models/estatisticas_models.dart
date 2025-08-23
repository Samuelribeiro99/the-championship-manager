// Em lib/models/estatisticas_models.dart

class EstatisticasJogador {
  final String nome;
  int totalJogos = 0;
  int totalVitorias = 0;
  int totalEmpates = 0;
  int totalDerrotas = 0;
  int totalGolsPro = 0;
  int totalGolsContra = 0;
  int totalPontos = 0;

  EstatisticasJogador({required this.nome});

  // Calcula o aproveitamento em porcentagem
  double get aproveitamento {
    if (totalJogos == 0) return 0.0;
    // Fórmula: (pontos ganhos / pontos possíveis) * 100
    return (totalPontos / (totalJogos * 3)) * 100;
  }

  // Calcula a média de gols marcados por jogo
  double get mediaGolsPro {
    if (totalJogos == 0) return 0.0;
    return totalGolsPro / totalJogos;
  }

  // Calcula a média de gols sofridos por jogo
  double get mediaGolsContra {
    if (totalJogos == 0) return 0.0;
    return totalGolsContra / totalJogos;
  }
  
  // Calcula o saldo de gols
  int get saldoDeGols => totalGolsPro - totalGolsContra;
}

class CampeonatoFinalizado {
  final String nome;
  final String campeaoNome;
  final String trofeuUrl;

  CampeonatoFinalizado({
    required this.nome,
    required this.campeaoNome,
    required this.trofeuUrl,
  });
}

class RecordeGoleada {
  final String vencedor;
  final String perdedor;
  final int placarVencedor;
  final int placarPerdedor;

  RecordeGoleada({
    required this.vencedor,
    required this.perdedor,
    required this.placarVencedor,
    required this.placarPerdedor,
  });

  int get saldoDeGols => placarVencedor - placarPerdedor;
}

class EstatisticasRecordes {
  final RecordeGoleada? maiorGoleada;
  final EstatisticasJogador? melhorAtaque;
  final EstatisticasJogador? melhorDefesa;
  final MapEntry<String, int>? maiorCampeao;
  final EstatisticasJogador? maiorVitorioso;

  EstatisticasRecordes({
    this.maiorGoleada,
    this.melhorAtaque,
    this.melhorDefesa,
    this.maiorCampeao,
    this.maiorVitorioso,
  });
}

class EstatisticasPatos {
  final RecordeGoleada? piorGoleadaSofrida;
  final MapEntry<String, int>? maiorLanterna; // Jogador e número de últimos lugares
  final EstatisticasJogador? piorAtaque;
  final EstatisticasJogador? maiorPerdedor;
  final EstatisticasJogador? piorDefesa;

  EstatisticasPatos({
    this.piorGoleadaSofrida,
    this.maiorLanterna,
    this.piorAtaque,
    this.maiorPerdedor,
    this.piorDefesa,
  });
}

class ConfrontoDiretoStats {
  final String jogador1;
  final String jogador2;

  int vitoriasJogador1 = 0;
  int vitoriasJogador2 = 0;
  int empates = 0;
  int golsJogador1 = 0;
  int golsJogador2 = 0;

  ConfrontoDiretoStats({required this.jogador1, required this.jogador2});

  int get totalPartidas => vitoriasJogador1 + vitoriasJogador2 + empates;
}