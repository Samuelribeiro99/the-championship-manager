// Em lib/utils/validators.dart

class Validators {
  // Valida o formato do e-mail usando uma expressão regular (RegExp)
  // Retorna uma string de erro se for inválido, ou null se for válido.
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'O campo de e-mail não pode estar vazio.';
    }
    // Expressão regular para um formato de e-mail básico
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Por favor, insira um e-mail válido.';
    }
    return null; // Válido
  }
}