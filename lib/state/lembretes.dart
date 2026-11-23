import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/plotter_crud.dart';
import '../models/registro.dart';
import 'preferencias.dart';

/// Lembrete entregue pelo sistema operacional no dia de uma aplicação.
@immutable
class Lembrete {
  /// O id do registro, que também identifica a notificação no sistema.
  final int id;
  final int talhaoId;
  final DateTime quando;
  final String titulo;
  final String corpo;

  const Lembrete({
    required this.id,
    required this.talhaoId,
    required this.quando,
    required this.titulo,
    required this.corpo,
  });

  /// Muda quando qualquer dado exibido ou o horário muda. Serve para saber
  /// se é preciso reagendar.
  String get assinatura =>
      '$id|${quando.millisecondsSinceEpoch}|$titulo|$corpo';
}

/// Acesso ao recurso nativo de notificações.
///
/// A implementação real (`NotificacoesLocais`, em
/// `lib/services/notificacoes_locais.dart`) usa o plugin
/// `flutter_local_notifications`. Os testes usam uma versão falsa, que
/// simula permissão negada, falhas e toques sem precisar de um aparelho.
abstract interface class CanalNotificacoes {
  /// Prepara o recurso. Lança erro ou devolve `false` se o aparelho não
  /// oferece notificações. [aoTocar] recebe o talhão do lembrete tocado com o
  /// app aberto ou em segundo plano.
  Future<bool> inicializar({required void Function(int talhaoId) aoTocar});

  /// Talhão do lembrete que abriu o app, quando ele estava fechado.
  Future<int?> talhaoQueAbriuOApp();

  /// O sistema permite que o Plotter mostre notificações?
  Future<bool> permissaoConcedida();

  /// Mostra o pedido de permissão do sistema e devolve a resposta. Se o
  /// usuário já negou de vez, o sistema não pergunta de novo e devolve `false`.
  Future<bool> pedirPermissao();

  Future<void> agendar(Lembrete lembrete);

  Future<void> cancelarTodos();

  /// Abre a tela do sistema em que o usuário libera as notificações do app.
  Future<void> abrirConfiguracoes();
}

/// Situação dos lembretes, exibida em Ajustes e na tela de Notificações.
enum SituacaoLembretes {
  /// O app acabou de abrir e ainda está consultando o sistema.
  verificando,

  /// O usuário não ativou os lembretes.
  desativados,

  /// Os lembretes estão agendados no sistema.
  ativos,

  /// O usuário ativou os lembretes, mas o sistema bloqueia as notificações
  /// do Plotter (permissão negada ou retirada nas configurações).
  semPermissao,

  /// O sistema recusou o agendamento. O app tenta de novo na próxima
  /// alteração, ao voltar para o app ou com o botão "Tentar de novo".
  falha,

  /// O aparelho ou a plataforma não oferece notificações locais.
  indisponivel,
}

/// Resposta de [Lembretes.ativar], usada pela tela para escolher a mensagem.
enum ResultadoAtivacao { ativado, permissaoNegada, indisponivel, falha }

/// Lembretes de aplicações agendadas: o recurso nativo da Etapa 7.
///
/// Junta os dois estados globais do app: lê as aplicações agendadas no
/// [PlotterCrud] e a escolha do usuário em [Preferencias]. Sempre que um dos
/// dois muda, ou quando o usuário volta ao app (ele pode ter mudado a
/// permissão nas configurações do sistema), refaz a agenda de notificações.
/// Cada aplicação agendada vira um aviso às [horaDoLembrete] h do próprio dia.
class Lembretes extends ChangeNotifier {
  Lembretes({
    required this._canal,
    required this._crud,
    required this._preferencias,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  /// Hora do dia em que o lembrete aparece: cedo, antes da saída para o campo.
  static const horaDoLembrete = 7;

  /// Máximo de lembretes agendados ao mesmo tempo, das aplicações mais
  /// próximas. O Android aceita até 500 alarmes por app; 50 cobrem semanas
  /// de agenda com folga.
  static const limite = 50;

  final CanalNotificacoes _canal;
  final PlotterCrud _crud;
  final Preferencias _preferencias;
  final DateTime Function() _relogio;

  SituacaoLembretes _situacao = SituacaoLembretes.verificando;
  int _quantidade = 0;
  bool _iniciado = false;
  AppLifecycleListener? _cicloDeVida;

  /// Assinatura da última agenda enviada ao sistema. Evita cancelar e
  /// reagendar tudo quando nada que importa mudou.
  String? _agendaAtual;

  Future<void>? _execucao;
  bool _atualizacaoPendente = false;

  /// Talhão de um lembrete tocado pelo usuário, à espera de ser aberto pela
  /// casca de navegação (que só existe depois do login).
  final ValueNotifier<int?> talhaoSolicitado = ValueNotifier<int?>(null);

  SituacaoLembretes get situacao => _situacao;

  /// Quantos lembretes estão agendados no sistema.
  int get quantidade => _quantidade;

  /// Prepara o recurso nativo e passa a acompanhar os dados e as
  /// preferências. Se o aparelho não oferece notificações, os lembretes
  /// ficam [SituacaoLembretes.indisponivel] e o resto do app segue normal.
  Future<void> iniciar() async {
    if (_iniciado) return;
    bool disponivel;
    try {
      disponivel = await _canal.inicializar(aoTocar: _solicitarTalhao);
    } catch (erro) {
      debugPrint('Notificações indisponíveis: $erro');
      disponivel = false;
    }
    if (!disponivel) {
      _definir(SituacaoLembretes.indisponivel, 0);
      return;
    }

    // O app pode ter sido aberto por um toque em um lembrete. Uma falha aqui
    // não impede os lembretes de funcionar.
    try {
      final talhaoId = await _canal.talhaoQueAbriuOApp();
      if (talhaoId != null) _solicitarTalhao(talhaoId);
    } catch (erro) {
      debugPrint('Não foi possível ler o lembrete que abriu o app: $erro');
    }

    _iniciado = true;
    _crud.addListener(atualizar);
    _preferencias.addListener(atualizar);
    _cicloDeVida = AppLifecycleListener(onResume: atualizar);
    await atualizar();
  }

  /// Chamado quando o usuário liga os lembretes. Pede a permissão do sistema
  /// só neste momento, quando o motivo está claro para quem usa o app.
  Future<ResultadoAtivacao> ativar() async {
    if (_situacao == SituacaoLembretes.indisponivel) {
      return ResultadoAtivacao.indisponivel;
    }
    final bool concedida;
    try {
      concedida =
          await _canal.permissaoConcedida() || await _canal.pedirPermissao();
    } catch (erro) {
      debugPrint('Falha ao pedir permissão de notificação: $erro');
      return ResultadoAtivacao.falha;
    }
    if (!concedida) return ResultadoAtivacao.permissaoNegada;

    await _preferencias.definirLembretes(true);
    await atualizar();
    return _situacao == SituacaoLembretes.ativos
        ? ResultadoAtivacao.ativado
        : ResultadoAtivacao.falha;
  }

  /// Desliga os lembretes e cancela os que já estavam no sistema.
  Future<void> desativar() async {
    await _preferencias.definirLembretes(false);
    await atualizar();
  }

  /// Refaz a agenda do zero, mesmo que nada tenha mudado (botão "Tentar de
  /// novo" depois de uma [SituacaoLembretes.falha]).
  Future<void> tentarDeNovo() {
    _agendaAtual = null;
    return atualizar();
  }

  /// Abre as configurações de notificação do sistema. Devolve `false` se o
  /// aparelho não permitir.
  Future<bool> abrirConfiguracoes() async {
    try {
      await _canal.abrirConfiguracoes();
      return true;
    } catch (erro) {
      debugPrint('Não foi possível abrir as configurações: $erro');
      return false;
    }
  }

  /// Entrega à tela o talhão de um lembrete tocado, uma única vez.
  int? consumirTalhaoSolicitado() {
    final id = talhaoSolicitado.value;
    talhaoSolicitado.value = null;
    return id;
  }

  /// Sincroniza a agenda do sistema com os dados atuais. Pedidos feitos
  /// enquanto outra sincronização está em andamento são reunidos em uma nova
  /// rodada, e o `Future` devolvido só termina quando tudo estiver aplicado.
  Future<void> atualizar() {
    _atualizacaoPendente = true;
    return _execucao ??= _processarPendentes();
  }

  Future<void> _processarPendentes() async {
    try {
      while (_atualizacaoPendente) {
        _atualizacaoPendente = false;
        await _aplicar();
      }
    } finally {
      _execucao = null;
    }
  }

  Future<void> _aplicar() async {
    if (!_iniciado) return;
    try {
      if (!_preferencias.lembretesAtivos) {
        if (_situacao != SituacaoLembretes.desativados) {
          await _cancelarSemFalhar();
        }
        _agendaAtual = null;
        _definir(SituacaoLembretes.desativados, 0);
        return;
      }

      if (!await _canal.permissaoConcedida()) {
        // A escolha do usuário é mantida: quando ele liberar a permissão
        // nas configurações e voltar ao app, os lembretes voltam sozinhos.
        if (_situacao != SituacaoLembretes.semPermissao) {
          await _cancelarSemFalhar();
        }
        _agendaAtual = null;
        _definir(SituacaoLembretes.semPermissao, 0);
        return;
      }

      final planejados = planejar();
      final agenda = planejados.map((l) => l.assinatura).join(';');
      if (agenda != _agendaAtual) {
        await _canal.cancelarTodos();
        for (final lembrete in planejados) {
          await _canal.agendar(lembrete);
        }
        _agendaAtual = agenda;
      }
      _definir(SituacaoLembretes.ativos, planejados.length);
    } catch (erro) {
      debugPrint('Falha ao agendar lembretes: $erro');
      _agendaAtual = null;
      _definir(SituacaoLembretes.falha, 0);
    }
  }

  /// Cancelar é uma limpeza: se o sistema recusar, não há o que mostrar ao
  /// usuário, que desligou os lembretes ou bloqueou as notificações.
  Future<void> _cancelarSemFalhar() async {
    try {
      await _canal.cancelarTodos();
    } catch (erro) {
      debugPrint('Falha ao cancelar lembretes: $erro');
    }
  }

  /// Lembretes que deveriam estar no sistema agora: um por aplicação
  /// agendada, às [horaDoLembrete] h do dia, só os que ainda vão acontecer,
  /// dos mais próximos para os mais distantes, até o [limite].
  @visibleForTesting
  List<Lembrete> planejar() {
    final agora = _relogio();
    final lembretes = <Lembrete>[];
    for (final registro in _crud.agendadas) {
      final id = registro.id;
      if (id == null) continue;
      final quando = DateTime(registro.data.year, registro.data.month,
          registro.data.day, horaDoLembrete);
      if (!quando.isAfter(agora)) continue;
      lembretes.add(_lembreteDe(registro, id, quando));
    }
    lembretes.sort((a, b) => a.quando.compareTo(b.quando));
    return lembretes.take(limite).toList(growable: false);
  }

  Lembrete _lembreteDe(Registro registro, int id, DateTime quando) {
    final talhao = _crud.buscarTalhao(registro.talhaoId)?.nome ?? 'talhão';
    final quantidade =
        registro.quantidade.isEmpty ? '' : ' · ${registro.quantidade}';
    return Lembrete(
      id: id,
      talhaoId: registro.talhaoId,
      quando: quando,
      titulo: 'Aplicação agendada para hoje',
      corpo: '${registro.insumo} em $talhao$quantidade',
    );
  }

  void _solicitarTalhao(int talhaoId) => talhaoSolicitado.value = talhaoId;

  void _definir(SituacaoLembretes situacao, int quantidade) {
    if (_situacao == situacao && _quantidade == quantidade) return;
    _situacao = situacao;
    _quantidade = quantidade;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_iniciado) {
      _crud.removeListener(atualizar);
      _preferencias.removeListener(atualizar);
    }
    _cicloDeVida?.dispose();
    talhaoSolicitado.dispose();
    super.dispose();
  }
}

/// Disponibiliza os [Lembretes] para toda a árvore de widgets.
class LembretesScope extends InheritedNotifier<Lembretes> {
  const LembretesScope({
    super.key,
    required Lembretes lembretes,
    required super.child,
  }) : super(notifier: lembretes);

  static Lembretes of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LembretesScope>();
    assert(scope != null, 'LembretesScope não encontrado na árvore.');
    return scope!.notifier!;
  }

  static Lembretes read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<LembretesScope>();
    assert(scope != null, 'LembretesScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
