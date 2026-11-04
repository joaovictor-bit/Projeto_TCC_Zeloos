import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'child_profiles_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'pulseiras_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService.clearToken();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ZELOOS',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
              children: [
                const Text(
                  'Olá, que bom ter você aqui!',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'O que você deseja acessar?',
                  style: TextStyle(color: AppTheme.muted, fontSize: 16),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 480 ? 1 : 2;
                    final tileWidth =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _HomeAction(
                            icon: Icons.watch_rounded,
                            title: 'Editar pulseira',
                            subtitle: 'Cadastrar ou editar dispositivos',
                            onTap: () => _open(context, const PulseirasScreen()),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _HomeAction(
                            icon: Icons.child_care_rounded,
                            title: 'Editar perfil',
                            subtitle: 'Gerenciar perfis da família',
                            onTap: () =>
                                _open(context, const ChildProfilesScreen()),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _HomeAction(
                            icon: Icons.settings_rounded,
                            title: 'Configurações',
                            subtitle: 'Personalizar os alertas',
                            onTap: () => _open(context, const SettingsScreen()),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _HomeAction(
                            icon: Icons.map_rounded,
                            title: 'Mapa',
                            subtitle: 'Acompanhar a localização',
                            onTap: () => _open(context, const MapScreen()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppTheme.navy, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
            ],
          ),
        ),
      ),
    );
  }
}
