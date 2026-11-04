import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<ChildProfile> _children = [];
  int? _selectedChildId;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _alertaSaidaLocal = true;
  bool _alertaEntradaLocal = true;
  bool _alertaDesconexao = true;
  bool _alertaBateriaBaixa = true;
  int _limiteBateria = 20;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  bool _asBool(Object? value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }

  Future<void> _loadChildren() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final children = await ApiService.fetchChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        _selectedChildId = children.isEmpty ? null : children.first.id;
      });
      if (_selectedChildId != null) {
        await _loadConfiguration(_selectedChildId!);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadConfiguration(int childId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final config = await ApiService.fetchAlertConfiguration(childId);
      if (!mounted || _selectedChildId != childId) return;
      setState(() {
        _alertaSaidaLocal = _asBool(config?['alerta_saida_local'], true);
        _alertaEntradaLocal = _asBool(config?['alerta_entrada_local'], true);
        _alertaDesconexao = _asBool(config?['alerta_desconexao'], true);
        _alertaBateriaBaixa = _asBool(config?['alerta_bateria_baixa'], true);
        final threshold = config?['limite_bateria_percentual'];
        _limiteBateria = threshold is num
            ? threshold.round().clamp(1, 100).toInt()
            : int.tryParse('$threshold')?.clamp(1, 100).toInt() ?? 20;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final childId = _selectedChildId;
    if (childId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.updateAlertConfiguration(
        childId: childId,
        alertaSaidaLocal: _alertaSaidaLocal,
        alertaEntradaLocal: _alertaEntradaLocal,
        alertaDesconexao: _alertaDesconexao,
        alertaBateriaBaixa: _alertaBateriaBaixa,
        limiteBateriaPercentual: _limiteBateria,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas.')),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadChildren,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _children.isEmpty
          ? _errorView()
          : _children.isEmpty
          ? _emptyView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Alertas de segurança',
                  style: TextStyle(
                    color: AppTheme.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha o perfil e defina quais avisos deseja receber.',
                  style: TextStyle(color: AppTheme.muted),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: _selectedChildId,
                  decoration: const InputDecoration(
                    labelText: 'Perfil infantil',
                    prefixIcon: Icon(Icons.child_care_rounded),
                  ),
                  items: _children
                      .map(
                        (child) => DropdownMenuItem(
                          value: child.id,
                          child: Text(child.nome),
                        ),
                      )
                      .toList(),
                  onChanged: _saving
                      ? null
                      : (childId) {
                          if (childId == null) return;
                          setState(() => _selectedChildId = childId);
                          _loadConfiguration(childId);
                        },
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _alertaSaidaLocal,
                        title: const Text('Saída de local seguro'),
                        subtitle: const Text('Avisar quando sair da área segura'),
                        onChanged: (value) =>
                            setState(() => _alertaSaidaLocal = value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _alertaEntradaLocal,
                        title: const Text('Entrada em local seguro'),
                        subtitle: const Text('Avisar quando chegar à área segura'),
                        onChanged: (value) =>
                            setState(() => _alertaEntradaLocal = value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _alertaDesconexao,
                        title: const Text('Desconexão da pulseira'),
                        subtitle: const Text('Avisar quando a pulseira perder conexão'),
                        onChanged: (value) =>
                            setState(() => _alertaDesconexao = value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _alertaBateriaBaixa,
                        title: const Text('Bateria baixa'),
                        subtitle: const Text('Avisar quando a bateria atingir o limite'),
                        onChanged: (value) =>
                            setState(() => _alertaBateriaBaixa = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Avisar com $_limiteBateria% de bateria',
                  style: const TextStyle(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Slider(
                  value: _limiteBateria.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '$_limiteBateria%',
                  onChanged: (value) =>
                      setState(() => _limiteBateria = value.round()),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _saving || _loading ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Salvando...' : 'Salvar configurações'),
                ),
              ],
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppTheme.muted),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadChildren, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'Cadastre um perfil infantil antes de configurar os alertas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.muted),
        ),
      ),
    );
  }
}
