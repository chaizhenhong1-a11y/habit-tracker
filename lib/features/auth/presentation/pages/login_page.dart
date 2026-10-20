import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_local_store.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authStore = AuthLocalStore();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    final isValid = await _authStore.verifyCredentials(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (isValid) {
      widget.onLoginSuccess();
      return;
    }
    final loc = AppLocalizations.of(context);
    _showSnackBar(loc.translate('loginError') ?? '用户名或密码错误', isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(18),
          backgroundColor: isError ? scheme.error : const Color(0xFF243129),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      );
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      PageRouteBuilder<bool>(
        pageBuilder: (_, animation, secondaryAnimation) => const RegisterPage(),
        transitionsBuilder: (_, animation, secondaryAnimation, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
    if (!mounted || registered != true) return;
    final loc = AppLocalizations.of(context);
    _showSnackBar(loc.translate('registerSuccessHint') ?? '注册成功，请登录');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [Color(0xFF111712), Color(0xFF0E110F)]
                      : const [Color(0xFFF1F4EC), Color(0xFFF8F7F2)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -75,
            child: _AmbientOrb(color: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.12), size: 250),
          ),
          Positioned(
            bottom: 40,
            left: -100,
            child: _AmbientOrb(color: scheme.secondary.withValues(alpha: isDark ? 0.07 : 0.08), size: 230),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              _BrandMark(color: scheme.primary),
                              const SizedBox(height: 34),
                              Text(
                                loc.translate('welcomeBack') ?? '欢迎回来',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.1,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                loc.translate('appSubtitle') ?? '每天进步一点，成为更好的自己',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 34),
                              _AuthSurface(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      loc.translate('login') ?? '登录',
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '继续你的成长旅程',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                                    ),
                                    const SizedBox(height: 24),
                                    _AuthField(
                                      controller: _usernameController,
                                      label: loc.translate('username') ?? '用户名',
                                      hint: loc.translate('usernameHint') ?? '请输入用户名',
                                      icon: Icons.person_outline_rounded,
                                      autofillHints: const [AutofillHints.username],
                                      textInputAction: TextInputAction.next,
                                      validator: (value) => value == null || value.trim().isEmpty
                                          ? (loc.translate('usernameRequired') ?? '请输入用户名')
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _AuthField(
                                      controller: _passwordController,
                                      label: loc.translate('password') ?? '密码',
                                      hint: loc.translate('passwordHint') ?? '请输入密码',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      autofillHints: const [AutofillHints.password],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                                      suffix: IconButton(
                                        tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return loc.translate('passwordRequired') ?? '请输入密码';
                                        }
                                        if (value.length < 3) return loc.translate('passwordTooShort') ?? '密码至少3位';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: _isLoading ? null : _submit,
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 180),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                                )
                                              : Row(
                                                  key: const ValueKey('login'),
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(loc.translate('login') ?? '登录'),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.arrow_forward_rounded, size: 19),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('第一次来到这里？', style: TextStyle(color: scheme.onSurfaceVariant)),
                                  TextButton(
                                    onPressed: _openRegistration,
                                    child: Text(loc.translate('noAccount') ?? '创建账户'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 14, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 6),
                                  Text('你的习惯数据保存在设备中', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                                ],
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
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(23),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          child: Icon(Icons.spa_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 34),
        ),
      );
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

class _AuthSurface extends StatelessWidget {
  const _AuthSurface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.045), blurRadius: 32, offset: const Offset(0, 16))],
      ),
      child: child,
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscureText,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
      );
}
