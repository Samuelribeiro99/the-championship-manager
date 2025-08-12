// Em lib/utils/popup_utils.dart

import 'package:flutter/material.dart';

/// Exibe um pop-up de alerta padrão (AlertDialog) com um título, uma mensagem e um botão "OK".
///
/// [context] é o BuildContext da tela que está chamando o pop-up.
/// [mensagem] é o texto que será exibido no corpo do alerta.
Future<void> mostrarPopupAlerta(BuildContext context, String mensagem) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Atenção'),
        content: Text(mensagem),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o pop-up
            },
          ),
        ],
      );
    },
  );
}

Future<bool?> mostrarPopupConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Retorna false
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true), // Retorna true
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red, // Deixa o botão de confirmação vermelho para ações perigosas
          ),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
}