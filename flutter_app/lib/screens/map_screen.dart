import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/pulseira.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'pulseira_map_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Pulseira> _pulseiras = [];
  List<ChildProfile> _children = [];
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
        ApiService.fetchPulseiras(),
        ApiService.fetchChildren(),
      ]);
      if (!mounted) return;
      setState(() {
        _pulseiras = results[0] as List<Pulseira>;
        _children = results[1] as List<ChildProfile>;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMap(Pulseira pulseira) async {
    final children = _children.where((item) => item.id == pulseira.criancaId);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PulseiraMapScreen(
          pulseira: pulseira,
          childName: children.isEmpty ? null : children.first.nome,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _message(
              icon: Icons.cloud_off_rounded,
              message: 'Não foi possível carregar as pulseiras.\n$_error',
              action: _load,
            )
          : _pulseiras.isEmpty
          ? _message(
              icon: Icons.location_off_rounded,
              message: 'Cadastre uma pulseira para acompanhar a localização no mapa.',
              action: _load,
              actionLabel: 'Atualizar',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Escolha uma pulseira para abrir sua localização.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 12),
                  ..._pulseiras.map((pulseira) {
                    final child = _children.where(
                      (item) => item.id == pulseira.criancaId,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFE9EDFF),
                          child: Icon(Icons.watch_rounded, color: AppTheme.navy),
                        ),
                        title: Text(
                          pulseira.nomeDispositivo ?? pulseira.identificador,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          child.isEmpty ? 'Perfil não vinculado' : child.first.nome,
                        ),
                        trailing: const Icon(Icons.map_outlined),
                        onTap: () => _openMap(pulseira),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _message({
    required IconData icon,
    required String message,
    required VoidCallback action,
    String actionLabel = 'Tentar novamente',
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: action, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
