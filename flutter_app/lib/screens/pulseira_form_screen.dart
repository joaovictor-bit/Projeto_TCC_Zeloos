import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/pulseira.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PulseiraFormScreen extends StatefulWidget {
  const PulseiraFormScreen({super.key, this.pulseira});

  final Pulseira? pulseira;

  @override
  State<PulseiraFormScreen> createState() => _PulseiraFormScreenState();
}

class _PulseiraFormScreenState extends State<PulseiraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _modelController = TextEditingController();
  List<ChildProfile> _children = [];
  int? _selectedChildId;
  bool _loadingChildren = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.pulseira != null;

  @override
  void initState() {
    super.initState();
    final pulseira = widget.pulseira;
    if (pulseira != null) {
      _nameController.text = pulseira.nomeDispositivo ?? '';
      _identifierController.text = pulseira.identificador;
      _modelController.text = pulseira.modelo ?? '';
      _selectedChildId = pulseira.criancaId;
    }
    _loadChildren();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    try {
      final children = await ApiService.fetchChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        if (_selectedChildId == null && children.isNotEmpty) {
          _selectedChildId = children.first.id;
        }
        _loadingChildren = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os perfis: $error';
        _loadingChildren = false;
      });
    }
  }

  Future<void> _createChild() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar perfil infantil'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome da criança'),
            validator: (value) => value == null || value.trim().length < 2
                ? 'Informe ao menos 2 caracteres.'
                : null,
            onFieldSubmitted: (_) {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) {
      controller.dispose();
      return;
    }

    try {
      final child = await ApiService.createChild(nome: name);
      if (!mounted) return;
      setState(() {
        _children = [..._children, child];
        _selectedChildId = child.id;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível criar o perfil: $error');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedChildId == null) {
      if (_selectedChildId == null) {
        setState(() => _error = 'Selecione ou cadastre um perfil infantil.');
      }
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final modelo = _modelController.text.trim();
      if (_editing) {
        await ApiService.updatePulseira(
          id: widget.pulseira!.id,
          criancaId: _selectedChildId!,
          identificador: _identifierController.text.trim(),
          nomeDispositivo: _nameController.text.trim(),
          modelo: modelo.isEmpty ? null : modelo,
        );
      } else {
        await ApiService.createPulseira(
          criancaId: _selectedChildId!,
          identificador: _identifierController.text.trim(),
          nomeDispositivo: _nameController.text.trim(),
          modelo: modelo.isEmpty ? null : modelo,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar pulseira' : 'Nova pulseira'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(Icons.watch_rounded, size: 52, color: context.palette.accent),
                const SizedBox(height: 12),
                Text(
                  _editing
                      ? 'Atualize os dados do dispositivo.'
                      : 'Vincule uma pulseira à sua família.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.muted),
                ),
                const SizedBox(height: 26),
                if (_loadingChildren)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  DropdownButtonFormField<int>(
                    initialValue:
                        _children.any((child) => child.id == _selectedChildId)
                        ? _selectedChildId
                        : null,
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
                    onChanged: (value) => setState(() {
                      _selectedChildId = value;
                      _error = null;
                    }),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _createChild,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Adicionar perfil infantil'),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome da pulseira',
                    hintText: 'Ex.: Pulseira da Ana',
                    prefixIcon: Icon(Icons.watch_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe um nome para a pulseira.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _identifierController,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Identificador do dispositivo',
                    hintText: 'Ex.: BRACELET-001',
                    prefixIcon: Icon(Icons.tag_rounded),
                    helperText: 'Use o código único impresso na pulseira.',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Informe o identificador da pulseira.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Modelo (opcional)',
                    prefixIcon: Icon(Icons.devices_other_rounded),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFB3261E)),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving || _loadingChildren ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _editing ? 'Salvar alterações' : 'Cadastrar pulseira',
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
