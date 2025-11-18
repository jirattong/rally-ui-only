import 'package:flutter/material.dart';

class LogRegPage extends StatefulWidget {
  const LogRegPage({super.key});
  @override
  State<LogRegPage> createState() => _LogRegPageState();
}

class _LogRegPageState extends State<LogRegPage> {
  bool isRegister = false;
  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();
  final _regUser = TextEditingController();
  final _regPass = TextEditingController();
  final _regPass2 = TextEditingController();

  @override
  void dispose() {
    _loginUser.dispose();
    _loginPass.dispose();
    _regUser.dispose();
    _regPass.dispose();
    _regPass2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF9EFE6);
    const orange = Color(0xFFFF7E2F);
    return Scaffold(
      backgroundColor: bg,
      appBar: isRegister
          ? AppBar(
              backgroundColor: bg,
              elevation: 0,
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: orange),
                  onPressed: () => setState(() => isRegister = false)),
            )
          : null,
      body: SafeArea(child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final side = w * 0.08;
        final double logoW = ((w * 0.55).clamp(220.0, 340.0)) as double;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, w * 0.10, side, w * 0.06),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Column(children: [
              Image.asset('assets/rally_logo.png',
                  width: logoW, fit: BoxFit.contain),
              SizedBox(height: w * 0.04),
            ]),
            const SizedBox(height: 20),
            if (!isRegister)
              _LoginForm(
                user: _loginUser,
                pass: _loginPass,
                onLogin: () => Navigator.pushNamed(context, '/home'),
                onForgot: () {},
                onSignUp: () => setState(() => isRegister = true),
              )
            else
              _RegisterForm(
                user: _regUser,
                pass: _regPass,
                pass2: _regPass2,
                onRegister: () {},
              ),
          ]),
        );
      })),
    );
  }
}

InputDecoration _decor([String? hint]) {
  const borderColor = Color(0xFFC9CED4);
  final radius = BorderRadius.circular(10);
  return InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
        borderRadius: radius, borderSide: const BorderSide(color: borderColor)),
    focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: borderColor, width: 1.5)),
    hintStyle: const TextStyle(color: Colors.black54),
    filled: true,
    fillColor: Colors.white,
  );
}

class _LoginForm extends StatelessWidget {
  const _LoginForm(
      {required this.user,
      required this.pass,
      required this.onLogin,
      required this.onForgot,
      required this.onSignUp});
  final TextEditingController user;
  final TextEditingController pass;
  final VoidCallback onLogin;
  final VoidCallback onForgot;
  final VoidCallback onSignUp;
  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7E2F);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: user, decoration: _decor('Username')),
      const SizedBox(height: 16),
      TextField(
          controller: pass, decoration: _decor('Password'), obscureText: true),
      const SizedBox(height: 22),
      SizedBox(
        height: 54,
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: onLogin,
          child: const Text('Log In',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 16),
      Center(
          child: TextButton(
              onPressed: onForgot,
              child: const Text('Forgot password?',
                  style: TextStyle(color: Colors.black87)))),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text("Don't have an account?  ",
            style: TextStyle(color: Colors.black87)),
        GestureDetector(
            onTap: onSignUp,
            child: const Text('Sign Up',
                style: TextStyle(
                    color: Colors.deepOrange, fontWeight: FontWeight.w700))),
      ]),
    ]);
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm(
      {required this.user,
      required this.pass,
      required this.pass2,
      required this.onRegister});
  final TextEditingController user;
  final TextEditingController pass;
  final TextEditingController pass2;
  final VoidCallback onRegister;
  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF7E2F);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(controller: user, decoration: _decor('Username')),
      const SizedBox(height: 16),
      TextField(
          controller: pass, decoration: _decor('Password'), obscureText: true),
      const SizedBox(height: 16),
      TextField(
          controller: pass2,
          decoration: _decor('Re-Password'),
          obscureText: true),
      const SizedBox(height: 22),
      SizedBox(
        height: 54,
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: onRegister,
          child: const Text('Register',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }
}
