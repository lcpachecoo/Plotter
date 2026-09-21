import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

/// Tela inicial da aplicação: autenticação do usuário (produtor, gerente
/// ou operador de campo).
///
/// É a porta de entrada do fluxo de navegação: ao entrar, a tela de login é
/// substituída pela casca principal (`pushReplacementNamed`), de modo que o
/// botão "voltar" não retorne a uma sessão já encerrada.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'produtor@fazenda.com');
  final _senhaController = TextEditingController(text: 'plotter123');
  final _senhaFocus = FocusNode();

  bool _entrando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    // Validação com mensagem clara em cada campo; se algo falhar, o usuário
    // recebe também um aviso global (visual e por leitor de tela).
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.erro(context, 'Revise os campos destacados para continuar.');
      return;
    }

    // Estado de carregamento: o botão vira "Aguarde…" e fica desabilitado,
    // deixando evidente que a ação foi registrada.
    setState(() => _entrando = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _entrando = false);

    // A confirmação do login é anunciada ao leitor de tela; visualmente,
    // a própria chegada ao painel já é o retorno da ação — uma mensagem
    // flutuante aqui encobriria o botão de ação do Dashboard.
    AppFeedback.anunciar(context, 'Acesso liberado. Abrindo o painel de talhões.');
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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
                    // Logo decorativa: sem valor informativo, fica fora da
                    // leitura do leitor de tela.
                    const ExcludeSemantics(
                      child: Icon(Icons.grass_rounded,
                          size: 64, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: Text(
                        'Plotter',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestão de lavoura por talhões',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 32),
                    AppTextField(
                      label: 'E-mail',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      obrigatorio: true,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _senhaFocus.requestFocus(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail cadastrado';
                        }
                        if (!value.contains('@')) {
                          return 'E-mail inválido: falta o "@"';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Senha',
                      icon: Icons.lock_outline,
                      obscureText: !_senhaVisivel,
                      controller: _senhaController,
                      focusNode: _senhaFocus,
                      obrigatorio: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _entrar(),
                      // Alternar a visibilidade da senha ajuda quem digita
                      // com luvas ou sob sol forte a conferir o que escreveu.
                      suffix: IconButton(
                        tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                        onPressed: () =>
                            setState(() => _senhaVisivel = !_senhaVisivel),
                        icon: Icon(_senhaVisivel
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      ),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'A senha deve ter ao menos 6 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => AppFeedback.informacao(
                          context,
                          'Um link de redefinição será enviado ao e-mail informado.',
                        ),
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Entrar',
                      icon: Icons.login,
                      loading: _entrando,
                      dica: 'Acessa o painel de talhões da fazenda',
                      onPressed: _entrar,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      'Perfis de acesso: Produtor, Gerente e Operador de campo.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
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
