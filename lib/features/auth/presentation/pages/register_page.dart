import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_local_store.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _authStore = AuthLocalStore();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final exists = await _authStore.usernameExists(username);
    if (!mounted) return;

    if (exists) {
      setState(() => _isLoading = false);
      final loc = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.translate('alreadyRegistered') ?? '该用户名已被注册')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(18),
            backgroundColor: scheme.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        );
      _usernameController.clear();
      _usernameFocusNode.requestFocus();
      return;
    }

    await _authStore.register(username: username, password: password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameFocusNode.dispose();
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
            top: -100,
            left: -80,
            child: _AmbientOrb(color: scheme.primary.withValues(alpha: isDark ? 0.09 : 0.11), size: 250),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton.filledTonal(
                                  tooltip: '返回',
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: 0.20), blurRadius: 24, offset: const Offset(0, 10))],
                                ),
                                child: Icon(Icons.auto_awesome_rounded, color: scheme.onPrimary, size: 27),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                loc.translate('createAccount') ?? '创建你的账户',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '从今天开始，把目标变成每天看得见的进步。',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),
                              _RegisterSurface(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _RegisterField(
                                      controller: _usernameController,
                                      focusNode: _usernameFocusNode,
                                      label: loc.translate('username') ?? '用户名',
                                      hint: loc.translate('usernameHint') ?? '为自己取一个名字',
                                      icon: Icons.person_outline_rounded,
                                      autofillHints: const [AutofillHints.newUsername],
                                      textInputAction: TextInputAction.next,
                                      validator: (value) => value == null || value.trim().isEmpty
                                          ? (loc.translate('usernameRequired') ?? '请输入用户名')
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    _RegisterField(
                                      controller: _passwordController,
                                      label: loc.translate('password') ?? '密码',
                                      hint: loc.translate('passwordHint') ?? '至少 8 位，包含大小写和数字',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      autofillHints: const [AutofillHints.newPassword],
                                      textInputAction: TextInputAction.next,
                                      suffix: IconButton(
                                        tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return loc.translate('passwordRequired') ?? '请输入密码';
                                        if (value.length < 8) return loc.translate('passwordTooShort') ?? '密码至少8位';
                                        final hasUpper = value.contains(RegExp(r'[A-Z]'));
                                        final hasLower = value.contains(RegExp(r'[a-z]'));
                                        final hasDigit = value.contains(RegExp(r'[0-9]'));
                                        if (!hasUpper || !hasLower || !hasDigit) {
                                          return loc.translate('passwordTooWeak') ?? '密码需包含大写、小写字母和数字';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    _PasswordHint(color: scheme.onSurfaceVariant),
                                    const SizedBox(height: 14),
                                    _RegisterField(
                                      controller: _confirmController,
                                      label: loc.translate('confirmPassword') ?? '确认密码',
                                      hint: '再次输入密码',
                                      icon: Icons.verified_user_outlined,
                                      obscureText: _obscureConfirm,
                                      autofillHints: const [AutofillHints.newPassword],
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _isLoading ? null : _register(),
                                      suffix: IconButton(
                                        tooltip: _obscureConfirm ? '显示密码' : '隐藏密码',
                                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                      ),
                                      validator: (value) => value != _passwordController.text
                                          ? (loc.translate('passwordMismatch') ?? '两次密码输入不一致')
                                          : null,
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: _isLoading ? null : _register,
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
                                                  key: const ValueKey('register'),
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(loc.translate('register') ?? '创建账户'),
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
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(loc.translate('hasAccount') ?? '已经有账户？', style: TextStyle(color: scheme.onSurfaceVariant)),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(loc.translate('login') ?? '登录'),
                                  ),
                                ],
                              ),
                              Text(
                                '创建账户即代表你开始为自己的成长留下记录',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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

class _PasswordHint extends StatelessWidget {
  const _PasswordHint({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '使用 8 位以上密码，并包含大写字母、小写字母和数字',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, height: 1.4),
            ),
          ),
        ],
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

class _RegisterSurface extends StatelessWidget {
  const _RegisterSurface({required this.child});
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

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.obscureText = false,
    this.suffix,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
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
        focusNode: focusNode,
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
