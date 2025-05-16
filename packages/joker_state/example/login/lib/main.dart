import 'dart:async';

import 'package:flutter/material.dart';
import 'package:joker_state/joker_state.dart';

void main() {
  // Get/Register the Global RingCueMaster
  Circus.ringMaster();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joker State Login Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

const _fakeAccounts = {
  'user@example.com': 'password123',
};

class LoggedInCue {
  final String email;

  const LoggedInCue(this.email);
}

class LoginFailedCue {
  final String reason;

  const LoginFailedCue(this.reason);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final StreamSubscription _successSub;
  late final StreamSubscription _failSub;

  @override
  void initState() {
    super.initState();

    _successSub = Circus.onCue<LoggedInCue>((cue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 ${cue.email} logged in.')),
      );
    });

    _failSub = Circus.onCue<LoginFailedCue>((cue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Login failed: ${cue.reason}')),
      );
    });
  }

  @override
  void dispose() {
    _successSub.cancel();
    _failSub.cancel();
    super.dispose();
  }

  void _login() {
    final email = _emailController.text.trim();
    final pw = _passwordController.text.trim();

    if (_fakeAccounts.containsKey(email)) {
      if (_fakeAccounts[email] == pw) {
        Circus.cue(LoggedInCue(email));
      } else {
        Circus.cue(LoginFailedCue('Password incorrect'));
      }
    } else {
      Circus.cue(LoginFailedCue('Account not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎪 Login with RingCueMaster')),
      // use trapeze to dispose to all controllers without StatefulWidget
      body: [_emailController, _passwordController].trapeze(
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: ValueKey('login-button'),
                icon: const Icon(Icons.login),
                label: const Text('Login'),
                onPressed: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
