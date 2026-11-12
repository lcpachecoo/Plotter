import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plotter/data/plotter_api.dart';
import 'package:plotter/data/plotter_crud.dart';
import 'package:plotter/models/registro.dart';
import 'package:plotter/screens/novo_registro_screen.dart';
import 'package:plotter/theme/app_theme.dart';
import 'package:plotter/widgets/previsao_tempo_card.dart';

/// Testes da integração com o serviço de previsão do tempo (Etapa 6).
///
/// O backend é simulado por um [MockClient] que responde à rota
/// `GET /clima/previsao` com o mesmo JSON da API real (que, por sua vez,
/// resume a resposta do OpenWeatherMap).
void main() {
  final hoje = DateUtils.dateOnly(DateTime.now());
  final amanha = hoje.add(const Duration(days: 1));

  late _ServidorFalso servidor;
  late PlotterCrud crud;

  setUp(() async {
    servidor = _ServidorFalso(_previsaoJson([
      _diaJson(hoje, adequada: true, motivo: 'Janela favorável: 06h–12h.'),
      _diaJson(amanha,
          adequada: false,
          motivo: 'Vento acima de 10 km/h: risco de deriva do produto.',
          descricao: 'Chuva leve',
          icone: '10d',
          chuvaMm: 3.2,
          probChuva: 80),
    ]));
    crud = await PlotterCrud.abrir(
      factory: databaseFactoryFfiNoIsolate,
      caminho: inMemoryDatabasePath,
      popularDadosIniciais: false,
      api: PlotterApi(
        baseUrl: 'http://api.teste',
        client: MockClient(servidor.responder),
      ),
    );
  });

  tearDown(() => crud.fechar());

  group('cliente da API', () {
    test('consulta GET /clima/previsao e converte o JSON', () async {
      final previsao = await crud.previsaoDoTempo();

      expect(servidor.pedidos.single.method, 'GET');
      expect(servidor.pedidos.single.url.path, '/clima/previsao');
      expect(previsao.fonte, 'OpenWeatherMap');
      expect(previsao.local, 'Rio Verde');
      expect(previsao.dias, hasLength(2));

      final dia = previsao.doDia(amanha)!;
      expect(dia.adequada, isFalse);
      expect(dia.descricao, 'Chuva leve');
      expect(dia.faixaTemperatura, '18–29 °C');
      expect(dia.resumoChuvaVento, 'Chuva 80% (3,2 mm) · Vento 14 km/h');
      expect(previsao.doDia(hoje.add(const Duration(days: 9))), isNull);
      expect(crud.status, StatusServidor.conectado);
    });

    test('reaproveita a previsão recente em vez de consultar de novo', () async {
      await crud.previsaoDoTempo();
      await crud.previsaoDoTempo();
      expect(servidor.pedidos, hasLength(1));
      expect(crud.previsaoRecente, isNotNull);
    });

    test('falha do serviço externo (503) mostra a mensagem do servidor', () async {
      servidor.resposta = () => _json(
          {'erro': 'A previsão do tempo ainda não foi configurada no servidor.'},
          503);

      await expectLater(
        crud.previsaoDoTempo(),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem',
            'A previsão do tempo ainda não foi configurada no servidor.')),
      );
      expect(crud.status, StatusServidor.conectado,
          reason: 'o backend respondeu; quem falhou foi o serviço externo');
      expect(crud.previsaoRecente, isNull, reason: 'erro não fica guardado');
    });

    test('JSON em formato inesperado vira resposta inválida', () async {
      servidor.resposta = () => _json({'dias': 'nenhum'});

      await expectLater(
        crud.previsaoDoTempo(),
        throwsA(isA<ApiException>().having((e) => e.mensagem, 'mensagem',
            'O servidor enviou uma resposta inválida.')),
      );
    });

    test('sem servidor configurado a previsão fica indisponível', () async {
      final local = await PlotterCrud.abrir(
        factory: databaseFactoryFfiNoIsolate,
        caminho: inMemoryDatabasePath,
        popularDadosIniciais: false,
      );
      expect(local.previsaoDisponivel, isFalse);
      await expectLater(local.previsaoDoTempo(), throwsA(isA<ApiException>()));
      await local.fechar();
    });
  });

  group('cartão do detalhe do talhão', () {
    Future<void> mostrar(WidgetTester tester) => tester.pumpWidget(
          PlotterCrudScope(
            crud: crud,
            child: MaterialApp(
              theme: AppTheme.theme,
              home: const Scaffold(
                body: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: PrevisaoTempoCard(),
                ),
              ),
            ),
          ),
        );

    testWidgets('carregando → sucesso com o selo de cada dia', (tester) async {
      final pendente = Completer<http.Response>();
      servidor.resposta = () => pendente.future;

      await mostrar(tester);
      expect(find.text('Consultando a previsão do tempo…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pendente.complete(_json(servidor.previsao));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Previsão do tempo · Rio Verde'), findsOneWidget);
      expect(find.text('Hoje'), findsOneWidget);
      expect(find.text('Amanhã'), findsOneWidget);
      expect(find.text('Favorável'), findsOneWidget);
      expect(find.text('Evitar'), findsOneWidget);
      expect(find.text('Janela favorável: 06h–12h.'), findsOneWidget);
      expect(find.textContaining('Fonte: OpenWeatherMap'), findsOneWidget);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('erro → mensagem e "Tentar de novo" refaz a consulta',
        (tester) async {
      final previsao = servidor.previsao;
      servidor.resposta = () => _json(
          {'erro': 'O serviço de previsão do tempo está indisponível no momento.'},
          502);

      await mostrar(tester);
      await tester.pumpAndSettle();
      expect(find.text('O serviço de previsão do tempo está indisponível no momento.'),
          findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      servidor.resposta = () => _json(previsao);
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();

      expect(find.text('Tentar de novo'), findsNothing);
      expect(find.text('Hoje'), findsOneWidget);
      expect(servidor.pedidos, hasLength(2));
    });

    testWidgets('sem conexão com o servidor', (tester) async {
      servidor.foraDoAr = true;

      await mostrar(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Sem conexão com o servidor'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(crud.status, StatusServidor.offline);
    });

    testWidgets('ausência de dados → aviso de que não há previsão',
        (tester) async {
      servidor.resposta = () => _json(_previsaoJson(const []));

      await mostrar(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhuma previsão disponível'), findsOneWidget);
      expect(find.text('Consultar de novo'), findsOneWidget);
    });
  });

  group('formulário de registro', () {
    Future<void> abrirComData(WidgetTester tester, DateTime data) =>
        tester.pumpWidget(PlotterCrudScope(
          crud: crud,
          child: MaterialApp(
            theme: AppTheme.theme,
            home: NovoRegistroScreen(
              registro: Registro(
                id: 1,
                talhaoId: 1,
                insumo: 'Fungicida',
                tipo: TipoInsumo.defensivo,
                data: data,
                quantidade: '0.5 L/ha',
              ),
            ),
          ),
        ));

    testWidgets('mostra a previsão da data escolhida', (tester) async {
      await abrirComData(tester, amanha);
      await tester.pumpAndSettle();

      expect(find.text('Previsão para ${formatarData(amanha)}'), findsOneWidget);
      expect(find.text('Evitar'), findsOneWidget);
      expect(find.text('Vento acima de 10 km/h: risco de deriva do produto.'),
          findsOneWidget);
    });

    testWidgets('data além dos 5 dias → aviso de ausência de previsão',
        (tester) async {
      final distante = hoje.add(const Duration(days: 12));
      await abrirComData(tester, distante);
      await tester.pumpAndSettle();

      expect(
        find.text('Sem previsão do tempo para ${formatarData(distante)}: '
            'ela fica disponível apenas para os próximos 5 dias.'),
        findsOneWidget,
      );
    });

    testWidgets('data passada não consulta a previsão', (tester) async {
      await abrirComData(tester, hoje.subtract(const Duration(days: 3)));
      await tester.pumpAndSettle();

      expect(find.byType(PrevisaoDoDiaCard), findsNothing);
      expect(servidor.pedidos, isEmpty);
    });
  });
}

/// Backend simulado: responde a `/clima/previsao` e registra os pedidos.
class _ServidorFalso {
  _ServidorFalso(this.previsao) {
    resposta = () => _json(previsao);
  }

  final Map<String, Object?> previsao;
  late FutureOr<http.Response> Function() resposta;
  final pedidos = <http.Request>[];
  bool foraDoAr = false;

  Future<http.Response> responder(http.Request req) async {
    if (foraDoAr) throw http.ClientException('Connection refused', req.url);
    pedidos.add(req);
    if (req.url.path != '/clima/previsao') {
      return _json({'erro': 'Rota não existe.'}, 404);
    }
    return await resposta();
  }
}

http.Response _json(Object? dados, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(dados)), status,
        headers: {'content-type': 'application/json; charset=utf-8'});

Map<String, Object?> _previsaoJson(List<Map<String, Object?>> dias) => {
      'fonte': 'OpenWeatherMap',
      'local': 'Rio Verde',
      'latitude': -17.79,
      'longitude': -50.92,
      'atualizadoEm': '2026-11-13T15:00:00.000Z',
      'dias': dias,
    };

Map<String, Object?> _diaJson(
  DateTime data, {
  required bool adequada,
  required String motivo,
  String descricao = 'Céu limpo',
  String icone = '01d',
  double chuvaMm = 0,
  int probChuva = 0,
}) {
  String dois(int n) => n.toString().padLeft(2, '0');
  return {
    'data': '${data.year}-${dois(data.month)}-${dois(data.day)}',
    'descricao': descricao,
    'icone': icone,
    'tempMin': 18.2,
    'tempMax': 29.4,
    'umidade': 68,
    'ventoKmh': 14.4,
    'probChuva': probChuva,
    'chuvaMm': chuvaMm,
    'pulverizacao': {
      'adequada': adequada,
      'motivo': motivo,
      'horarios': adequada ? ['06:00', '09:00'] : <String>[],
    },
  };
}
