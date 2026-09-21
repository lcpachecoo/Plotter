import 'package:flutter/material.dart';

/// Campo de texto padronizado, reutilizado em todos os formulários de
/// entrada de dados da aplicação (login, cadastro de talhão, novo registro).
///
/// Além do visual comum, padroniza o comportamento de acessibilidade:
/// rótulo sempre visível (nunca apenas um placeholder), indicação textual de
/// campo obrigatório, dica de preenchimento lida por leitores de tela e
/// encadeamento do foco entre os campos pelo teclado.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;

  /// Texto de apoio exibido abaixo do campo (formato esperado, unidade...).
  final String? ajuda;
  final IconData? icon;

  /// Componente exibido no fim do campo (ex.: botão de mostrar/ocultar
  /// senha). Mantém o alvo de toque dentro do próprio campo.
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  /// Marca o campo como obrigatório: acrescenta "*" ao rótulo e informa o
  /// leitor de tela, em vez de deixar o usuário descobrir só ao validar.
  final bool obrigatorio;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<String>? autofillHints;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.ajuda,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.controller,
    this.validator,
    this.obrigatorio = false,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
    this.autofocus = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: obrigatorio ? '$label, campo obrigatório' : label,
      hint: ajuda,
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        onChanged: onChanged,
        autofillHints: autofillHints,
        validator: validator,
        style: Theme.of(context).textTheme.bodyLarge,
        // A mensagem de erro aparece assim que o usuário interage com o
        // campo já preenchido incorretamente, e não apenas ao enviar.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: obrigatorio ? '$label *' : label,
          hintText: hint,
          helperText: ajuda,
          prefixIcon: icon != null ? Icon(icon) : null,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
