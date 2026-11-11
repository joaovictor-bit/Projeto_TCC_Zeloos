import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/phone_input_formatter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _email = '';
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final user = await ApiService.fetchMe();
      if (!mounted) return;
      setState(() {
        _nameController.text = user['nome'] as String? ?? '';
        _phoneController.text = PhoneInputFormatter.format(
          user['telefone'] as String? ?? '',
        );
        _email = user['email'] as String? ?? '';
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _loadError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final phone = _phoneController.text.trim();
      await ApiService.updateMe(
        nome: _nameController.text.trim(),
        telefone: phone.isEmpty ? null : phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados da conta atualizados.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _saveError = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _initials {
    final parts = _nameController.text.trim().split(RegExp(r'\s+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _errorView()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: context.palette.iconBg,
                          child: _initials.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 40,
                                  color: context.palette.title,
                                )
                              : Text(
                                  _initials,
                                  style: TextStyle(
                                    color: context.palette.title,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _email,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.palette.muted),
                      ),
                      const SizedBox(height: 28),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Nome completo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 2
                            ? 'Informe ao menos 2 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: _email,
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                          helperText: 'O e-mail é usado para entrar e não pode ser alterado.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [PhoneInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                          hintText: '(11) 98765-4321',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (value) =>
                            PhoneInputFormatter.isValid(value ?? '')
                            ? null
                            : 'Telefone inválido. Informe DDD e número.',
                      ),
                      if (_saveError != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _saveError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
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
                        label: Text(_saving ? 'Salvando...' : 'Salvar alterações'),
                      ),
                    ],
                  ),
                ),
              ),
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
            Icon(Icons.cloud_off_rounded, size: 48, color: context.palette.muted),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar sua conta.\n$_loadError',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
