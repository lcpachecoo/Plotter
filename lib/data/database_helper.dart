import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'mock_data.dart';

/// Abertura e criação do banco SQLite local (`plotter.db`).
///
/// O arquivo fica na pasta de dados privada do aplicativo, e por isso
/// continua existindo depois que o app é fechado ou o aparelho reiniciado —
/// só é apagado ao desinstalar o app ou limpar os dados dele.
class DatabaseHelper {
  DatabaseHelper._();

  static const String nomeArquivo = 'plotter.db';

  /// Versão do esquema. Ao mudar as tabelas em etapas futuras, basta
  /// incrementá-la e tratar a migração em `onUpgrade`.
  static const int versao = 1;

  /// Abre o banco, criando as tabelas na primeira execução.
  ///
  /// [factory] e [caminho] existem para os testes automatizados, que usam o
  /// SQLite via FFI e um banco em memória; no aplicativo ficam vazios.
  static Future<Database> abrir({
    DatabaseFactory? factory,
    String? caminho,
    bool popularDadosIniciais = true,
  }) async {
    final fabrica = factory ?? databaseFactory;
    final destino =
        caminho ?? p.join(await fabrica.getDatabasesPath(), nomeArquivo);

    return fabrica.openDatabase(
      destino,
      options: OpenDatabaseOptions(
        version: versao,
        // O SQLite vem com as chaves estrangeiras desligadas; sem isto, o
        // ON DELETE CASCADE de `registros` seria ignorado.
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await _criarTabelas(db);
          if (popularDadosIniciais) await _popular(db);
        },
      ),
    );
  }

  static Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE talhoes (
        id      INTEGER PRIMARY KEY AUTOINCREMENT,
        nome    TEXT    NOT NULL,
        cultura TEXT    NOT NULL,
        area_ha REAL    NOT NULL,
        estagio TEXT    NOT NULL DEFAULT '',
        pivo    TEXT    NOT NULL DEFAULT '',
        status  TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE registros (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        talhao_id   INTEGER NOT NULL
                    REFERENCES talhoes (id) ON DELETE CASCADE,
        insumo      TEXT    NOT NULL,
        tipo        TEXT    NOT NULL,
        data        TEXT    NOT NULL,
        quantidade  TEXT    NOT NULL,
        responsavel TEXT    NOT NULL DEFAULT '',
        observacoes TEXT    NOT NULL DEFAULT ''
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_registros_talhao ON registros (talhao_id)',
    );
  }

  /// Grava a carga inicial em uma única transação: ou entra tudo, ou nada.
  static Future<void> _popular(Database db) async {
    await db.transaction((txn) async {
      final ids = <int>[];
      for (final talhao in MockData.talhoes) {
        final mapa = talhao.toMap()..remove('id');
        ids.add(await txn.insert('talhoes', mapa));
      }

      final agora = DateTime.now();
      final hoje = DateTime(agora.year, agora.month, agora.day);
      for (final registro in MockData.registros(ids, hoje)) {
        final mapa = registro.toMap()..remove('id');
        await txn.insert('registros', mapa);
      }
    });
  }
}
