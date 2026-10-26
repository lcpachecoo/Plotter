import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/registro.dart';
import '../models/talhao.dart';

/// Falha ao falar com o backend, já com uma mensagem pronta para o usuário.
///
/// As telas não precisam conhecer códigos HTTP: basta exibir [mensagem].
class ApiException implements Exception {
  final String mensagem;

  /// Problemas por campo devolvidos pela validação do servidor (status 400).
  final Map<String, String> campos;

  /// `true` quando o servidor não pôde ser alcançado (sem rede, servidor
  /// desligado ou tempo esgotado), e não quando ele recusou o pedido.
  final bool semConexao;

  const ApiException(
    this.mensagem, {
    this.campos = const {},
    this.semConexao = false,
  });

  @override
  String toString() => 'ApiException: $mensagem';
}

/// Mensagem a exibir para um erro qualquer: a da API quando houver, ou
/// [padrao] para falhas inesperadas.
String mensagemDeErro(Object erro, String padrao) =>
    erro is ApiException ? erro.mensagem : padrao;

/// Cliente da API REST do Plotter (pasta `backend/`).
///
/// Cada método corresponde a uma rota e devolve os modelos do app já
/// convertidos do JSON. Qualquer falha vira uma [ApiException].
class PlotterApi {
  PlotterApi({
    String? baseUrl,
    http.Client? client,
    this.tempoLimite = const Duration(seconds: 8),
  })  : baseUrl = baseUrl ?? urlPadrao,
        _client = client ?? http.Client();

  /// Endereço da API, definido na compilação:
  /// `flutter run --dart-define=API_URL=http://192.168.0.10:3000`.
  ///
  /// O padrão `10.0.2.2` é o endereço pelo qual o emulador Android enxerga o
  /// `localhost` do computador onde a API está rodando.
  static const String urlPadrao =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000');

  final String baseUrl;
  final Duration tempoLimite;
  final http.Client _client;

  // -------------------------------------------------------------------------
  // Talhões
  // -------------------------------------------------------------------------

  Future<List<Talhao>> listarTalhoes() async {
    final lista = await _enviar('GET', '/talhoes') as List<Object?>;
    return lista.cast<Map<String, Object?>>().map(Talhao.fromJson).toList();
  }

  Future<Talhao> criarTalhao(Talhao talhao) async =>
      Talhao.fromJson(await _enviar('POST', '/talhoes', talhao.toJson()));

  Future<Talhao> atualizarTalhao(Talhao talhao) async => Talhao.fromJson(
      await _enviar('PUT', '/talhoes/${talhao.id}', talhao.toJson()));

  /// Devolve quantos registros foram removidos junto com o talhão.
  Future<int> removerTalhao(int id) async {
    final resposta = await _enviar('DELETE', '/talhoes/$id');
    return (resposta as Map<String, Object?>)['registrosRemovidos'] as int;
  }

  // -------------------------------------------------------------------------
  // Registros
  // -------------------------------------------------------------------------

  Future<List<Registro>> listarRegistros() async {
    final lista = await _enviar('GET', '/registros') as List<Object?>;
    return lista.cast<Map<String, Object?>>().map(Registro.fromJson).toList();
  }

  Future<Registro> criarRegistro(Registro registro) async =>
      Registro.fromJson(await _enviar('POST', '/registros', registro.toJson()));

  Future<Registro> atualizarRegistro(Registro registro) async =>
      Registro.fromJson(await _enviar(
          'PUT', '/registros/${registro.id}', registro.toJson()));

  Future<void> removerRegistro(int id) => _enviar('DELETE', '/registros/$id');

  // -------------------------------------------------------------------------
  // Comunicação
  // -------------------------------------------------------------------------

  /// Faz a requisição e devolve o corpo da resposta já decodificado.
  Future<dynamic> _enviar(
    String metodo,
    String caminho, [
    Map<String, Object?>? corpo,
  ]) async {
    final requisicao = http.Request(metodo, Uri.parse('$baseUrl$caminho'))
      ..headers['Accept'] = 'application/json';
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }

    final http.Response resposta;
    try {
      resposta = await http.Response.fromStream(
          await _client.send(requisicao).timeout(tempoLimite));
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Verifique a conexão e tente novamente.',
        semConexao: true,
      );
    } on http.ClientException {
      // Sem rede, servidor desligado ou endereço errado.
      throw const ApiException(
        'Sem conexão com o servidor. Verifique a internet e tente novamente.',
        semConexao: true,
      );
    }

    final texto = utf8.decode(resposta.bodyBytes);
    final dados = texto.isEmpty ? null : _decodificar(texto);

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) return dados;
    throw _erroDaResposta(resposta.statusCode, dados);
  }

  static Object? _decodificar(String texto) {
    try {
      return jsonDecode(texto);
    } on FormatException {
      throw const ApiException('O servidor enviou uma resposta inválida.');
    }
  }

  /// Converte a resposta de erro da API (`{erro, campos}`) em exceção.
  static ApiException _erroDaResposta(int status, Object? dados) {
    final mapa = dados is Map<String, Object?> ? dados : const {};
    final campos = (mapa['campos'] as Map<String, Object?>?)
            ?.map((campo, motivo) => MapEntry(campo, '$motivo')) ??
        const <String, String>{};

    final mensagem = switch (status) {
      // Erro de validação: os motivos de cada campo dizem o que corrigir.
      400 when campos.isNotEmpty => campos.values.join(' '),
      404 => 'Este item não existe mais no servidor. Atualize a lista.',
      >= 500 => 'O servidor encontrou um erro. Tente novamente em instantes.',
      _ => mapa['erro'] as String? ?? 'Não foi possível concluir a operação.',
    };
    return ApiException(mensagem, campos: campos);
  }
}
