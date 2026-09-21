import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/section_header.dart';

/// Tela de Configurações/Sincronização: status offline/online, preferências
/// e saída da conta.
///
/// Concentra as ações de conta e é também o ponto de acesso à tela de ajuda
/// e acessibilidade.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _sincronizando = false;
  bool _notificacoes = true;
  bool _economiaDados = false;
  String _ultimaSincronizacao = '07:42';

  Future<void> _sincronizar() async {
    if (_sincronizando) return;

    setState(() => _sincronizando = true);
    AppFeedback.informacao(context, 'Sincronização iniciada…');

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final agora = TimeOfDay.now();
    setState(() {
      _sincronizando = false;
      _ultimaSincronizacao =
          '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';
    });
    AppFeedback.sucesso(context, 'Dados sincronizados com o servidor.');
  }

  Future<void> _sair() async {
    final confirmado = await AppFeedback.confirmar(
      context,
      titulo: 'Sair da conta?',
      mensagem: 'Registros ainda não sincronizados permanecem no aparelho.',
      confirmarLabel: 'Sair',
      destrutivo: true,
    );

    if (!mounted || !confirmado) return;
    // Remove todo o histórico de navegação: o "voltar" não deve trazer o
    // usuário de volta para dentro de uma sessão encerrada.
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (rota) => false);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'Sincronização'),
              const SizedBox(height: 12),
              MergeSemantics(
                child: Card(
                  color: AppTheme.lightGreen.withValues(alpha: 0.18),
                  child: ListTile(
                    leading: const Icon(Icons.cloud_done_outlined),
                    title: const Text('Conectado'),
                    subtitle: Text(
                        'Últimos dados sincronizados às $_ultimaSincronizacao'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: _sincronizando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.sync),
                  title: Text(
                      _sincronizando ? 'Sincronizando…' : 'Sincronizar agora'),
                  subtitle: const Text('Envia os registros pendentes ao servidor'),
                  enabled: !_sincronizando,
                  onTap: _sincronizar,
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Conta'),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    const MergeSemantics(
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Perfil'),
                        subtitle: Text('Produtor · Fazenda Modelo'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications_outlined),
                      title: const Text('Notificações recebidas'),
                      subtitle: const Text('Ver avisos de aplicações'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.notificacoes),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Ajuda e acessibilidade'),
                      subtitle: const Text('Como navegar e recursos disponíveis'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.ajuda),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Preferências'),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Notificações push'),
                      subtitle: const Text('Avisos de aplicações agendadas'),
                      value: _notificacoes,
                      onChanged: (valor) {
                        setState(() => _notificacoes = valor);
                        AppFeedback.informacao(
                          context,
                          valor
                              ? 'Notificações push ativadas.'
                              : 'Notificações push desativadas.',
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.wifi_off_outlined),
                      title: const Text('Modo economia de dados'),
                      subtitle: const Text('Sincroniza apenas em rede Wi-Fi'),
                      value: _economiaDados,
                      onChanged: (valor) {
                        setState(() => _economiaDados = valor);
                        AppFeedback.informacao(
                          context,
                          valor
                              ? 'Economia de dados ativada.'
                              : 'Economia de dados desativada.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Ação destrutiva separada das demais, com cor de alerta e
              // confirmação antes de executar.
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.dangerRed),
                  title: const Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: AppTheme.dangerRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Encerra a sessão neste aparelho'),
                  onTap: _sair,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
