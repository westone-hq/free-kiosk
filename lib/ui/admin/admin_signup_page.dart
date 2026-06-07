// lib/ui/admin/admin_signup_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kiosk/providers/admin_session_provider.dart';

/// 회원가입 — 이름·주소 입력 시 **승인 없이** 내 매장(storeId)이 바로 생깁니다.
class AdminSignupPage extends ConsumerStatefulWidget {
  const AdminSignupPage({super.key});

  @override
  ConsumerState<AdminSignupPage> createState() => _AdminSignupPageState();
}

class _AdminSignupPageState extends ConsumerState<AdminSignupPage> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignup() async {
    if (_loading) {
      return;
    }
    if (_passCtrl.text != _passConfirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 확인이 일치하지 않습니다.')),
      );
      return;
    }
    setState(() {
      _loading = true;
    });
    final ok = await ref.read(adminSessionProvider.notifier).signup(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          ownerName: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
    });
    if (ok) {
      context.go('/');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '가입할 수 없습니다. 이메일 형식·비밀번호(4자 이상)·이름·주소를 확인하세요.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '가입하면 승인 없이 내 매장 앱이 바로 만들어집니다.\n'
                    '이후 매장 관리 탭에서 테이블·메뉴·QR을 직접 관리하세요.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '이름 (매장명으로도 씁니다)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: '주소',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 (4자 이상)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passConfirmCtrl,
                    obscureText: true,
                    onSubmitted: (_) => _onSignup(),
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _onSignup,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('가입하고 내 매장 시작'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('이미 계정이 있나요? 로그인'),
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
