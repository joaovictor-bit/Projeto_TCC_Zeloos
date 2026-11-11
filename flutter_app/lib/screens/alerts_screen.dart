import 'package:flutter/material.dart';

import '../models/alerta.dart';
import '../models/child_profile.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  return 'há ${diff.inDays} d';
}

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.alerta, this.childName});

  final Alerta alerta;
  final String? childName;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (alerta.tipo) {
      'saida_local' => (Icons.directions_walk_rounded, const Color(0xFFD64545)),
      'entrada_local' => (Icons.home_rounded, const Color(0xFF2E9E5B)),
      'bateria_baixa' => (Icons.battery_alert_rounded, const Color(0xFFE09B1A)),
      'desconexao' => (Icons.wifi_off_rounded, context.palette.muted),
      _ => (Icons.notifications_rounded, context.palette.accent),
    };
    final isNew = alerta.status == 'novo';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          alerta.titulo,
          style: TextStyle(
            color: context.palette.title,
            fontWeight: isNew ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          [
            ?childName,
            if (alerta.mensagem.isNotEmpty) alerta.mensagem,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              timeAgo(alerta.ocorridoEm),
              style: TextStyle(color: context.palette.muted, fontSize: 12),
            ),
            if (isNew) ...[
              const SizedBox(height: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD64545),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alerta> _alerts = [];
  Map<int, String> _childNames = {};
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
        ApiService.fetchAlerts(),
        ApiService.fetchChildren(),
      ]);
      if (!mounted) return;
      setState(() {
        _alerts = (results[0] as List<Alerta>)
          ..sort((a, b) => b.ocorridoEm.compareTo(a.ocorridoEm));
        _childNames = {
          for (final child in results[1] as List<ChildProfile>)
            child.id: child.nome,
        };
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 48, color: context.palette.muted),
                          const SizedBox(height: 12),
                          Text(
                            'Não foi possível carregar os alertas.\n$_error',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    )
                  else if (_alerts.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 48, color: context.palette.muted),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum alerta por aqui. Tudo tranquilo!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.palette.muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._alerts.map(
                      (alerta) => AlertTile(
                        alerta: alerta,
                        childName: _childNames[alerta.criancaId],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
