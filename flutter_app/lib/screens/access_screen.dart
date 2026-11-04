import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, required this.email});

  final String email;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _pressed = false;
  bool _hovered = false;
  bool _entering = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    final curved = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = curved;
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, .08),
      end: Offset.zero,
    ).animate(curved);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    if (_entering) return;
    setState(() => _entering = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final transition = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: transition,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(.04, 0),
                end: Offset.zero,
              ).animate(transition),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.navy.withValues(alpha: .08),
                          blurRadius: 32,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9EDFF),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            color: AppTheme.blue,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Acesso confirmado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.navy,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sua conta está conectada. Toque em Entrar para acessar as configurações da sua família.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mail_outline_rounded,
                                color: AppTheme.muted,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.email,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        MouseRegion(
                          onEnter: (_) => setState(() => _hovered = true),
                          onExit: (_) => setState(() => _hovered = false),
                          child: GestureDetector(
                            onTap: _entering ? null : _enter,
                            onTapDown: (_) => setState(() => _pressed = true),
                            onTapUp: (_) => setState(() => _pressed = false),
                            onTapCancel: () => setState(() => _pressed = false),
                            child: AnimatedScale(
                              scale: _pressed
                                  ? .97
                                  : _hovered
                                  ? 1.02
                                  : 1,
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOut,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _hovered
                                      ? const Color(0xFF172575)
                                      : AppTheme.navy,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.navy.withValues(
                                        alpha: _hovered ? .24 : .16,
                                      ),
                                      blurRadius: _hovered ? 18 : 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _entering
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Entrar',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            SizedBox(width: 10),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
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
          ),
        ),
      ),
    );
  }
}
