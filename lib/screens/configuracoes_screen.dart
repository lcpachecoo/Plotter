import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tela de Configurações/Sincronização: status offline/online e
/// sincronização manual dos dados com o servidor.
class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppTheme.lightGreen.withValues(alpha: 0.15),
                child: const ListTile(
                  leading: Icon(Icons.cloud_done_outlined, color: AppTheme.primaryGreen),
                  title: Text('Conectado'),
                  subtitle: Text('Últimos dados sincronizados às 07:42'),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.sync),
                  title: const Text('Sincronizar agora'),
                  subtitle: const Text('Envia os registros pendentes ao servidor'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sincronização iniciada.')),
                  ),
                ),
              ),
              const Divider(height: 32),
              const _SectionLabel('Conta'),
              Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Perfil'),
                      subtitle: Text('Produtor · Fazenda Modelo'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
                      onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              const _SectionLabel('Preferências'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Notificações push'),
                      value: true,
                      onChanged: (_) {},
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.wifi_off_outlined),
                      title: const Text('Modo economia de dados'),
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
      ),
    );
  }
}
