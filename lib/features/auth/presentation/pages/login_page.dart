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
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final valid = await _authStore.verifyCredentials(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (valid) {
      widget.onLoginSuccess();
      return;
    }
    final loc = AppLocalizations.of(context);
    _notice(loc.translate('loginError') ?? '用户名或密码错误', error: true);
  }

  void _notice(String message, {bool error = false}) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(18),
        backgroundColor: error ? scheme.error : const Color(0xFF1E2822),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
  }

  Future<void> _openRegistration() async {
    final registered = await Navigator.push<bool>(
      context,
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, __) => const RegisterPage(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: SlideTransition(
            position: Tween(begin: const Offset(.025, .025), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
      ),
    );
    if (!mounted || registered != true) return;
    _notice(AppLocalizations.of(context).translate('registerSuccessHint') ?? '注册成功，请登录');
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
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: ColoredBox(color: dark ? const Color(0xFF0B0E0C) : const Color(0xFFF6F5EF))),
        Positioned(
          top: -150,
          right: -120,
          child: _Glow(size: 330, color: scheme.primary.withValues(alpha: dark ? .09 : .07)),
        ),
        SafeArea(
          child: LayoutBuilder(builder: (context, viewport) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 32),
                            const _Wordmark(),
                            SizedBox(height: viewport.maxHeight < 700 ? 58 : 92),
                            Text(
                              loc.translate('welcomeBack') ?? '欢迎回来',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 42,
                                height: 1.03,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '继续今天的节奏。\n小步前进，也算前进。',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                height: 1.55,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 44),
                            _LineField(
                              controller: _usernameController,
                              label: loc.translate('username') ?? '用户名',
                              hint: loc.translate('usernameHint') ?? '输入你的用户名',
                              autofillHints: const [AutofillHints.username],
                              textInputAction: TextInputAction.next,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? (loc.translate('usernameRequired') ?? '请输入用户名')
                                  : null,
                            ),
                            const SizedBox(height: 26),
                            _LineField(
                              controller: _passwordController,
                              label: loc.translate('password') ?? '密码',
                              hint: loc.translate('passwordHint') ?? '输入你的密码',
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _isLoading ? null : _submit(),
                              suffix: IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) return loc.translate('passwordRequired') ?? '请输入密码';
                                if (value.length < 3) return loc.translate('passwordTooShort') ?? '密码至少3位';
                                return null;
                              },
                            ),
                            const SizedBox(height: 38),
                            SizedBox(
                              height: 58,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: dark ? const Color(0xFFE6E9E3) : const Color(0xFF18221C),
                                  foregroundColor: dark ? const Color(0xFF111512) : Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _isLoading
                                      ? const SizedBox(
                                          key: ValueKey('busy'),
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2.2),
                                        )
                                      : Row(
                                          key: const ValueKey('ready'),
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(loc.translate('login') ?? '登录', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                            const Icon(Icons.arrow_outward_rounded, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Row(children: [
                              Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: .55))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text('NEW HERE', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.6, color: scheme.onSurfaceVariant)),
                              ),
                              Expanded(child: Divider(color: scheme.outlineVariant.withValues(alpha: .55))),
                            ]),
                            const SizedBox(height: 18),
                            OutlinedButton(
                              onPressed: _openRegistration,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .75)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              ),
                              child: Text(loc.translate('noAccount') ?? '创建新账户'),
                            ),
                            const SizedBox(height: 28),
                            Row(children: [
                              Icon(Icons.shield_outlined, size: 15, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 7),
                              Expanded(child: Text('Private by design · 数据保存在你的设备中', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
                            ]),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(11)),
        child: Icon(Icons.north_east_rounded, size: 18, color: scheme.surface),
      ),
      const SizedBox(width: 11),
      Text('HABIT', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 2.2)),
    ]);
  }
}

class _LineField extends StatelessWidget {
  const _LineField({
    required this.controller,
    required this.label,
    required this.hint,
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
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.2, color: scheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        validator: validator,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: suffix,
          filled: false,
          contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 13),
          border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant)),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: .8))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: scheme.onSurface, width: 1.4)),
        ),
      ),
    ]);
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
