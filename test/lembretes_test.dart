import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plotter/data/plotter_crud.dart';
import 'package:plotter/models/registro.dart';
import 'package:plotter/state/lembretes.dart';
import 'package:plotter/state/preferencias.dart';

import 'canal_notificacoes_falso.dart';

/// Testes dos lembretes de aplicações (recurso nativo da Etapa 7).
///
/// O recurso nativo é substituído por [CanalNotificacoesFalso], o que permite
/// simular permissão negada, permissão retirada, aparelho sem suporte e falha
/// ao agendar. Os dados vêm de um `PlotterCrud` real sobre SQLite em memória,
/// com a carga de exemplo (4 aplicações agendadas).
void main() {
  // `Lembretes` observa o ciclo de vida do app (volta do segundo plano).
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlotterCrud crud;
  late Preferencias preferencias;
  late CanalNotificacoesFalso canal;
  late Lembretes lembretes;

  Lembretes criar({DateTime Function()? relogio}) => Lembretes(
        canal: canal,
        crud: crud,
        preferencias: preferencias,
        relogio: relogio,
      );

  setUp(() async {
    crud = await PlotterCrud.abrir(
      factory: databaseFactoryFfiNoIsolate,
      caminho: inMemoryDatabasePath,
    );
    preferencias = Preferencias.emMemoria();
    canal = CanalNotificacoesFalso();
    lembretes = criar();
  });

  tearDown(() async {
    lembretes.dispose();
    await crud.fechar();
  });

  DateTime seteHorasDo(DateTime dia) =>
      DateTime(dia.year, dia.month, dia.day, Lembretes.horaDoLembrete);

  test('começa desativado, sem pedir permissão nem agendar nada', () async {
    await lembretes.iniciar();

    expect(lembretes.situacao, SituacaoLembretes.desativados);
    expect(canal.pedidosDePermissao, 0);
    expect(canal.agendados, isEmpty);
  });

  test('ativar com permissão agenda um lembrete por aplicação agendada, às 7h',
      () async {
    await lembretes.iniciar();

    final resultado = await lembretes.ativar();

    expect(resultado, ResultadoAtivacao.ativado);
    expect(canal.pedidosDePermissao, 1);
    expect(preferencias.lembretesAtivos, isTrue);
    expect(lembretes.situacao, SituacaoLembretes.ativos);
    expect(crud.agendadas, hasLength(4));
    expect(lembretes.quantidade, 4);

    for (final registro in crud.agendadas) {
      final lembrete = canal.agendados[registro.id]!;
      final talhao = crud.buscarTalhao(registro.talhaoId)!;
      expect(lembrete.quando, seteHorasDo(registro.data));
      expect(lembrete.talhaoId, registro.talhaoId);
      expect(lembrete.corpo, contains(registro.insumo));
      expect(lembrete.corpo, contains(talhao.nome));
    }
  });

  test('permissão negada: nada é agendado e a preferência continua desligada',
      () async {
    canal.concedeAoPedir = false;
    await lembretes.iniciar();

    final resultado = await lembretes.ativar();

    expect(resultado, ResultadoAtivacao.permissaoNegada);
    expect(preferencias.lembretesAtivos, isFalse);
    expect(lembretes.situacao, SituacaoLembretes.desativados);
    expect(canal.agendados, isEmpty);
  });

  test('desativar cancela os lembretes já agendados', () async {
    await lembretes.iniciar();
    await lembretes.ativar();
    expect(canal.agendados, isNotEmpty);

    await lembretes.desativar();

    expect(preferencias.lembretesAtivos, isFalse);
    expect(lembretes.situacao, SituacaoLembretes.desativados);
    expect(canal.agendados, isEmpty);
  });

  test('nova aplicação agendada (e a exclusão dela) atualiza a agenda', () async {
    await lembretes.iniciar();
    await lembretes.ativar();

    final hoje = DateTime.now();
    final novo = await crud.inserirRegistro(Registro(
      talhaoId: crud.talhoes.first.id!,
      insumo: 'Fungicida Novo',
      tipo: TipoInsumo.defensivo,
      data: DateTime(hoje.year, hoje.month, hoje.day + 3),
      quantidade: '1 L/ha',
    ));
    // O lembrete acompanha o PlotterCrud sozinho; `atualizar` só espera a
    // sincronização em andamento terminar.
    await lembretes.atualizar();

    expect(canal.agendados[novo.id]?.corpo, contains('Fungicida Novo'));
    expect(lembretes.quantidade, 5);

    await crud.removerRegistro(novo.id!);
    await lembretes.atualizar();

    expect(canal.agendados.containsKey(novo.id), isFalse);
    expect(lembretes.quantidade, 4);
  });

  test('não agenda lembretes cujo horário já passou', () async {
    // Relógio três dias à frente: a aplicação de daqui a 2 dias já passou.
    lembretes.dispose();
    lembretes = criar(relogio: () => DateTime.now().add(const Duration(days: 3)));
    await lembretes.iniciar();

    await lembretes.ativar();

    expect(lembretes.quantidade, 3);
    expect(
      canal.agendados.values.map((l) => l.corpo),
      isNot(contains(contains('Inseticida'))),
    );
  });

  test('permissão retirada nas configurações: cancela e volta sozinho depois',
      () async {
    await lembretes.iniciar();
    await lembretes.ativar();

    // O usuário bloqueia as notificações nas configurações do sistema e
    // volta ao app.
    canal.permissao = false;
    await lembretes.atualizar();

    expect(lembretes.situacao, SituacaoLembretes.semPermissao);
    expect(canal.agendados, isEmpty);
    expect(preferencias.lembretesAtivos, isTrue,
        reason: 'a escolha do usuário é mantida');

    // Libera de novo e volta ao app: os lembretes retornam sem nova ação.
    canal.permissao = true;
    await lembretes.atualizar();

    expect(lembretes.situacao, SituacaoLembretes.ativos);
    expect(canal.agendados, hasLength(4));
  });

  test('aparelho sem notificações: indisponível, sem derrubar o app', () async {
    canal.disponivel = false;

    await lembretes.iniciar();

    expect(lembretes.situacao, SituacaoLembretes.indisponivel);
    expect(await lembretes.ativar(), ResultadoAtivacao.indisponivel);
    expect(canal.pedidosDePermissao, 0);
  });

  test('falha ao agendar vira situação de falha, e "Tentar de novo" recupera',
      () async {
    await lembretes.iniciar();
    canal.falharAoAgendar = true;

    expect(await lembretes.ativar(), ResultadoAtivacao.falha);
    expect(lembretes.situacao, SituacaoLembretes.falha);

    canal.falharAoAgendar = false;
    await lembretes.tentarDeNovo();

    expect(lembretes.situacao, SituacaoLembretes.ativos);
    expect(canal.agendados, hasLength(4));
  });

  test('não reagenda quando nada que importa mudou', () async {
    await lembretes.iniciar();
    await lembretes.ativar();
    final agendamentosAntes = canal.agendamentos;

    // Ler os avisos muda as Preferencias, mas não a agenda.
    await preferencias.marcarTodosComoLidos(crud.avisos);
    await lembretes.atualizar();

    expect(canal.agendamentos, agendamentosAntes);
  });

  test('toque em um lembrete pede para abrir o talhão, uma única vez', () async {
    canal.talhaoInicial = 3; // app aberto a partir de um lembrete
    await lembretes.iniciar();

    expect(lembretes.talhaoSolicitado.value, 3);
    expect(lembretes.consumirTalhaoSolicitado(), 3);
    expect(lembretes.consumirTalhaoSolicitado(), isNull);

    canal.tocar(7); // toque com o app aberto
    expect(lembretes.talhaoSolicitado.value, 7);
  });
}
