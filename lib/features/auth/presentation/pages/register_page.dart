import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/auth_local_store.dart';
import '../widgets/auth_brand.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.translate('alreadyRegistered') ?? '该用户名已被注册'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
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
      body: AuthBackdrop(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, viewport) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight - 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                tooltip: '返回',
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ),
                            const HabitBrand(compact: true),
                            const SizedBox(height: 30),
                            Text(
                              loc.translate('createAccount') ?? 'Create your\naccount',
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: dark ? const Color(0xFFEDEADF) : const Color(0xFF173B2C),
                                fontSize: 40,
                                height: 1.04,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Start your journey to a calmer, healthier and more intentional life.',
                              style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
                            ),
                            const SizedBox(height: 26),
                            PremiumAuthField(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              hint: loc.translate('usernameHint') ?? 'Your name',
                              icon: Icons.person_outline_rounded,
                              autofillHints: const [AutofillHints.newUsername],
                              textInputAction: TextInputAction.next,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? (loc.translate('usernameRequired') ?? '请输入用户名')
                                  : null,
                            ),
                            const SizedBox(height: 11),
                            PremiumAuthField(
                              controller: _passwordController,
                              hint: loc.translate('passwordHint') ?? 'Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.next,
                              suffix: IconButton(
                                tooltip: _obscurePassword ? '显示密码' : '隐藏密码',
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
                            const SizedBox(height: 11),
                            PremiumAuthField(
                              controller: _confirmController,
                              hint: loc.translate('confirmPassword') ?? 'Confirm password',
                              icon: Icons.verified_user_outlined,
                              obscureText: _obscureConfirm,
                              autofillHints: const [AutofillHints.newPassword],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _isLoading ? null : _register(),
                              suffix: IconButton(
                                tooltip: _obscureConfirm ? '显示密码' : '隐藏密码',
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              ),
                              validator: (value) => value != _passwordController.text
                                  ? (loc.translate('passwordMismatch') ?? '两次密码输入不一致')
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                              decoration: BoxDecoration(
                                color: dark ? Colors.white.withValues(alpha: .035) : Colors.white.withValues(alpha: .42),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: scheme.outlineVariant.withValues(alpha: .35)),
                              ),
                              child: const Column(children: [
                                _Requirement(text: 'At least 8 characters'),
                                SizedBox(height: 7),
                                _Requirement(text: 'Include upper & lower case letters'),
                                SizedBox(height: 7),
                                _Requirement(text: 'Include a number'),
                              ]),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 58,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _register,
                                style: premiumAuthButtonStyle(context),
                                child: _isLoading
                                    ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        Text(loc.translate('register') ?? 'Create account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                        const SizedBox(width: 10),
                                        const Icon(Icons.arrow_forward_rounded, size: 20),
                                      ]),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(loc.translate('hasAccount') ?? 'Already have an account?', style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                              TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('login') ?? 'Sign in')),
                            ]),
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
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      const Icon(Icons.check_rounded, size: 17, color: Color(0xFF456A55)),
      const SizedBox(width: 9),
      Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
    ]);
  }
}
