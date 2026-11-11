import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../theme/app_theme.dart';
import 'account_screen.dart';
import 'login_screen.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await ApiService.clearToken();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ZELOOS',
      applicationVersion: 'Versão ${AppConfig.appVersion}',
      applicationIcon: Icon(
        Icons.location_on_rounded,
        color: context.palette.accent,
        size: 40,
      ),
      children: const [
        Text(
          'Aplicativo de acompanhamento de pulseiras localizadoras infantis, '
          'desenvolvido como Trabalho de Conclusão de Curso.',
        ),
      ],
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidade e dados'),
        content: const SingleChildScrollView(
          child: Text(
            'O ZELOOS coleta apenas os dados necessários para o funcionamento '
            'do serviço: dados da conta do responsável, perfis das crianças e '
            'localizações enviadas pelas pulseiras.\n\n'
            'Essas informações são usadas exclusivamente para exibir a '
            'localização e gerar alertas de segurança, e não são '
            'compartilhadas com terceiros.\n\n'
            'Em conformidade com a LGPD (Lei nº 13.709/2018), o responsável '
            'pode solicitar a correção ou exclusão dos seus dados a qualquer '
            'momento.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações do app')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const _Section('Aparência'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label(
                          icon: Icons.palette_outlined,
                          title: 'Tema',
                          subtitle: 'Escolha como o aplicativo será exibido.',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_rounded),
                                label: Text('Claro'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_rounded),
                                label: Text('Escuro'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto_rounded),
                                label: Text('Sistema'),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (value) =>
                                settings.setThemeMode(value.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _Section('Mapa'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label(
                          icon: Icons.update_rounded,
                          title: 'Atualização da localização',
                          subtitle:
                              'Intervalos menores mostram a posição mais rápido, '
                              'mas consomem mais internet.',
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<int>(
                            segments: [
                              for (final seconds
                                  in AppSettings.mapIntervalOptions)
                                ButtonSegment(
                                  value: seconds,
                                  label: Text(
                                    seconds < 60
                                        ? '${seconds}s'
                                        : '${seconds ~/ 60} min',
                                  ),
                                ),
                            ],
                            selected: {settings.mapRefreshSeconds},
                            onSelectionChanged: (value) =>
                                settings.setMapRefreshSeconds(value.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _Section('Conta'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: const Text('Minha conta'),
                        subtitle: const Text('Nome, e-mail e telefone'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AccountScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFD64545),
                        ),
                        title: const Text(
                          'Sair da conta',
                          style: TextStyle(
                            color: Color(0xFFD64545),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => _logout(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _Section('Sobre'),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('Sobre o ZELOOS'),
                        subtitle: const Text('Versão ${AppConfig.appVersion}'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showAbout(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Privacidade e dados'),
                        subtitle: const Text('Como suas informações são usadas'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showPrivacy(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.title,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: context.palette.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.palette.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: context.palette.muted, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
