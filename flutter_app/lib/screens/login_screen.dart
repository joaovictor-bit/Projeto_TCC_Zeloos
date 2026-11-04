import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'access_screen.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;
  bool _hidePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth({required bool isRegister}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = isRegister
          ? await ApiService.register(
              nome: _nameController.text.trim(),
              email: _emailController.text.trim(),
              senha: _passwordController.text,
            )
          : await ApiService.login(
              email: _emailController.text.trim(),
              senha: _passwordController.text,
            );

      if (result['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AccessScreen(email: _emailController.text.trim()),
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(
        () =>
            _errorMessage = result['message'] ?? 'Não foi possível autenticar.',
      );
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'A API não respondeu em 15 segundos. Confira se o backend e o banco de dados estão ativos.';
      });
    } on SocketException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Não foi possível conectar à API em ${ApiService.baseUrl}: ${error.message}';
      });
    } on http.ClientException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Falha na comunicação com ${ApiService.baseUrl}: ${error.message}';
      });
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'A API respondeu com dados inválidos. Verifique os logs do backend.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Não foi possível concluir a operação: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 42, 28, 36),
                    decoration: const BoxDecoration(
                      color: AppTheme.navy,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ZELOOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mais tranquilidade para acompanhar quem você ama.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .8),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isRegister ? 'Criar conta' : 'Acesse sua conta',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.navy,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isRegister
                                  ? 'Comece a cuidar da segurança da sua família.'
                                  : 'Entre para acompanhar sua família.',
                              style: const TextStyle(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 24),
                            if (_isRegister) ...[
                              TextField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nome completo',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: _hidePassword,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: _hidePassword
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB3261E),
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            FilledButton(
                              onPressed: _loading
                                  ? null
                                  : () => _handleAuth(isRegister: _isRegister),
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isRegister
                                          ? 'Criar minha conta'
                                          : 'Entrar',
                                    ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => setState(() {
                                      _isRegister = !_isRegister;
                                      _errorMessage = null;
                                    }),
                              child: Text(
                                _isRegister
                                    ? 'Já tenho uma conta · Entrar'
                                    : 'Ainda não tem conta? Criar conta',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
