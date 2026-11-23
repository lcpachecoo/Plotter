import 'package:flutter/material.dart';

import '../data/plotter_crud.dart';
import '../models/aviso.dart';
import '../routes/app_routes.dart';
import '../state/preferencias.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/aviso_lembretes.dart';

/// Central de notificações: avisos de aplicações pendentes e agendadas.
///
/// É uma tela secundária, acessada pelo sino da barra superior do Dashboard
/// (ou pelo menu lateral em telas largas) e fechada pelo botão "voltar" da
/// barra superior, mantendo o usuário no mesmo fluxo de onde saiu.
///
/// Etapa 7: o estado "lido" de cada aviso deixou de ficar dentro desta tela
/// (`setState`) e passou para o estado global [Preferencias]. Assim ele
/// continua valendo ao sair e voltar, ao fechar o app, e o contador do sino
/// no Dashboard diminui assim que um aviso é lido aqui.
class NotificacoesScreen extends StatelessWidget {
  const NotificacoesScreen({super.key});

  void _marcarTodasComoLidas(BuildContext context) {
    final avisos = PlotterCrudScope.read(context).avisos;
    PreferenciasScope.read(context).marcarTodosComoLidos(avisos);
    AppFeedback.sucesso(context, 'Todas as notificações foram marcadas como lidas.');
  }

  void _abrirAviso(BuildContext context, Aviso aviso) {
    PreferenciasScope.read(context).marcarComoLido(aviso);
    AppRoutes.abrirTalhao(context, aviso.talhao);
  }

  @override
  Widget build(BuildContext context) {
    final crud = PlotterCrudScope.of(context);
    final preferencias = PreferenciasScope.of(context);
    final avisos = crud.avisos;
    final naoLidas = preferencias.naoLidos(avisos);
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Marcar todas como lidas',
            onPressed: naoLidas == 0 ? null : () => _marcarTodasComoLidas(context),
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 700 : double.infinity),
          child: avisos.isEmpty
              ? const Column(
                  children: [
                    AvisoLembretes(margem: EdgeInsets.all(16)),
                    Expanded(child: _SemNotificacoes()),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: avisos.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Convite para ativar os lembretes do sistema (ou
                          // aviso de que estão bloqueados). Some quando ativos.
                          const AvisoLembretes(
                            margem: EdgeInsets.only(bottom: 16),
                          ),
                          Semantics(
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
                          ),
                        ],
                      );
                    }

                    final aviso = avisos[index - 1];
                    final lida = preferencias.foiLido(aviso);
                    final pendente = aviso.pendente;

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
                          aviso.titulo,
                          style: TextStyle(
                            fontWeight: lida ? FontWeight.w500 : FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(crud.resumoProximaAplicacao(aviso.talhao.id!)),
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
                        onTap: () => _abrirAviso(context, aviso),
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
