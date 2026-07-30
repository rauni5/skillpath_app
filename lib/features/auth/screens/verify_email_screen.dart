import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _pollTimer;
  bool _checking = false;
  bool _justResent = false;

  @override
  void initState() {
    super.initState();
    // Poll quietly every few seconds so the app unlocks on its own the
    // moment the user taps the link in their email, without them needing
    // to come back and tap a button.
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      context.read<AuthProvider>().checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final verified = await context.read<AuthProvider>().checkEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still not verified — check your inbox and spam folder.'),
        ),
      );
    }
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.resendVerificationEmail();
    if (!mounted) return;
    if (ok) {
      setState(() => _justResent = true);
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final auth = context.watch<AuthProvider>();
    final email = auth.currentUser?.email ?? 'your email';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 44, color: p.indigo),
                const SizedBox(height: 20),
                Text(
                  'We sent a verification link to',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: p.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Open it and tap the link to continue. This page will '
                  'update automatically once you\'re verified.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: p.textMuted, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _checking ? null : _checkNow,
                  child: _checking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("I've verified — continue"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: auth.isLoading ? null : _resend,
                  child: Text(_justResent ? 'Email sent again' : 'Resend email'),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
