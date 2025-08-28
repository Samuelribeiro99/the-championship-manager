import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/utils/popup_utils.dart';

class TelaVerificarEmail extends StatefulWidget {
  const TelaVerificarEmail({super.key});

  @override
  State<TelaVerificarEmail> createState() => _TelaVerificarEmailState();
}

class _TelaVerificarEmailState extends State<TelaVerificarEmail> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Inicia um timer para verificar o status do e-mail periodicamente
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  Future<void> _checkEmailVerified() async {
    // Recarrega os dados do usuário do Firebase para pegar o status mais recente
    await FirebaseAuth.instance.currentUser?.reload();

    final isVerified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;

    if (isVerified) {
      _timer?.cancel();
      // O AuthPage irá detectar a mudança e navegar automaticamente.
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser!.sendEmailVerification();
      if (mounted) {
        mostrarPopupAlerta(context, 'Um novo link de verificação foi enviado para o seu e-mail. Verifique sua caixa de entrada e spam.');
      }
    } catch (e) {
      if (mounted) {
        mostrarPopupAlerta(context, 'Ocorreu um erro ao reenviar o e-mail: $e');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Verifique seu E-mail',
                style: AppTextStyles.screenTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'Enviamos um link de confirmação para ${FirebaseAuth.instance.currentUser?.email}. Por favor, verifique sua caixa de entrada e spam.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: _resendVerificationEmail,
                style: OutlinedButton.styleFrom().copyWith(
                  minimumSize: WidgetStateProperty.all(const Size(200, 50)),
                ),
                child: const Text('Reenviar E-mail'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
