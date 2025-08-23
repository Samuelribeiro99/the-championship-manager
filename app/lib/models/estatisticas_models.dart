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