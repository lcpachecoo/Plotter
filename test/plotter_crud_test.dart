import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:plotter/data/mock_data.dart';
import 'package:plotter/data/plotter_crud.dart';
import 'package:plotter/models/registro.dart';
import 'package:plotter/models/talhao.dart';

/// Testes da camada de persistência (`PlotterCrud`) sobre um SQLite real.
///
/// O banco é gravado em um arquivo temporário — e não em memória — para que
/// seja possível fechar a conexão e abri-la de novo, simulando o
/// encerramento e a reabertura do aplicativo.
void main() {
  late Directory pasta;
  late String caminho;

  Future<PlotterCrud> abrir({bool popular = false}) => PlotterCrud.abrir(
        factory: databaseFactoryFfi,
        caminho: caminho,
        popularDadosIniciais: popular,
      );

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('plotter_test_');
    caminho = p.join(pasta.path, 'plotter.db');
  });

  tearDown(() => pasta.delete(recursive: true));

  const talhaoExemplo = Talhao(
    nome: 'Talhão 05 - Pivô Leste',
    cultura: 'Soja',
    areaHa: 18.4,
    estagio: 'Vegetativo (V4)',
    pivo: 'Pivô Leste',
  );

  test('primeira abertura grava a carga inicial', () async {
    final crud = await abrir(popular: true);

    expect(crud.talhoes, hasLength(MockData.talhoes.length));
    expect(crud.realizadas, isNotEmpty);
    expect(crud.agendadas, isNotEmpty);
    await crud.fechar();
  });

  test('cria, lê, atualiza e remove um talhão', () async {
    final crud = await abrir();

    final criado = await crud.inserirTalhao(talhaoExemplo);
    expect(criado.id, isNotNull);
    expect(crud.buscarTalhao(criado.id!)?.nome, talhaoExemplo.nome);

    await crud.atualizarTalhao(
      criado.copyWith(cultura: 'Milho', status: TalhaoStatus.feito),
    );
    final atualizado = crud.buscarTalhao(criado.id!)!;
    expect(atualizado.cultura, 'Milho');
    expect(atualizado.status, TalhaoStatus.feito);
    expect(atualizado.pivo, 'Pivô Leste');

    await crud.removerTalhao(criado.id!);
    expect(crud.buscarTalhao(criado.id!), isNull);
    await crud.fechar();
  });

  test('cria, atualiza e remove um registro; separa realizadas e agendadas',
      () async {
    final crud = await abrir();
    final talhao = await crud.inserirTalhao(talhaoExemplo);
    final hoje = DateTime.now();

    final feito = await crud.inserirRegistro(Registro(
      talhaoId: talhao.id!,
      insumo: 'Fungicida',
      tipo: TipoInsumo.defensivo,
      data: hoje.subtract(const Duration(days: 2)),
      quantidade: '0.5 L/ha',
    ));
    final agendado = await crud.inserirRegistro(Registro(
      talhaoId: talhao.id!,
      insumo: 'Ureia',
      tipo: TipoInsumo.fertilizante,
      data: hoje.add(const Duration(days: 5)),
      quantidade: '150 kg/ha',
    ));

    expect(crud.realizadas.map((r) => r.id), [feito.id]);
    expect(crud.agendadas.map((r) => r.id), [agendado.id]);
    expect(crud.resumoUltimaAplicacao(talhao.id!), startsWith('Fungicida - '));
    expect(crud.resumoProximaAplicacao(talhao.id!), startsWith('Ureia - '));

    await crud.atualizarRegistro(feito.copyWith(quantidade: '0.7 L/ha'));
    expect(
      crud.registros.firstWhere((r) => r.id == feito.id).quantidade,
      '0.7 L/ha',
    );

    await crud.removerRegistro(agendado.id!);
    expect(crud.agendadas, isEmpty);
    expect(crud.resumoProximaAplicacao(talhao.id!), 'Nenhuma aplicação agendada');
    await crud.fechar();
  });

  test('remover o talhão apaga os registros dele (ON DELETE CASCADE)',
      () async {
    final crud = await abrir();
    final talhao = await crud.inserirTalhao(talhaoExemplo);
    await crud.inserirRegistro(Registro(
      talhaoId: talhao.id!,
      insumo: 'Herbicida',
      tipo: TipoInsumo.defensivo,
      data: DateTime.now(),
      quantidade: '2 L/ha',
    ));

    final removidos = await crud.removerTalhao(talhao.id!);

    expect(removidos, 1);
    expect(crud.registros, isEmpty);
    await crud.fechar();
  });

  test('os dados continuam disponíveis após fechar e reabrir o banco',
      () async {
    // 1ª "execução" do app: grava um talhão e um registro.
    final primeira = await abrir();
    final talhao = await primeira.inserirTalhao(talhaoExemplo);
    await primeira.inserirRegistro(Registro(
      talhaoId: talhao.id!,
      insumo: 'Inseticida',
      tipo: TipoInsumo.defensivo,
      data: DateTime(2026, 9, 12),
      quantidade: '0.3 L/ha',
      responsavel: 'João Operador',
      observacoes: 'Vento fraco',
    ));
    await primeira.fechar();

    // 2ª "execução": um objeto novo, lendo apenas o que está no arquivo.
    final segunda = await abrir();

    expect(segunda.talhoes, hasLength(1));
    expect(segunda.talhoes.single.nome, talhaoExemplo.nome);
    final registro = segunda.registros.single;
    expect(registro.talhaoId, talhao.id);
    expect(registro.data, DateTime(2026, 9, 12));
    expect(registro.responsavel, 'João Operador');
    expect(registro.observacoes, 'Vento fraco');
    await segunda.fechar();
  });

  test('a carga inicial não é repetida ao reabrir o banco', () async {
    final primeira = await abrir(popular: true);
    await primeira.removerTalhao(primeira.talhoes.first.id!);
    await primeira.fechar();

    final segunda = await abrir(popular: true);
    expect(segunda.talhoes, hasLength(MockData.talhoes.length - 1));
    await segunda.fechar();
  });
}
