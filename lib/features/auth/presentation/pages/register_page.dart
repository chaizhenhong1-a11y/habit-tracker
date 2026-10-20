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
      final scheme = Theme.of(context).colorScheme;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(loc.translate('alreadyRegistered') ?? '该用户名已被注册'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(18),
          backgroundColor: scheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ));
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
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: ColoredBox(color: dark ? const Color(0xFF0B0E0C) : const Color(0xFFF6F5EF))),
        Positioned(
          bottom: -180,
          left: -130,
          child: Container(
            width: 380,
            height: 380,
            decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primary.withValues(alpha: dark ? .07 : .055)),
          ),
        ),
        SafeArea(
          child: LayoutBuilder(builder: (context, viewport) => SingleChildScrollView(
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
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const SizedBox(height: 18),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          IconButton(
                            tooltip: '返回',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                            style: IconButton.styleFrom(
                              side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .65)),
                            ),
                          ),
                          Text('01 / 01', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5, color: scheme.onSurfaceVariant)),
                        ]),
                        SizedBox(height: viewport.maxHeight < 740 ? 34 : 58),
                        Text('BUILD YOUR\nBASELINE.', style: theme.textTheme.displaySmall?.copyWith(fontSize: 39, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                        const SizedBox(height: 14),
                        Text(
                          loc.translate('createAccount') ?? '创建账户，开始记录真正属于你的成长轨迹。',
                          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.55, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 38),
                        _Field(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          label: loc.translate('username') ?? '用户名',
                          hint: loc.translate('usernameHint') ?? '你希望我们怎么称呼你',
                          autofillHints: const [AutofillHints.newUsername],
                          textInputAction: TextInputAction.next,
                          validator: (value) => value == null || value.trim().isEmpty ? (loc.translate('usernameRequired') ?? '请输入用户名') : null,
                        ),
                        const SizedBox(height: 23),
                        _Field(
                          controller: _passwordController,
                          label: loc.translate('password') ?? '密码',
                          hint: '至少 8 位',
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.next,
                          suffix: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return loc.translate('passwordRequired') ?? '请输入密码';
                            if (value.length < 8) return loc.translate('passwordTooShort') ?? '密码至少8位';
                            final upper = value.contains(RegExp(r'[A-Z]'));
                            final lower = value.contains(RegExp(r'[a-z]'));
                            final digit = value.contains(RegExp(r'[0-9]'));
                            if (!upper || !lower || !digit) return loc.translate('passwordTooWeak') ?? '密码需包含大写、小写字母和数字';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Wrap(spacing: 7, runSpacing: 7, children: const [
                          _RuleChip('8+ CHARACTERS'),
                          _RuleChip('A–Z / a–z'),
                          _RuleChip('0–9'),
                        ]),
                        const SizedBox(height: 23),
                        _Field(
                          controller: _confirmController,
                          label: loc.translate('confirmPassword') ?? '确认密码',
                          hint: '再次输入密码',
                          obscureText: _obscureConfirm,
                          autofillHints: const [AutofillHints.newPassword],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _isLoading ? null : _register(),
                          suffix: IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          ),
                          validator: (value) => value != _passwordController.text ? (loc.translate('passwordMismatch') ?? '两次密码输入不一致') : null,
                        ),
                        const SizedBox(height: 34),
                        SizedBox(
                          height: 58,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _register,
                            style: FilledButton.styleFrom(
                              backgroundColor: dark ? const Color(0xFFE6E9E3) : const Color(0xFF18221C),
                              foregroundColor: dark ? const Color(0xFF111512) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _isLoading
                                  ? const SizedBox(key: ValueKey('busy'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                                  : Row(
                                      key: const ValueKey('ready'),
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(loc.translate('register') ?? '创建账户', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const Icon(Icons.arrow_outward_rounded, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(loc.translate('hasAccount') ?? '已有账户？', style: TextStyle(color: scheme.onSurfaceVariant)),
                          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('login') ?? '返回登录')),
                        ]),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          )),
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
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
        focusNode: focusNode,
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

class _RuleChip extends StatelessWidget {
  const _RuleChip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, letterSpacing: .8, color: scheme.onSurfaceVariant)),
    );
  }
}
