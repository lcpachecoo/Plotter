import 'package:flutter/material.dart';

/// Campo de texto padronizado, reutilizado em todos os formulários de
/// entrada de dados da aplicação (login, cadastro de talhão, novo registro).
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
