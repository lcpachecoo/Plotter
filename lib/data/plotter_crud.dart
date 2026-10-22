import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import '../models/registro.dart';
import '../models/talhao.dart';
import 'database_helper.dart';

/// Único ponto de acesso aos dados persistidos do aplicativo.
///
/// Concentra as operações de criação, leitura, atualização e remoção (CRUD)
/// de talhões e registros sobre o banco SQLite. As telas nunca executam SQL:
/// leem as listas expostas aqui e chamam os métodos de gravação.
///
/// Depois de cada gravação as listas são relidas do banco, de modo que a
/// interface sempre mostra exatamente o que está armazenado, e as telas que
/// observam este objeto são reconstruídas automaticamente
/// (`ChangeNotifier`).
class PlotterCrud extends ChangeNotifier {
  PlotterCrud(this._db);

  final Database _db;

  List<Talhao> _talhoes = const [];
  List<Registro> _registros = const [];

  /// Abre o banco e já carrega os dados gravados (recuperação dos dados ao
  /// reiniciar o aplicativo).
  static Future<PlotterCrud> abrir({
    DatabaseFactory? factory,
    String? caminho,
    bool popularDadosIniciais = true,
  }) async {
    final db = await DatabaseHelper.abrir(
      factory: factory,
      caminho: caminho,
      popularDadosIniciais: popularDadosIniciais,
    );
    final crud = PlotterCrud(db);
    await crud.carregar();
    return crud;
  }

  // ---------------------------------------------------------------------
  // Leitura
  // ---------------------------------------------------------------------

  List<Talhao> get talhoes => List.unmodifiable(_talhoes);

  /// Todos os registros, do mais recente para o mais antigo.
  List<Registro> get registros => List.unmodifiable(_registros);

  /// Aplicações já feitas (data até hoje), da mais recente para a mais antiga.
  List<Registro> get realizadas =>
      _registros.where((r) => !r.agendado).toList(growable: false);

  /// Aplicações agendadas (data futura), da mais próxima para a mais distante.
  List<Registro> get agendadas =>
      _registros.where((r) => r.agendado).toList(growable: false).reversed.toList();

  /// Relê as duas tabelas do banco e avisa as telas.
  Future<void> carregar() async {
    final linhasTalhoes = await _db.query('talhoes', orderBy: 'id');
    final linhasRegistros =
        await _db.query('registros', orderBy: 'data DESC, id DESC');

    _talhoes = linhasTalhoes.map(Talhao.fromMap).toList(growable: false);
    _registros = linhasRegistros.map(Registro.fromMap).toList(growable: false);
    notifyListeners();
  }

  Talhao? buscarTalhao(int id) {
    for (final talhao in _talhoes) {
      if (talhao.id == id) return talhao;
    }
    return null;
  }

  List<Registro> registrosDoTalhao(int talhaoId) =>
      _registros.where((r) => r.talhaoId == talhaoId).toList(growable: false);

  /// Última aplicação realizada no talhão, ou `null` se não houver.
  Registro? ultimaAplicacao(int talhaoId) {
    for (final registro in realizadas) {
      if (registro.talhaoId == talhaoId) return registro;
    }
    return null;
  }

  /// Próxima aplicação agendada para o talhão, ou `null` se não houver.
  Registro? proximaAplicacao(int talhaoId) {
    for (final registro in agendadas) {
      if (registro.talhaoId == talhaoId) return registro;
    }
    return null;
  }

  /// Resumo em texto ("Fungicida - 12/09/2026") usado nos cartões e no
  /// detalhe do talhão.
  String resumoUltimaAplicacao(int talhaoId) =>
      _resumo(ultimaAplicacao(talhaoId), 'Nenhuma aplicação registrada');

  String resumoProximaAplicacao(int talhaoId) =>
      _resumo(proximaAplicacao(talhaoId), 'Nenhuma aplicação agendada');

  static String _resumo(Registro? registro, String vazio) => registro == null
      ? vazio
      : '${registro.insumo} - ${registro.dataFormatada}';

  // ---------------------------------------------------------------------
  // Talhões: criação, atualização e remoção
  // ---------------------------------------------------------------------

  /// Grava um novo talhão e devolve-o já com o id gerado pelo banco.
  Future<Talhao> inserirTalhao(Talhao talhao) async {
    final id = await _db.insert('talhoes', talhao.toMap()..remove('id'));
    await carregar();
    return talhao.copyWith(id: id);
  }

  Future<void> atualizarTalhao(Talhao talhao) async {
    final alterados = await _db.update(
      'talhoes',
      talhao.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [_idObrigatorio(talhao.id)],
    );
    if (alterados == 0) throw StateError('Talhão não encontrado no banco.');
    await carregar();
  }

  /// Remove o talhão e, pelo ON DELETE CASCADE, todos os registros dele.
  /// Devolve quantos registros foram removidos junto.
  Future<int> removerTalhao(int id) async {
    final registrosRemovidos = registrosDoTalhao(id).length;
    await _db.delete('talhoes', where: 'id = ?', whereArgs: [id]);
    await carregar();
    return registrosRemovidos;
  }

  // ---------------------------------------------------------------------
  // Registros: criação, atualização e remoção
  // ---------------------------------------------------------------------

  Future<Registro> inserirRegistro(Registro registro) async {
    final id = await _db.insert('registros', registro.toMap()..remove('id'));
    await carregar();
    return registro.copyWith(id: id);
  }

  Future<void> atualizarRegistro(Registro registro) async {
    final alterados = await _db.update(
      'registros',
      registro.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [_idObrigatorio(registro.id)],
    );
    if (alterados == 0) throw StateError('Registro não encontrado no banco.');
    await carregar();
  }

  Future<void> removerRegistro(int id) async {
    await _db.delete('registros', where: 'id = ?', whereArgs: [id]);
    await carregar();
  }

  /// Fecha a conexão com o banco (usado pelos testes ao simular o
  /// encerramento do aplicativo).
  Future<void> fechar() => _db.close();

  static int _idObrigatorio(int? id) {
    if (id == null) {
      throw ArgumentError('Só é possível atualizar um item já gravado.');
    }
    return id;
  }
}

/// Disponibiliza o [PlotterCrud] para toda a árvore de widgets.
///
/// As telas que usam [of] são reconstruídas sempre que os dados mudam; os
/// callbacks (botões, gravações) usam [read], que não cria essa dependência.
class PlotterCrudScope extends InheritedNotifier<PlotterCrud> {
  const PlotterCrudScope({
    super.key,
    required PlotterCrud crud,
    required super.child,
  }) : super(notifier: crud);

  static PlotterCrud of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlotterCrudScope>();
    assert(scope != null, 'PlotterCrudScope não encontrado na árvore.');
    return scope!.notifier!;
  }

  static PlotterCrud read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<PlotterCrudScope>();
    assert(scope != null, 'PlotterCrudScope não encontrado na árvore.');
    return scope!.notifier!;
  }
}
