import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plotter/data/plotter_api.dart';
import 'package:plotter/data/plotter_crud.dart';
import 'package:plotter/models/registro.dart';
import 'package:plotter/models/talhao.dart';

/// Testes da integração app ↔ backend (Etapa 5).
///
/// O servidor é simulado por um [MockClient] que guarda os dados em memória
/// e responde como a API real (mesmas rotas, mesmo JSON, mesmos códigos).
/// O banco local é um SQLite em memória.
void main() {
  late _ServidorFalso servidor;

  Future<PlotterCrud> abrir({http.Client? client}) => PlotterCrud.abrir(
        factory: databaseFactoryFfiNoIsolate,
        caminho: inMemoryDatabasePath,
        popularDadosIniciais: false,
        api: PlotterApi(
          baseUrl: 'http://api.teste',
          client: client ?? MockClient(servidor.responder),
        ),
      );

  setUp(() => servidor = _ServidorFalso());

  const talhaoNovo = Talhao(
    nome: 'Talhão 05 - Pivô Leste',
    cultura: 'Soja',
    areaHa: 18.4,
  );

  test('sincronizar substitui a cópia local pelos dados do servidor', () async {
    servidor.talhoes[7] = {
      'id': 7, 'nome': 'Talhão do servidor', 'cultura': 'Milho',
      'areaHa': 30.0, 'estagio': '', 'pivo': '', 'status': 'feito',
    };
    servidor.registros[3] = {
      'id': 3, 'talhaoId': 7, 'insumo': 'Ureia', 'tipo': 'fertilizante',
      'data': '2026-01-15', 'quantidade': '180 kg/ha',
      'responsavel': '', 'observacoes': '',
    };
    final crud = await abrir();
    expect(crud.status, StatusServidor.verificando);

    await crud.sincronizar();

    expect(crud.status, StatusServidor.conectado);
    expect(crud.ultimaSincronizacao, isNotNull);
    expect(crud.talhoes.single.id, 7);
    expect(crud.registros.single.data, DateTime(2026, 1, 15));
    expect(crud.resumoUltimaAplicacao(7), 'Ureia - 15/01/2026');
    await crud.fechar();
  });

  test('fluxo criar → alterar → excluir passa pelo servidor', () async {
    final crud = await abrir();

    final criado = await crud.inserirTalhao(talhaoNovo);
    expect(criado.id, servidor.talhoes.keys.single,
        reason: 'o id local deve ser o gerado pelo servidor');
    expect(crud.talhoes.single.nome, talhaoNovo.nome);

    final registro = await crud.inserirRegistro(Registro(
      talhaoId: criado.id!,
      insumo: 'Fungicida',
      tipo: TipoInsumo.defensivo,
      data: DateTime(2026, 3, 1),
      quantidade: '0.5 L/ha',
    ));
    expect(servidor.registros[registro.id]!['data'], '2026-03-01');

    await crud.atualizarTalhao(criado.copyWith(status: TalhaoStatus.feito));
    expect(servidor.talhoes[criado.id]!['status'], 'feito');
    expect(crud.talhoes.single.status, TalhaoStatus.feito);

    final removidos = await crud.removerTalhao(criado.id!);
    expect(removidos, 1);
    expect(servidor.talhoes, isEmpty);
    expect(crud.talhoes, isEmpty);
    expect(crud.registros, isEmpty);
    await crud.fechar();
  });

  test('sem conexão: gravação falha, cópia local fica intacta e status vira offline',
      () async {
    final crud = await abrir();
    await crud.inserirTalhao(talhaoNovo);

    servidor.foraDoAr = true;
    await expectLater(
      crud.inserirTalhao(talhaoNovo.copyWith(nome: 'Outro')),
      throwsA(isA<ApiException>()
          .having((e) => e.semConexao, 'semConexao', isTrue)
          .having((e) => e.mensagem, 'mensagem', contains('Sem conexão'))),
    );
    expect(crud.status, StatusServidor.offline);
    expect(crud.talhoes, hasLength(1));

    await expectLater(crud.sincronizar(), throwsA(isA<ApiException>()));
    expect(crud.talhoes, hasLength(1),
        reason: 'a cópia local continua disponível sem internet');

    servidor.foraDoAr = false;
    await crud.sincronizar();
    expect(crud.status, StatusServidor.conectado);
    await crud.fechar();
  });

  test('erro de validação do servidor vira mensagem por campo', () async {
    final crud = await abrir();
    await expectLater(
      crud.inserirTalhao(talhaoNovo.copyWith(nome: '   ')),
      throwsA(isA<ApiException>()
          .having((e) => e.campos.keys, 'campos', ['nome'])
          .having((e) => e.mensagem, 'mensagem', 'Informe o nome do talhão.')),
    );
    expect(crud.status, StatusServidor.conectado,
        reason: 'o servidor respondeu, só recusou os dados');
    expect(crud.talhoes, isEmpty);
    await crud.fechar();
  });

  test('item removido por outro aparelho gera aviso de 404', () async {
    final crud = await abrir();
    final criado = await crud.inserirTalhao(talhaoNovo);
    servidor.talhoes.clear();

    await expectLater(
      crud.atualizarTalhao(criado.copyWith(cultura: 'Milho')),
      throwsA(isA<ApiException>().having(
          (e) => e.mensagem, 'mensagem', contains('não existe mais'))),
    );
    await crud.fechar();
  });

  test('tempo esgotado é tratado como falta de conexão', () async {
    final lento = MockClient((_) => Future.delayed(
        const Duration(seconds: 1), () => http.Response('[]', 200)));
    final api = PlotterApi(
      baseUrl: 'http://api.teste',
      client: lento,
      tempoLimite: const Duration(milliseconds: 50),
    );

    await expectLater(
      api.listarTalhoes(),
      throwsA(isA<ApiException>()
          .having((e) => e.semConexao, 'semConexao', isTrue)
          .having((e) => e.mensagem, 'mensagem', contains('demorou'))),
    );
  });

  test('erro interno do servidor não expõe detalhes técnicos', () async {
    final quebrado = MockClient((_) async =>
        http.Response(jsonEncode({'erro': 'stack trace...'}), 500));
    final api = PlotterApi(baseUrl: 'http://api.teste', client: quebrado);

    await expectLater(
      api.listarRegistros(),
      throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem',
          'O servidor encontrou um erro. Tente novamente em instantes.')),
    );
  });
}

/// Imita as rotas da API (`backend/src/routes`) guardando tudo em mapas.
class _ServidorFalso {
  final talhoes = <int, Map<String, Object?>>{};
  final registros = <int, Map<String, Object?>>{};
  bool foraDoAr = false;
  int _proximoId = 1;

  Future<http.Response> responder(http.Request req) async {
    if (foraDoAr) throw http.ClientException('Connection refused', req.url);

    final partes = req.url.pathSegments;
    final colecao = partes.first == 'talhoes' ? talhoes : registros;
    final id = partes.length > 1 ? int.parse(partes[1]) : null;
    final corpo = req.body.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(req.body) as Map<String, Object?>;

    switch ((req.method, id)) {
      case ('GET', null):
        return _json(colecao.values.toList());
      case ('POST', null):
        if (partes.first == 'talhoes' &&
            (corpo['nome'] as String).trim().isEmpty) {
          return _json({
            'erro': 'Dados inválidos. Revise os campos informados.',
            'campos': {'nome': 'Informe o nome do talhão.'},
          }, 400);
        }
        final novoId = _proximoId++;
        colecao[novoId] = {...corpo, 'id': novoId};
        return _json(colecao[novoId], 201);
      case ('PUT', final int id):
        if (!colecao.containsKey(id)) return _naoEncontrado();
        colecao[id] = {...corpo, 'id': id};
        return _json(colecao[id]);
      case ('DELETE', final int id):
        if (colecao.remove(id) == null) return _naoEncontrado();
        if (partes.first == 'registros') return http.Response('', 204);
        final antes = registros.length;
        registros.removeWhere((_, r) => r['talhaoId'] == id);
        return _json({'registrosRemovidos': antes - registros.length});
    }
    return _naoEncontrado();
  }

  static http.Response _json(Object? dados, [int status = 200]) =>
      http.Response.bytes(utf8.encode(jsonEncode(dados)), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  static http.Response _naoEncontrado() =>
      _json({'erro': 'Não encontrado.'}, 404);
}
