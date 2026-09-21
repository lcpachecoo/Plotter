import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/talhao.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../utils/app_feedback.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/talhao_card.dart';
import 'home_shell.dart';

/// Tela Dashboard (Home): visão geral dos talhões ativos da fazenda.
///
/// É o centro do fluxo de navegação: daqui o usuário abre o detalhe de um
/// talhão, cadastra um novo talhão, abre as notificações, usa o menu de mais
/// opções da barra superior e salta para o Histórico.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Filtro ativo do painel de status. `null` significa "todos os talhões".
  TalhaoStatus? _filtro;

  List<Talhao> get _talhoes {
    final todos = MockData.talhoes;
    if (_filtro == null) return todos;
    return todos.where((t) => t.status == _filtro).toList(growable: false);
  }

  void _alternarFiltro(TalhaoStatus status) {
    final novo = _filtro == status ? null : status;
    setState(() => _filtro = novo);

    final mensagem = novo == null
        ? 'Filtro removido. Exibindo todos os talhões.'
        : 'Exibindo apenas talhões com situação ${novo.label}.';
    AppFeedback.informacao(context, mensagem);
  }

  Future<void> _novoTalhao() async {
    // A tela de cadastro devolve `true` quando algo foi salvo: o retorno da
    // navegação é o gatilho do feedback, e não um aviso solto.
    final salvou = await Navigator.of(context)
        .pushNamed<Object?>(AppRoutes.talhaoFormulario);

    if (!mounted || salvou != true) return;
    AppFeedback.sucesso(context, 'Talhão cadastrado com sucesso.');
  }

  Future<void> _atualizar() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    AppFeedback.informacao(context, 'Lista de talhões atualizada.');
  }

  Future<void> _sair() async {
    final confirmado = await AppFeedback.confirmar(
      context,
      titulo: 'Sair da conta?',
      mensagem: 'Você precisará informar e-mail e senha novamente.',
      confirmarLabel: 'Sair',
      destrutivo: true,
    );

    if (!mounted || !confirmado) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (rota) => false);
  }

  @override
  Widget build(BuildContext context) {
    final todos = MockData.talhoes;
    final visiveis = _talhoes;
    final pendentes = todos.where((t) => t.status == TalhaoStatus.pendente).length;
    final emDia = todos.where((t) => t.status == TalhaoStatus.feito).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Talhões'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: pendentes > 0,
              label: Text('$pendentes'),
              backgroundColor: AppTheme.pendingOrange,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notificações ($pendentes pendentes)',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notificacoes),
          ),
          // Menu de mais opções: agrupa ações secundárias sem poluir a
          // barra superior nem competir com as ações principais.
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            icon: const Icon(Icons.more_vert),
            onSelected: (valor) {
              switch (valor) {
                case 'ajuda':
                  Navigator.of(context).pushNamed(AppRoutes.ajuda);
                case 'ajustes':
                  HomeShellScope.maybeOf(context)?.irPara(HomeTab.configuracoes);
                case 'sair':
                  _sair();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'ajuda',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Ajuda e acessibilidade'),
                ),
              ),
              PopupMenuItem(
                value: 'ajustes',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Ajustes'),
                ),
              ),
              PopupMenuItem(
                value: 'sair',
                child: ListTile(
                  leading: Icon(Icons.logout, color: AppTheme.dangerRed),
                  title: Text('Sair da conta',
                      style: TextStyle(color: AppTheme.dangerRed)),
                ),
              ),
            ],
          ),
        ],
      ),
      // Ação principal da tela em botão grande, no canto inferior direito —
      // a área mais fácil de alcançar com o polegar (Lei de Fitts).
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: _novoTalhao,
        icon: const Icon(Icons.add),
        label: const Text('Novo talhão'),
        tooltip: 'Cadastrar um novo talhão',
      ),
      body: RefreshIndicator(
        // Puxar para atualizar dá um retorno imediato de que a ação está em
        // andamento, encerrado por uma mensagem de confirmação.
        onRefresh: _atualizar,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
            final crossAxisCount = isWide
                ? (constraints.maxWidth >= AppBreakpoints.desktop ? 3 : 2)
                : 1;
            // A altura do cartão acompanha o tamanho de fonte do sistema,
            // evitando corte de texto quando a fonte está ampliada.
            final escala = MediaQuery.textScalerOf(context).scale(16) / 16;

            final painel = [
              StatTile(
                label: 'Talhões em dia',
                value: '$emDia',
                icon: Icons.check_circle_outline,
                color: AppTheme.doneGreen,
                selecionado: _filtro == TalhaoStatus.feito,
                onTap: () => _alternarFiltro(TalhaoStatus.feito),
              ),
              StatTile(
                label: 'Talhões pendentes',
                value: '$pendentes',
                icon: Icons.warning_amber_rounded,
                color: AppTheme.pendingOrange,
                selecionado: _filtro == TalhaoStatus.pendente,
                onTap: () => _alternarFiltro(TalhaoStatus.pendente),
              ),
            ];

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Painel de status responsivo: empilha em telas estreitas e
                  // fica lado a lado em telas largas.
                  if (isWide)
                    Row(
                      children: [
                        Expanded(child: painel[0]),
                        const SizedBox(width: 12),
                        Expanded(child: painel[1]),
                      ],
                    )
                  else
                    Column(
                      children: [
                        painel[0],
                        const SizedBox(height: 12),
                        painel[1],
                      ],
                    ),
                  if (_filtro != null) ...[
                    const SizedBox(height: 12),
                    _AvisoFiltro(
                      status: _filtro!,
                      onLimpar: () => _alternarFiltro(_filtro!),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Talhões ativos',
                    actionLabel: 'Ver histórico',
                    actionIcon: Icons.history,
                    // Atalho entre seções: troca a aba da casca de navegação
                    // em vez de empilhar mais uma tela.
                    onAction: () =>
                        HomeShellScope.maybeOf(context)?.irPara(HomeTab.historico),
                  ),
                  const SizedBox(height: 12),
                  if (visiveis.isEmpty)
                    _ListaVazia(onLimpar: () => _alternarFiltro(_filtro!))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visiveis.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 186 * escala,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final talhao = visiveis[index];
                        return TalhaoCard(
                          talhao: talhao,
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.talhaoDetalhe,
                            arguments: talhao,
                          ),
                        );
                      },
                    ),
                  // Espaço para que o botão flutuante não cubra o último card.
                  const SizedBox(height: 96),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Faixa que deixa explícito que a lista está filtrada e oferece a saída do
/// filtro a um toque de distância.
class _AvisoFiltro extends StatelessWidget {
  final TalhaoStatus status;
  final VoidCallback onLimpar;

  const _AvisoFiltro({required this.status, required this.onLimpar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: AppTheme.darkGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Filtrando por: ${status.label}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton.icon(
            onPressed: onLimpar,
            icon: const Icon(Icons.close, size: 20),
            label: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class _ListaVazia extends StatelessWidget {
  final VoidCallback onLimpar;

  const _ListaVazia({required this.onLimpar});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              'Nenhum talhão nessa situação no momento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onLimpar,
              icon: const Icon(Icons.clear_all),
              label: const Text('Mostrar todos os talhões'),
            ),
          ],
        ),
      ),
    );
  }
}
