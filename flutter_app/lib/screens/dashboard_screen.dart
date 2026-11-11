import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../models/child_profile.dart';
import '../models/pulseira.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'alerts_screen.dart';
import 'app_settings_screen.dart';
import 'child_profiles_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'pulseira_map_screen.dart';
import 'pulseira_settings_screen.dart';
import 'pulseiras_screen.dart';

const _green = Color(0xFF2E9E5B);
const _amber = Color(0xFFE09B1A);
const _red = Color(0xFFD64545);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.userName});

  final String? userName;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ChildProfile> _children = [];
  List<Pulseira> _pulseiras = [];
  List<Alerta> _alerts = [];
  late String? _userName = widget.userName;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.fetchChildren(),
        ApiService.fetchPulseiras(),
        ApiService.fetchAlerts(),
        ApiService.fetchMe(),
      ]);
      if (!mounted) return;
      setState(() {
        _userName = (results[3] as Map<String, dynamic>)['nome'] as String?;
        _children = results[0] as List<ChildProfile>;
        _pulseiras = results[1] as List<Pulseira>;
        _alerts = (results[2] as List<Alerta>)
          ..sort((a, b) => b.ocorridoEm.compareTo(a.ocorridoEm));
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) await _load();
  }

  Pulseira? _pulseiraOf(ChildProfile child) {
    final items = _pulseiras.where((p) => p.criancaId == child.id);
    return items.isEmpty ? null : items.first;
  }

  int get _newAlerts => _alerts.where((a) => a.status == 'novo').length;

  int get _offline =>
      _pulseiras.where((p) => p.statusConexao != 'conectada').length;

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
            onPressed: () => _open(const AppSettingsScreen()),
            tooltip: 'Configurações do app',
            icon: const Icon(Icons.settings_rounded),
          ),
          IconButton(
            onPressed: _logout,
            tooltip: 'Sair da conta',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorCard(message: _error!, onRetry: _load)
                  else ...[
                    _buildChildrenSection(),
                    const SizedBox(height: 24),
                    _buildSummary(),
                    const SizedBox(height: 28),
                    _buildAlertsSection(),
                  ],
                  const SizedBox(height: 28),
                  _buildShortcuts(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _userName?.trim().split(' ').first;
    final (label, color, icon) = _loading || _error != null
        ? (null, null, null)
        : _newAlerts > 0
        ? (
            _newAlerts == 1 ? '1 alerta novo' : '$_newAlerts alertas novos',
            _red,
            Icons.error_rounded,
          )
        : _offline > 0
        ? (
            _offline == 1
                ? '1 pulseira offline'
                : '$_offline pulseiras offline',
            _amber,
            Icons.wifi_off_rounded,
          )
        : ('Tudo certo', _green, Icons.check_circle_rounded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name == null || name.isEmpty ? 'Olá!' : 'Olá, $name!',
          style: TextStyle(
            color: context.palette.title,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Acompanhe sua família em tempo real.',
          style: TextStyle(color: context.palette.muted, fontSize: 15),
        ),
        if (label != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color!.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChildrenSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Crianças'),
        const SizedBox(height: 12),
        if (_children.isEmpty)
          _EmptyCard(
            icon: Icons.child_care_rounded,
            message: 'Nenhuma criança cadastrada ainda.',
            actionLabel: 'Cadastrar perfil',
            onTap: () => _open(const ChildProfilesScreen()),
          )
        else
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final child = _children[index];
                final pulseira = _pulseiraOf(child);
                return _ChildCard(
                  child: child,
                  pulseira: pulseira,
                  onMap: pulseira == null
                      ? () => _open(const PulseirasScreen())
                      : () => _open(
                          PulseiraMapScreen(
                            pulseira: pulseira,
                            childName: child.nome,
                          ),
                        ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    final active = _pulseiras.where((p) => p.status == 'ativa').length;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${_children.length}',
            label: _children.length == 1 ? 'criança' : 'crianças',
            icon: Icons.child_care_rounded,
            color: context.palette.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$active',
            label: active == 1 ? 'pulseira ativa' : 'pulseiras ativas',
            icon: Icons.watch_rounded,
            color: _green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: '$_newAlerts',
            label: _newAlerts == 1 ? 'alerta novo' : 'alertas novos',
            icon: Icons.notifications_rounded,
            color: _newAlerts > 0 ? _red : context.palette.muted,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSection() {
    final names = {for (final c in _children) c.id: c.nome};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('Alertas recentes')),
            if (_alerts.isNotEmpty)
              TextButton(
                onPressed: () => _open(const AlertsScreen()),
                child: const Text('Ver todos'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_alerts.isEmpty)
          const _EmptyCard(
            icon: Icons.notifications_none_rounded,
            message: 'Nenhum alerta por aqui. Tudo tranquilo!',
          )
        else
          ..._alerts
              .take(3)
              .map(
                (alerta) => AlertTile(
                  alerta: alerta,
                  childName: names[alerta.criancaId],
                ),
              ),
      ],
    );
  }

  Widget _buildShortcuts() {
    final items = [
      (Icons.watch_rounded, 'Pulseiras', const PulseirasScreen()),
      (Icons.child_care_rounded, 'Perfis', const ChildProfilesScreen()),
      (Icons.tune_rounded, 'Config. pulseira', const PulseiraSettingsScreen()),
      (Icons.map_rounded, 'Mapa', const MapScreen()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Atalhos'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, (icon, label, screen)) in items.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _ShortcutTile(
                  icon: icon,
                  label: label,
                  onTap: () => _open(screen),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.palette.title,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.pulseira,
    required this.onMap,
  });

  final ChildProfile child;
  final Pulseira? pulseira;
  final VoidCallback onMap;

  String get _initials {
    final parts = child.nome.trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    final p = pulseira;
    final online = p?.statusConexao == 'conectada';
    final battery = p?.bateriaPercentual;
    final batteryColor = battery == null
        ? context.palette.muted
        : battery > 50
        ? _green
        : battery > 20
        ? _amber
        : _red;

    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: context.palette.iconBg,
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: context.palette.title,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.palette.title,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p == null
                              ? 'Sem pulseira'
                              : p.ultimaComunicacao == null
                              ? 'Sem comunicação'
                              : 'Visto ${timeAgo(p.ultimaComunicacao!)}',
                          style: TextStyle(
                            color: context.palette.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (p != null)
                Row(
                  children: [
                    _Chip(
                      icon: online
                          ? Icons.wifi_rounded
                          : Icons.wifi_off_rounded,
                      label: online ? 'Online' : 'Offline',
                      color: online ? _green : context.palette.muted,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.battery_std_rounded,
                      label: battery == null
                          ? '--'
                          : '${battery.round()}%',
                      color: batteryColor,
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: onMap,
                  icon: Icon(
                    p == null ? Icons.add_rounded : Icons.location_on_rounded,
                    size: 18,
                  ),
                  label: Text(p == null ? 'Vincular pulseira' : 'Ver no mapa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: context.palette.title,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.palette.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.palette.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: context.palette.title, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.palette.title,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: context.palette.muted, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: context.palette.muted),
              ),
            ),
            if (actionLabel != null)
              TextButton(onPressed: onTap, child: Text(actionLabel!)),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.palette.muted),
            const SizedBox(height: 10),
            Text(
              'Não foi possível carregar os dados.',
              style: TextStyle(
                color: context.palette.title,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
