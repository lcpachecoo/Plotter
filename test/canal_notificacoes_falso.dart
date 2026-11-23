import 'package:flutter/services.dart';

import 'package:plotter/state/lembretes.dart';

/// Substitui as notificações do sistema nos testes. Guarda os lembretes
/// agendados em memória e permite simular cada situação do recurso nativo:
/// aparelho sem suporte, permissão negada, permissão retirada nas
/// configurações, falha ao agendar e toque em um lembrete.
class CanalNotificacoesFalso implements CanalNotificacoes {
  CanalNotificacoesFalso({
    this.disponivel = true,
    this.permissao = false,
    this.concedeAoPedir = true,
  });

  /// `false` simula um aparelho/plataforma sem o plugin de notificações.
  bool disponivel;

  /// Situação atual da permissão no sistema.
  bool permissao;

  /// Resposta do usuário ao diálogo de permissão.
  bool concedeAoPedir;

  /// `true` faz o sistema recusar o agendamento.
  bool falharAoAgendar = false;

  /// Talhão do lembrete que "abriu o app".
  int? talhaoInicial;

  final Map<int, Lembrete> agendados = {};

  /// Quantas vezes `agendar` foi chamado (para conferir que nada é
  /// reagendado à toa).
  int agendamentos = 0;
  int pedidosDePermissao = 0;
  int aberturasDasConfiguracoes = 0;

  void Function(int talhaoId)? _aoTocar;

  /// Simula o toque do usuário em um lembrete com o app aberto.
  void tocar(int talhaoId) => _aoTocar!(talhaoId);

  @override
  Future<bool> inicializar({required void Function(int talhaoId) aoTocar}) async {
    if (!disponivel) {
      throw MissingPluginException('Notificações não implementadas.');
    }
    _aoTocar = aoTocar;
    return true;
  }

  @override
  Future<int?> talhaoQueAbriuOApp() async => talhaoInicial;

  @override
  Future<bool> permissaoConcedida() async => permissao;

  @override
  Future<bool> pedirPermissao() async {
    pedidosDePermissao++;
    if (concedeAoPedir) permissao = true;
    return permissao;
  }

  @override
  Future<void> agendar(Lembrete lembrete) async {
    if (falharAoAgendar) {
      throw PlatformException(code: 'erro', message: 'Agendamento recusado.');
    }
    agendamentos++;
    agendados[lembrete.id] = lembrete;
  }

  @override
  Future<void> cancelarTodos() async => agendados.clear();

  @override
  Future<void> abrirConfiguracoes() async => aberturasDasConfiguracoes++;
}
