import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChildProfilesScreen extends StatefulWidget {
  const ChildProfilesScreen({super.key});

  @override
  State<ChildProfilesScreen> createState() => _ChildProfilesScreenState();
}

class _ChildProfilesScreenState extends State<ChildProfilesScreen> {
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
      final children = await ApiService.fetchChildren();
      if (!mounted) return;
      setState(() => _children = children);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile([ChildProfile? child]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => _ChildProfileFormScreen(child: child)),
    );
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfis da família'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editProfile(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo perfil'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _message(
              icon: Icons.cloud_off_rounded,
              message: 'Não foi possível carregar os perfis.\n$_error',
              action: _load,
            )
          : _children.isEmpty
          ? _message(
              icon: Icons.family_restroom_rounded,
              message: 'Ainda não há perfis cadastrados.',
              action: () => _editProfile(),
              actionLabel: 'Criar primeiro perfil',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  Text(
                    '${_children.length} ${_children.length == 1 ? 'perfil cadastrado' : 'perfis cadastrados'}',
                    style: TextStyle(
                      color: context.palette.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._children.map(
                    (child) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: context.palette.iconBg,
                          child: Icon(
                            Icons.child_care_rounded,
                            color: context.palette.title,
                          ),
                        ),
                        title: Text(
                          child.nome,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          child.dataNascimento == null ||
                                  child.dataNascimento!.isEmpty
                              ? 'Data de nascimento não informada'
                              : 'Nascimento: ${child.dataNascimento!.split('T').first}',
                        ),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _editProfile(child),
                      ),
                    ),
                  ),
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
            Icon(icon, size: 48, color: context.palette.muted),
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

class _ChildProfileFormScreen extends StatefulWidget {
  const _ChildProfileFormScreen({this.child});

  final ChildProfile? child;

  @override
  State<_ChildProfileFormScreen> createState() =>
      _ChildProfileFormScreenState();
}

class _ChildProfileFormScreenState extends State<_ChildProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _birthDateController;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.child != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child?.nome ?? '');
    _birthDateController = TextEditingController(
      text: widget.child?.dataNascimento?.split('T').first ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final parsed = DateTime.tryParse(_birthDateController.text);
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(today.year - 8, today.month, today.day),
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (selected == null) return;
    setState(() {
      _birthDateController.text =
          '${selected.year.toString().padLeft(4, '0')}-'
          '${selected.month.toString().padLeft(2, '0')}-'
          '${selected.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final birthDate = _birthDateController.text.trim();
      if (_editing) {
        await ApiService.updateChild(
          id: widget.child!.id,
          nome: _nameController.text.trim(),
          dataNascimento: birthDate.isEmpty ? null : birthDate,
        );
      } else {
        await ApiService.createChild(
          nome: _nameController.text.trim(),
          dataNascimento: birthDate.isEmpty ? null : birthDate,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editar perfil' : 'Novo perfil'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.child_care_rounded,
                  size: 52,
                  color: context.palette.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  _editing
                      ? 'Atualize os dados do perfil.'
                      : 'Cadastre um perfil para organizar os dispositivos da família.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.palette.muted),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().length < 2
                      ? 'Informe ao menos 2 caracteres.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _birthDateController,
                  readOnly: true,
                  onTap: _saving ? null : _selectBirthDate,
                  decoration: InputDecoration(
                    labelText: 'Data de nascimento (opcional)',
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    suffixIcon: _birthDateController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: _saving
                                ? null
                                : () => setState(
                                    () => _birthDateController.clear(),
                                  ),
                            icon: const Icon(Icons.clear_rounded),
                          ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_editing ? 'Salvar alterações' : 'Criar perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
