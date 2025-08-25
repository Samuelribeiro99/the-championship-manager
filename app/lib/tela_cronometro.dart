import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';

class TelaCronometro extends StatefulWidget {
  const TelaCronometro({super.key});

  @override
  State<TelaCronometro> createState() => _TelaCronometroState();
}

class _TelaCronometroState extends State<TelaCronometro> {
  // Variável estática para manter o tempo padrão durante a sessão do app
  static Duration _tempoPadrao = const Duration(minutes: 0);

  Timer? _timer;
  late Duration _tempoAtual;
  bool _estaRodando = false;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempoAtual = _tempoPadrao;
    // Se nenhum tempo foi definido ainda, pede para o usuário definir
    if (_tempoPadrao == Duration.zero) {
      // Pede para mostrar o dialog de edição logo após a tela ser construída
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editarTempo();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // --- LÓGICA DO TIMER ---

  void _iniciarOuPausar() {
    if (_estaRodando) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_tempoAtual.inSeconds == 0) {
          _timer?.cancel();
          _finalizarContagem();
        } else {
          setState(() {
            _tempoAtual = _tempoAtual - const Duration(seconds: 1);
          });
        }
      });
    }
    setState(() {
      _estaRodando = !_estaRodando;
    });
  }

  void _zerarCronometro() {
    _timer?.cancel();
    setState(() {
      _tempoAtual = _tempoPadrao;
      _estaRodando = false;
    });
  }

  void _finalizarContagem() async {
    // Vibra o celular
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate();
    }
    // Mostra o pop-up
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tempo esgotado!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _zerarCronometro();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    setState(() {
      _estaRodando = false;
    });
  }

  // --- LÓGICA DE EDIÇÃO DE TEMPO ---

    void _editarTempo() {
    // Formata o tempo atual para o controller
    _controller.text = _formatarDuracao(_tempoAtual);

    // Seleciona os minutos para que o usuário possa substituir facilmente
    _controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Tempo (mm:ss)'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
          keyboardType: TextInputType.number,
          inputFormatters: [
            // Usa nosso novo formatador inteligente
            _TimeInputFormatter(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Pega o texto do controller (ex: "2:00")
              String textoFinal = _controller.text;
              List<String> partes = textoFinal.split(':');

              if (partes.length == 2) {
                // Adiciona o zero à esquerda ANTES de salvar
                String minutosStr = partes[0].padLeft(2, '0');
                String segundosStr = partes[1];

                final minutos = int.tryParse(minutosStr) ?? 0;
                final segundos = int.tryParse(segundosStr) ?? 0;
                
                if (segundos > 59) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Os segundos não podem ser maiores que 59.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                setState(() {
                  _tempoPadrao = Duration(minutes: minutos, seconds: segundos);
                  _zerarCronometro();
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // --- FUNÇÕES AUXILIARES ---

  String _formatarDuracao(Duration duracao) {
    String doisDigitos(int n) => n.toString().padLeft(2, '0');
    String doisDigitosMinutos = doisDigitos(duracao.inMinutes.remainder(60));
    String doisDigitosSegundos = doisDigitos(duracao.inSeconds.remainder(60));
    return "$doisDigitosMinutos:$doisDigitosSegundos";
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Cronômetro', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 120),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- DISPLAY DO CRONÔMETRO ---
                  GestureDetector(
                    onTap: _editarTempo,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderYellow, width: 5),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Center(
                        child: Text(
                          _formatarDuracao(_tempoAtual),
                          style: AppTextStyles.screenTitle.copyWith(fontSize: 70),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- BOTÕES DE CONTROLE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SquareIconButton(
                        svgAsset: 'assets/icons/cronograma.svg', // Crie este ícone
                        onPressed: _zerarCronometro,
                        size: 80,
                      ),
                      SquareIconButton(
                        // Muda o ícone dependendo se está rodando ou não
                        svgAsset: _estaRodando ? 'assets/icons/pause.svg' : 'assets/icons/play.svg',
                        onPressed: _iniciarOuPausar,
                        size: 80,
                      ),
                    ],
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
        ],
      ),
    );
  }
}

// Classe auxiliar para formatar o input do tempo como "mm:ss"
class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Se o usuário está apagando, permite o comportamento padrão
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Pega apenas os dígitos do novo texto
    var digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    var newString = <String>[];
    int selectionIndex = 0;

    for (int i = 0; i < digitsOnly.length; i++) {
      newString.add(digitsOnly[i]);
      if (i == 1) {
        newString.add(':'); // Adiciona o ':' depois do segundo dígito
      }
    }

    final formattedText = newString.join('');
    
    // Posiciona o cursor no final
    selectionIndex = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}