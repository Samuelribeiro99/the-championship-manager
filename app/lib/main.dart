import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_page.dart';
import 'package:app/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Championship Manager', // Você pode alterar o título aqui
      
      // --- INÍCIO DA MUDANÇA DO TEMA ---
      theme: ThemeData(
        // Ponto de partida para um tema escuro, com fontes claras por padrão
        brightness: Brightness.dark, 
        
        // Cor de destaque (opcional, pode ajustar)
        primarySwatch: Colors.green, 

        // Define o estilo padrão para TODAS as AppBars do seu app
        appBarTheme: const AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.white, 
            fontSize: 20, 
            fontWeight: FontWeight.bold,
          ),
        ),

        // Define o estilo padrão para TODOS os TextFields
        inputDecorationTheme: InputDecorationTheme(
          // Cor do texto do label (ex: "Email", "Senha")
          labelStyle: TextStyle(color: Colors.white70), // Um branco mais suave
          
          // Estilo da borda quando o campo não está focado
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              width: 5.0,
              color: AppColors.borderYellow,
            ), // Um branco transparente
          ),

          // Estilo da borda quando o campo está focado
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              width: 7.0,
              color: AppColors.borderYellow,
            ),
          ),
        ),

        // Define o estilo padrão para TODOS os TextButtons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white, // Cor do texto do TextButton
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.borderYellow,
            minimumSize: const Size(50, 50),
            side: const BorderSide(
              width: 5.0,
              color: AppColors.borderYellow,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ),
      home: const AuthPage(),
    );
  }
}