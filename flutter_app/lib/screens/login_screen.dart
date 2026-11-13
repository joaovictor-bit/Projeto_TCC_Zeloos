import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import 'dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../utils/phone_input_formatter.dart';
import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isRegister = false;
  bool _hidePassword = true;
  bool _loading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth({required bool isRegister}) async {
    final phone = _phoneController.text.trim();
    if (isRegister && !PhoneInputFormatter.isValid(phone)) {
      setState(
        () => _errorMessage = 'Telefone inválido. Informe DDD e número.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = isRegister
          ? await ApiService.register(
              nome: _nameController.text.trim(),
              email: _emailController.text.trim(),
              senha: _passwordController.text,
              telefone: phone.isEmpty ? null : phone,
            )
          : await ApiService.login(
              email: _emailController.text.trim(),
              senha: _passwordController.text,
            );

      if (result['success'] == true) {
        if (!mounted) return;
        if (isRegister) {
          _passwordController.clear();
          setState(() {
            _isRegister = false;
            _successMessage = 'Conta criada com sucesso! Faça login para continuar.';
          });
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              userName: (result['user'] as Map<String, dynamic>?)?['nome']
                  as String?,
            ),
          ),
        );
        return;
      }

      if (!mounted) return;
      final errors = result['errors'];
      setState(
        () => _errorMessage = errors is List && errors.isNotEmpty
            ? (errors.first as Map<String, dynamic>)['message'] as String?
            : result['message'] ?? 'Não foi possível autenticar.',
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

  void _toggleMode() => setState(() {
    _isRegister = !_isRegister;
    _errorMessage = null;
    _successMessage = null;
  });

  ThemeData _screenTheme(bool isDark, _LoginColors colors) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );
    final base = isDark ? AppTheme.dark() : AppTheme.light();
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: colors.fieldFill,
        labelStyle: TextStyle(color: palette.muted),
        floatingLabelStyle: TextStyle(color: palette.accent),
        prefixIconColor: palette.muted,
        suffixIconColor: palette.muted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border(colors.fieldBorder),
        enabledBorder: border(colors.fieldBorder),
        focusedBorder: border(palette.accent, 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark ? _LoginColors.dark : _LoginColors.light;
    return Theme(
      data: _screenTheme(isDark, colors),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: colors.pageBottom,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.pageTop, colors.pageBottom],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 32,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _buildCard(context, colors),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: ThemeToggleButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colors.card,
                        foregroundColor: AppTheme.navy,
                        fixedSize: const Size(48, 48),
                        side: BorderSide(color: colors.cardBorder),
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

  Widget _buildCard(BuildContext context, _LoginColors colors) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 28),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              colors.logo,
              height: 120,
              gaplessPlayback: true,
              semanticLabel: 'ZELOOS',
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _isRegister ? 'Criar conta' : 'Acesse sua conta',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.title,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isRegister
                ? 'Comece a cuidar da segurança da sua família.'
                : 'Entre para acompanhar sua família.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.muted, fontSize: 14),
          ),
          const SizedBox(height: 28),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                if (_isRegister) ...[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Telefone (opcional)',
                      hintText: '(11) 98765-4321',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
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
            onSubmitted: _loading
                ? null
                : (_) => _handleAuth(isRegister: _isRegister),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _hidePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          if (_successMessage != null)
            _message(
              _successMessage!,
              colors.success,
              Icons.check_circle_outline_rounded,
            ),
          if (_errorMessage != null)
            _message(_errorMessage!, colors.error, Icons.error_outline_rounded),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.blue,
              disabledBackgroundColor: AppTheme.blue.withValues(alpha: .5),
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
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
                : Text(_isRegister ? 'Criar minha conta' : 'Entrar'),
          ),
          const SizedBox(height: 28),
          Divider(color: colors.cardBorder, height: 1),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _isRegister ? 'Já tem uma conta?' : 'Ainda não tem uma conta Zeloos?',
                style: TextStyle(color: palette.muted),
              ),
              TextButton(
                onPressed: _loading ? null : _toggleMode,
                child: Text(
                  _isRegister ? 'Entrar' : 'Criar conta',
                  style: TextStyle(
                    color: palette.accent,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: palette.accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _message(String text, Color color, IconData icon) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: color, height: 1.35)),
        ),
      ],
    ),
  );
}

class _LoginColors {
  const _LoginColors({
    required this.pageTop,
    required this.pageBottom,
    required this.card,
    required this.cardBorder,
    required this.shadow,
    required this.fieldFill,
    required this.fieldBorder,
    required this.success,
    required this.error,
    required this.logo,
  });

  final Color pageTop;
  final Color pageBottom;
  final Color card;
  final Color cardBorder;
  final Color shadow;
  final Color fieldFill;
  final Color fieldBorder;
  final Color success;
  final Color error;
  final String logo;

  static const dark = _LoginColors(
    pageTop: AppTheme.navy,
    pageBottom: Color(0xFF0B0F1F),
    card: Color(0xFF161B30),
    cardBorder: Color(0x0FFFFFFF),
    shadow: Color(0x59000000),
    fieldFill: Color(0xFF1E2440),
    fieldBorder: Color(0xFF2C3458),
    success: Color(0xFF4ADE80),
    error: Color(0xFFFF6B6B),
    logo: 'assets/images/zeloos_logo_white.png',
  );

  static const light = _LoginColors(
    pageTop: Color(0xFFE9EDFF),
    pageBottom: AppTheme.background,
    card: Colors.white,
    cardBorder: Color(0x1408104E),
    shadow: Color(0x1A08104E),
    fieldFill: Color(0xFFF7F8FC),
    fieldBorder: Color(0xFFD5DAEA),
    success: Color(0xFF1B7F3B),
    error: Color(0xFFB3261E),
    logo: 'assets/images/zeloos_logo_navy.png',
  );
}
