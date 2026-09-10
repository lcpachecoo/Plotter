import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_shell.dart';

/// Tela inicial da aplicação: autenticação do usuário (produtor, gerente
/// ou operador de campo).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'produtor@fazenda.com');
  final _senhaController = TextEditingController(text: '••••••••');

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // Em telas largas (tablet/desktop) o formulário fica centralizado
              // e limitado em largura para não esticar demais.
              constraints: BoxConstraints(maxWidth: isWide ? 420 : double.infinity),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.grass_rounded, size: 64, color: AppTheme.primaryGreen),
                    const SizedBox(height: 12),
                    Text(
                      'Plotter',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestão de lavoura por talhões',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'E-mail',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Informe o e-mail' : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      controller: _senhaController,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(label: 'Entrar', icon: Icons.login, onPressed: _entrar),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    const Text(
                      'Perfis de acesso: Produtor, Gerente e Operador de campo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
