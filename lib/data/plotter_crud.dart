import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import '../models/registro.dart';
import '../models/talhao.dart';
import 'database_helper.dart';
import 'plotter_api.dart';

/// Situação da comunicação com o backend, exibida em Ajustes e no Dashboard.
enum StatusServidor {
  /// O app funciona só com o banco local (sem [PlotterApi]; usado nos testes).
  semServidor,

  /// Primeira sincronização ainda em andamento.
  verificando,

  /// A última comunicação com a API deu certo.
  conectado,

  /// A API não pôde ser alcançada: o app mostra os dados salvos no aparelho.
  offline,
}

/// Único ponto de acesso aos dados do aplicativo.
///
/// Concentra as operações de criação, leitura, atualização e remoção (CRUD)
/// de talhões e registros. As telas nunca executam SQL nem HTTP: leem as
/// listas expostas aqui e chamam os métodos de gravação.
///
/// Desde a Etapa 5 o **servidor é a fonte oficial dos dados**. Cada gravação
/// vai primeiro para a API; só depois que o servidor confirma ela é copiada
/// para o SQLite, que funciona como cópia local para consulta sem internet.
/// Sem [PlotterApi] (testes da Etapa 4), tudo é gravado só no SQLite.
///
/// Depois de cada gravação as listas são relidas do banco local, de modo que
/// a interface sempre mostra exatamente o que está armazenado, e as telas que
/// observam este objeto são reconstruídas automaticamente (`ChangeNotifier`).
class PlotterCrud extends ChangeNotifier {
  PlotterCrud(this._db, {PlotterApi? api})
      : _api = api,
        _status =
            api == null ? StatusServidor.semServidor : StatusServidor.verificando;

  final Database _db;
  final PlotterApi? _api;

  List<Talhao> _talhoes = const [];
  List<Registro> _registros = const [];

  StatusServidor _status;
  DateTime? _ultimaSincronizacao;

  /// Abre o banco e já carrega os dados gravados (recuperação dos dados ao
  /// reiniciar o aplicativo).
  static Future<PlotterCrud> abrir({
    DatabaseFactory? factory,
    String? caminho,
    bool popularDadosIniciais = true,
    PlotterApi? api,
  }) async {
    final db = await DatabaseHelper.abrir(
      factory: factory,
      caminho: caminho,
      popularDadosIniciais: popularDadosIniciais,
    );
    final crud = PlotterCrud(db, api: api);
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

  StatusServidor get status => _status;

  /// Momento da última sincronização bem-sucedida com o servidor.
  DateTime? get ultimaSincronizacao => _ultimaSincronizacao;

  /// Relê as duas tabelas do banco local e avisa as telas.
  Future<void> carregar() async {
    final linhasTalhoes = await _db.query('talhoes', orderBy: 'id');
    final linhasRegistros =
        await _db.query('registros', orderBy: 'data DESC, id DESC');

    _talhoes = linhasTalhoes.map(Talhao.fromMap).toList(growable: false);
    _registros = linhasRegistros.map(Registro.fromMap).toList(growable: false);
    notifyListeners();
  }

  /// Baixa todos os talhões e registros do servidor e substitui a cópia
  /// local por eles. Sem servidor configurado, apenas relê o banco local.
  ///
  /// Se a API não responder, a cópia local continua intacta (o app segue
  /// mostrando os últimos dados recebidos) e a [ApiException] é repassada
  /// para a tela informar o usuário.
  Future<void> sincronizar() async {
    final api = _api;
    if (api == null) return carregar();

    final (talhoes, registros) = await _chamar(
      () async => (await api.listarTalhoes(), await api.listarRegistros()),
    );

    // Transação: a cópia local nunca fica pela metade.
    await _db.transaction((txn) async {
      await txn.delete('registros');
      await txn.delete('talhoes');
      for (final talhao in talhoes) {
        await txn.insert('talhoes', talhao.toMap());
      }
      for (final registro in registros) {
        await txn.insert('registros', registro.toMap());
      }
    });

    _ultimaSincronizacao = DateTime.now();
    await carregar();
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
    final api = _api;
    final Talhao salvo;
    if (api == null) {
      final id = await _db.insert('talhoes', talhao.toMap()..remove('id'));
      salvo = talhao.copyWith(id: id);
    } else {
      // O id gerado pelo servidor é mantido também na cópia local.
      salvo = await _chamar(() => api.criarTalhao(talhao));
      await _db.insert('talhoes', salvo.toMap());
    }
    await carregar();
    return salvo;
  }

  Future<void> atualizarTalhao(Talhao talhao) async {
    final api = _api;
    final salvo = api == null ? talhao : await _chamar(() => api.atualizarTalhao(talhao));
    final alterados = await _db.update(
      'talhoes',
      salvo.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [_idObrigatorio(talhao.id)],
    );
    if (alterados == 0) throw StateError('Talhão não encontrado no banco.');
    await carregar();
  }

  /// Remove o talhão e, pelo ON DELETE CASCADE, todos os registros dele.
  /// Devolve quantos registros foram removidos junto.
  Future<int> removerTalhao(int id) async {
    final api = _api;
    final registrosRemovidos = api == null
        ? registrosDoTalhao(id).length
        : await _chamar(() => api.removerTalhao(id));
    await _db.delete('talhoes', where: 'id = ?', whereArgs: [id]);
    await carregar();
    return registrosRemovidos;
  }

  // ---------------------------------------------------------------------
  // Registros: criação, atualização e remoção
  // ---------------------------------------------------------------------

  Future<Registro> inserirRegistro(Registro registro) async {
    final api = _api;
    final Registro salvo;
    if (api == null) {
      final id = await _db.insert('registros', registro.toMap()..remove('id'));
      salvo = registro.copyWith(id: id);
    } else {
      salvo = await _chamar(() => api.criarRegistro(registro));
      await _db.insert('registros', salvo.toMap());
    }
    await carregar();
    return salvo;
  }

  Future<void> atualizarRegistro(Registro registro) async {
    final api = _api;
    final salvo =
        api == null ? registro : await _chamar(() => api.atualizarRegistro(registro));
    final alterados = await _db.update(
      'registros',
      salvo.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [_idObrigatorio(registro.id)],
    );
    if (alterados == 0) throw StateError('Registro não encontrado no banco.');
    await carregar();
  }

  Future<void> removerRegistro(int id) async {
    final api = _api;
    if (api != null) await _chamar(() => api.removerRegistro(id));
    await _db.delete('registros', where: 'id = ?', whereArgs: [id]);
    await carregar();
  }

  /// Fecha a conexão com o banco (usado pelos testes ao simular o
  /// encerramento do aplicativo).
  Future<void> fechar() => _db.close();

  /// Executa uma chamada à API mantendo o [status] da conexão atualizado:
  /// qualquer resposta do servidor (mesmo um erro de validação) prova que ele
  /// está acessível; só falhas de conexão o marcam como offline.
  Future<T> _chamar<T>(Future<T> Function() chamada) async {
    try {
      final resultado = await chamada();
      _mudarStatus(StatusServidor.conectado);
      return resultado;
    } on ApiException catch (erro) {
      _mudarStatus(
          erro.semConexao ? StatusServidor.offline : StatusServidor.conectado);
      rethrow;
    }
  }

  void _mudarStatus(StatusServidor novo) {
    if (_status == novo) return;
    _status = novo;
    notifyListeners();
  }

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
