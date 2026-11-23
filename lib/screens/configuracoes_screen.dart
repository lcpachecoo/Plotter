import 'package:flutter/material.dart';

import '../data/plotter_api.dart';
import '../data/plotter_crud.dart';
import '../routes/app_routes.dart';
import '../state/lembretes.dart';
import '../state/preferencias.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/aviso_lembretes.dart';
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

  /// Enquanto o pedido de permissão do sistema está aberto, o interruptor
  /// fica travado para evitar um segundo toque.
  bool _alternandoLembretes = false;

  // Etapa 7: as preferências saíram daqui (antes eram `bool` desta tela,
  // perdidas ao fechar o app) e passaram para o estado global
  // [Preferencias], gravado no aparelho.

  Future<void> _alternarLembretes(bool ativar) async {
    setState(() => _alternandoLembretes = true);
    await alternarLembretes(context, ativar);
    if (mounted) setState(() => _alternandoLembretes = false);
  }

  /// Baixa do servidor os dados mais recentes (Etapa 5: sincronização real,
  /// antes simulada).
  Future<void> _sincronizar() async {
    if (_sincronizando) return;

    setState(() => _sincronizando = true);
    AppFeedback.informacao(context, 'Sincronização iniciada…');

    try {
      await PlotterCrudScope.read(context).sincronizar();
    } catch (erro) {
      if (!mounted) return;
      setState(() => _sincronizando = false);
      AppFeedback.erro(
        context,
        mensagemDeErro(erro, 'Não foi possível sincronizar. Tente novamente.'),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _sincronizando = false);
    AppFeedback.sucesso(context, 'Dados sincronizados com o servidor.');
  }

  Future<void> _sair() async {
    final confirmado = await AppFeedback.confirmar(
      context,
      titulo: 'Sair da conta?',
      mensagem: 'Você precisará entrar novamente para usar o Plotter.',
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
    final crud = PlotterCrudScope.of(context);
    final preferencias = PreferenciasScope.of(context);
    final lembretes = LembretesScope.of(context);
    final situacao = lembretes.situacao;

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
              _StatusConexao(
                status: crud.status,
                ultimaSincronizacao: crud.ultimaSincronizacao,
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
                  subtitle: const Text('Busca no servidor os dados mais recentes'),
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
                    // Recurso nativo (Etapa 7): lembretes pelas
                    // notificações do sistema. Ligado quando o usuário quer
                    // os lembretes e o aparelho permite entregá-los.
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Lembretes de aplicações'),
                      subtitle: Text(descricaoLembretes(lembretes)),
                      value: preferencias.lembretesAtivos &&
                          situacao != SituacaoLembretes.semPermissao &&
                          situacao != SituacaoLembretes.indisponivel,
                      onChanged: _alternandoLembretes ||
                              situacao == SituacaoLembretes.verificando ||
                              situacao == SituacaoLembretes.indisponivel
                          ? null
                          : _alternarLembretes,
                    ),
                    if (situacao == SituacaoLembretes.semPermissao)
                      ListTile(
                        leading: const Icon(Icons.open_in_new),
                        title: const Text('Permitir notificações'),
                        subtitle: const Text(
                            'Abre as configurações do aparelho para o Plotter'),
                        onTap: () => abrirConfiguracoesDeNotificacao(context),
                      ),
                    if (situacao == SituacaoLembretes.falha)
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('Tentar agendar de novo'),
                        onTap: lembretes.tentarDeNovo,
                      ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.wifi_off_outlined),
                      title: const Text('Modo economia de dados'),
                      subtitle: const Text('Sincroniza apenas em rede Wi-Fi'),
                      value: preferencias.economiaDados,
                      onChanged: (valor) {
                        preferencias.definirEconomiaDados(valor);
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

/// Cartão com a situação real da conexão com o backend, lida do
/// [PlotterCrud]. Cor, ícone e texto mudam juntos.
class _StatusConexao extends StatelessWidget {
  final StatusServidor status;
  final DateTime? ultimaSincronizacao;

  const _StatusConexao({required this.status, this.ultimaSincronizacao});

  @override
  Widget build(BuildContext context) {
    final ultima = ultimaSincronizacao;
    final horario = ultima == null
        ? null
        : '${ultima.hour.toString().padLeft(2, '0')}:'
            '${ultima.minute.toString().padLeft(2, '0')}';

    final (IconData icone, Color cor, String titulo, String detalhe) =
        switch (status) {
      StatusServidor.conectado => (
          Icons.cloud_done_outlined,
          AppTheme.doneGreen,
          'Conectado ao servidor',
          horario == null
              ? 'Dados enviados ao servidor a cada alteração'
              : 'Últimos dados sincronizados às $horario',
        ),
      StatusServidor.verificando => (
          Icons.cloud_sync_outlined,
          AppTheme.scheduledBlue,
          'Conectando ao servidor…',
          'Buscando os dados mais recentes',
        ),
      StatusServidor.offline => (
          Icons.cloud_off_outlined,
          AppTheme.pendingOrange,
          'Sem conexão com o servidor',
          'Exibindo os dados salvos no aparelho',
        ),
      StatusServidor.semServidor => (
          Icons.phone_android,
          AppTheme.textSecondary,
          'Somente neste aparelho',
          'Nenhum servidor configurado',
        ),
    };

    return MergeSemantics(
      child: Card(
        color: cor.withValues(alpha: 0.1),
        child: ListTile(
          leading: Icon(icone, color: cor),
          title: Text(titulo),
          subtitle: Text(detalhe),
        ),
      ),
    );
  }
}
