import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../state/lembretes.dart';

/// Recurso nativo da Etapa 7: notificações locais do Android e do iOS.
///
/// Os lembretes são agendados **no próprio aparelho**. Quem os entrega é o
/// sistema operacional, mesmo com o app fechado e sem internet, o que
/// combina com o uso em campo. Toda a conversa com o plugin
/// `flutter_local_notifications` fica nesta classe. O resto do app só
/// conhece a interface [CanalNotificacoes].
class NotificacoesLocais implements CanalNotificacoes {
  NotificacoesLocais([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Canal de notificação do Android: aparece com este nome nas
  /// configurações do sistema, onde o usuário pode silenciá-lo.
  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes_aplicacoes',
      'Lembretes de aplicações',
      channelDescription: 'Aviso no dia de cada aplicação de insumo agendada',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> inicializar({
    required void Function(int talhaoId) aoTocar,
  }) async {
    // O Plotter é um app para celular: as outras plataformas ficam sem
    // lembretes, e o app avisa que o recurso está indisponível.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return false;
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // No iOS a permissão não é pedida ao abrir o app, e sim quando o
        // usuário liga os lembretes em Ajustes.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (resposta) {
        final talhaoId = int.tryParse(resposta.payload ?? '');
        if (talhaoId != null) aoTocar(talhaoId);
      },
    );
    // No iOS o valor devolvido por `initialize` é a resposta a um pedido de
    // permissão (aqui, nenhum). Chegar até aqui sem erro já indica que o
    // recurso existe.
    return true;
  }

  @override
  Future<int?> talhaoQueAbriuOApp() async {
    final detalhes = await _plugin.getNotificationAppLaunchDetails();
    if (detalhes == null || !detalhes.didNotificationLaunchApp) return null;
    return int.tryParse(detalhes.notificationResponse?.payload ?? '');
  }

  @override
  Future<bool> permissaoConcedida() async {
    final android = _android;
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    final ios = _ios;
    if (ios != null) return (await ios.checkPermissions())?.isEnabled ?? false;
    return false;
  }

  @override
  Future<bool> pedirPermissao() async {
    // Android 13+: diálogo POST_NOTIFICATIONS. Em versões anteriores a
    // permissão é concedida na instalação e a chamada devolve `true`.
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<void> agendar(Lembrete lembrete) {
    return _plugin.zonedSchedule(
      id: lembrete.id,
      title: lembrete.titulo,
      body: lembrete.corpo,
      // O horário já foi calculado no fuso do aparelho. Convertido para UTC,
      // ele aponta para o mesmo instante, sem precisar carregar a base de
      // fusos horários.
      scheduledDate: tz.TZDateTime.from(lembrete.quando, tz.UTC),
      notificationDetails: _detalhes,
      // Entrega aproximada (pode atrasar alguns minutos em economia de
      // bateria). Assim o app não precisa da permissão de alarme exato, que
      // o Android 14 só concede a despertadores e agendas.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: '${lembrete.talhaoId}',
    );
  }

  @override
  Future<void> cancelarTodos() => _plugin.cancelAll();

  @override
  Future<void> abrirConfiguracoes() => _plugin.openAppNotificationSettings();
}
