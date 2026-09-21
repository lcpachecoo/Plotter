import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/talhao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';

/// Central de notificações: avisos de aplicações pendentes e agendadas.
///
/// É uma tela secundária, acessada pelo sino da barra superior do Dashboard
/// (ou pelo menu lateral em telas largas) e fechada pelo botão "voltar" da
/// barra superior, mantendo o usuário no mesmo fluxo de onde saiu.
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  /// Identificadores das notificações já lidas. O estado é apenas local:
  /// nesta etapa ainda não há persistência.
  final Set<String> _lidas = {};

  List<Talhao> get _pendentes => MockData.talhoes
      .where((t) => t.status != TalhaoStatus.feito)
      .toList(growable: false);

  void _marcarTodasComoLidas() {
    setState(() => _lidas.addAll(_pendentes.map((t) => t.id)));
    AppFeedback.sucesso(context, 'Todas as notificações foram marcadas como lidas.');
  }

  void _abrirTalhao(Talhao talhao) {
    setState(() => _lidas.add(talhao.id));
    Navigator.of(context).pushNamed(AppRoutes.talhaoDetalhe, arguments: talhao);
  }

  @override
  Widget build(BuildContext context) {
    final notificacoes = _pendentes;
    final naoLidas = notificacoes.where((t) => !_lidas.contains(t.id)).length;
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como lidas',
            onPressed: naoLidas == 0 ? null : _marcarTodasComoLidas,
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: notificacoes.isEmpty
              ? const _SemNotificacoes()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notificacoes.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Semantics(
                        header: true,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            naoLidas == 0
                                ? 'Nenhuma notificação não lida'
                                : '$naoLidas notificação(ões) não lida(s)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      );
                    }

                    final talhao = notificacoes[index - 1];
                    final lida = _lidas.contains(talhao.id);
                    final pendente = talhao.status == TalhaoStatus.pendente;

                    return Card(
                      // Notificações não lidas ganham fundo destacado, além
                      // do marcador: a cor não é o único indicador de estado.
                      color: lida ? AppTheme.surface : const Color(0xFFEEF5EC),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: (pendente
                                  ? AppTheme.pendingOrange
                                  : AppTheme.scheduledBlue)
                              .withValues(alpha: 0.12),
                          foregroundColor:
                              pendente ? AppTheme.pendingOrange : AppTheme.scheduledBlue,
                          child: Icon(
                            pendente ? Icons.warning_amber_rounded : Icons.schedule,
                          ),
                        ),
                        title: Text(
                          pendente
                              ? 'Aplicação pendente em ${talhao.nome}'
                              : 'Aplicação agendada em ${talhao.nome}',
                          style: TextStyle(
                            fontWeight: lida ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(talhao.proximaAplicacao),
                        // O ponto verde marca visualmente o item não lido; o
                        // rótulo semântico transmite o mesmo estado a quem
                        // usa leitor de tela.
                        trailing: lida
                            ? null
                            : Semantics(
                                label: 'Não lida',
                                child: const Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                        onTap: () => _abrirTalhao(talhao),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _SemNotificacoes extends StatelessWidget {
  const _SemNotificacoes();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 56, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Tudo em dia! Nenhuma aplicação pendente ou agendada no momento.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
