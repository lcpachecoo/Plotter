import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/aviso.dart';

/// Estado global das preferências do usuário (Etapa 7).
///
/// Antes desta etapa, cada valor vivia dentro de uma tela (`setState`) e se
/// perdia ao sair dela; o contador do sino nem sabia quais avisos já tinham
/// sido lidos. Agora um único objeto guarda esses valores, avisa todas as
/// telas interessadas quando algo muda (`ChangeNotifier`) e grava cada
/// alteração no aparelho (`shared_preferences`), para que ela continue valendo
/// depois de fechar e reabrir o app.
///
/// Quem usa:
/// * **Ajustes**: liga/desliga lembretes e economia de dados;
/// * **Notificações**: lê e marca os avisos lidos;
/// * **Dashboard** e **menu lateral**: contador de avisos não lidos no sino;
/// * **Lembretes** (fora da árvore de widgets): agenda ou cancela as
///   notificações do sistema quando [lembretesAtivos] muda.
class Preferencias extends ChangeNotifier {
  Preferencias._(
    this._armazenamento, {
    this._lembretesAtivos = false,
    this._economiaDados = false,
    Set<String> avisosLidos = const {},
  }) : _avisosLidos = {...avisosLidos};

  /// Preferências só em memória, sem gravar no aparelho. Usado nos testes e
  /// quando o armazenamento do aparelho não pode ser aberto.
  Preferencias.emMemoria() : this._(null);

  static const _chaveLembretes = 'lembretes_ativos';
  static const _chaveEconomia = 'economia_dados';
  static const _chaveAvisosLidos = 'avisos_lidos';

  /// Lê as preferências gravadas. Nunca falha: se o armazenamento não puder
  /// ser aberto, o app segue com os valores padrão, só não lembra das
  /// escolhas na próxima abertura.
  static Future<Preferencias> carregar() async {
    try {
      final armazenamento = await SharedPreferences.getInstance();
      return Preferencias._(
        armazenamento,
        lembretesAtivos: armazenamento.getBool(_chaveLembretes) ?? false,
        economiaDados: armazenamento.getBool(_chaveEconomia) ?? false,
        avisosLidos:
            (armazenamento.getStringList(_chaveAvisosLidos) ?? const []).toSet(),
      );
    } catch (erro) {
      debugPrint('Preferências não puderam ser lidas: $erro');
      return Preferencias.emMemoria();
    }
  }

  final SharedPreferences? _armazenamento;

  bool _lembretesAtivos;
  bool _economiaDados;
  Set<String> _avisosLidos;

  /// `false` quando as preferências valem só nesta execução do app.
  bool get persistente => _armazenamento != null;

  /// O usuário pediu para receber lembretes das aplicações agendadas. Se o
  /// sistema permite entregá-los é outra questão, tratada em `Lembretes`.
  bool get lembretesAtivos => _lembretesAtivos;

  bool get economiaDados => _economiaDados;

  // ---------------------------------------------------------------------
  // Avisos lidos
  // ---------------------------------------------------------------------

  bool foiLido(Aviso aviso) => _avisosLidos.contains(aviso.chave);

  /// Quantos dos [avisos] ainda não foram lidos (número exibido no sino).
  int naoLidos(Iterable<Aviso> avisos) =>
      avisos.where((aviso) => !foiLido(aviso)).length;

  Future<void> marcarComoLido(Aviso aviso) async {
    if (!_avisosLidos.add(aviso.chave)) return;
    notifyListeners();
    await _gravar((a) => a.setStringList(_chaveAvisosLidos, _avisosLidos.toList()));
  }

  /// Marca como lidos exatamente os [avisos] atuais. As chaves de avisos que
  /// já não existem são descartadas, então a lista gravada não cresce sem
  /// limite.
  Future<void> marcarTodosComoLidos(Iterable<Aviso> avisos) async {
    _avisosLidos = {for (final aviso in avisos) aviso.chave};
    notifyListeners();
    await _gravar((a) => a.setStringList(_chaveAvisosLidos, _avisosLidos.toList()));
  }

  // ---------------------------------------------------------------------
  // Ajustes
  // ---------------------------------------------------------------------

  Future<void> definirLembretes(bool ativos) async {
    if (_lembretesAtivos == ativos) return;
    _lembretesAtivos = ativos;
    notifyListeners();
    await _gravar((a) => a.setBool(_chaveLembretes, ativos));
  }

  Future<void> definirEconomiaDados(bool ativa) async {
    if (_economiaDados == ativa) return;
    _economiaDados = ativa;
    notifyListeners();
    await _gravar((a) => a.setBool(_chaveEconomia, ativa));
  }

  /// A tela é atualizada antes da gravação terminar. Se gravar falhar, o
  /// valor continua valendo até o app ser fechado.
  Future<void> _gravar(Future<bool> Function(SharedPreferences) escrever) async {
    final armazenamento = _armazenamento;
    if (armazenamento == null) return;
    try {
      await escrever(armazenamento);
    } catch (erro) {
      debugPrint('Preferência não pôde ser gravada: $erro');
    }
  }
}

/// Disponibiliza as [Preferencias] para toda a árvore de widgets, no mesmo
/// padrão do `PlotterCrudScope`: [of] reconstrói a tela quando algo muda;
/// [read] só lê, para uso em callbacks.
class PreferenciasScope extends InheritedNotifier<Preferencias> {
  const PreferenciasScope({
    super.key,
    required Preferencias preferencias,
    required super.child,
  }) : super(notifier: preferencias);

  static Preferencias of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PreferenciasScope>();
    assert(scope != null, 'PreferenciasScope não encontrado na árvore.');
    return scope!.notifier!;
  }

  static Preferencias read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<PreferenciasScope>();
    assert(scope != null, 'PreferenciasScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
