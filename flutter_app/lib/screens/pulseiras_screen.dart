import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/pulseira.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'pulseira_form_screen.dart';
import 'pulseira_map_screen.dart';

class PulseirasScreen extends StatefulWidget {
  const PulseirasScreen({super.key});

  @override
  State<PulseirasScreen> createState() => _PulseirasScreenState();
}

class _PulseirasScreenState extends State<PulseirasScreen> {
  List<Pulseira> _pulseiras = [];
  List<ChildProfile> _children = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _openForm([Pulseira? pulseira]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PulseiraFormScreen(pulseira: pulseira),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _remove(Pulseira pulseira) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover pulseira?'),
        content: Text(
          'A pulseira "${pulseira.nomeDispositivo ?? pulseira.identificador}" será desativada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deletePulseira(pulseira.id);
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível remover: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas pulseiras'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova pulseira'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _pulseiras.isEmpty
                  ? _emptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          Text(
                            '${_pulseiras.length} ${_pulseiras.length == 1 ? 'dispositivo cadastrado' : 'dispositivos cadastrados'}',
                            style: TextStyle(
                              color: context.palette.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._pulseiras.map(_pulseiraCard),
                        ],
                      ),
                    ),
    );
  }

  Widget _pulseiraCard(Pulseira pulseira) {
    final child = _children.where((item) => item.id == pulseira.criancaId);
    final connected = pulseira.statusConexao == 'conectada';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.palette.iconBg,
                  child: Icon(Icons.watch_rounded, color: context.palette.title),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pulseira.nomeDispositivo ?? pulseira.identificador,
                        style: TextStyle(
                          color: context.palette.title,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        child.isEmpty ? 'Perfil infantil' : child.first.nome,
                        style: TextStyle(color: context.palette.muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: connected
                      ? const Color(0xFF25855A)
                      : const Color(0xFFB54747),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info(Icons.tag_rounded, pulseira.identificador),
                if (pulseira.modelo != null && pulseira.modelo!.isNotEmpty)
                  _info(Icons.devices_other_rounded, pulseira.modelo!),
                _info(
                  Icons.battery_std_rounded,
                  pulseira.bateriaPercentual == null
                      ? 'Bateria sem dados'
                      : '${pulseira.bateriaPercentual!.round()}% de bateria',
                ),
                _info(
                  Icons.circle_rounded,
                  connected ? 'Conectada' : 'Aguardando sinal',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PulseiraMapScreen(
                          pulseira: pulseira,
                          childName: child.isEmpty ? null : child.first.nome,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Ver mapa'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => _openForm(pulseira),
                  tooltip: 'Editar pulseira',
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => _remove(pulseira),
                  tooltip: 'Remover pulseira',
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.palette.muted),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: context.palette.muted, fontSize: 12)),
      ],
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.watch_off_outlined, size: 56, color: context.palette.muted),
            const SizedBox(height: 14),
            Text(
              'Nenhuma pulseira cadastrada',
              style: TextStyle(
                color: context.palette.title,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre o identificador do dispositivo para começar a acompanhar as localizações.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Cadastrar pulseira'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.muted),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar as pulseiras.\n$_error',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.palette.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
