import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//สีธีม
const Color _rallyOrange = Color(0xFFFF9F4A);
const Color _bg = Color(0xFFF9EFE6);
const Color _textColor = Color(0xFF3A5150);

class LogRegPage extends StatefulWidget {
  const LogRegPage({super.key});

  @override
  State<LogRegPage> createState() => _LogRegPageState();
}

class _LogRegPageState extends State<LogRegPage> {
  bool showLoginPage = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // ตัวแปรควบคุมการแสดงรหัสผ่าน (ดวงตา)
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      // รีเซ็ตสถานะดวงตาเมื่อสลับหน้า
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
    });
  }

  // ฟังก์ชันแปลง Error Message ให้เป็นมิตร
  String _getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'email-already-in-use':
        return "This email is already in use.";
      case 'weak-password':
        return "Password should be at least 8 characters.";
      case 'network-request-failed':
        return "Network error. Please check your connection.";
      default:
        return "An error occurred ($code). Please try again.";
    }
  }

  // 🔥 1. เพิ่มฟังก์ชันตรวจสอบความปลอดภัยรหัสผ่าน
  String? _validatePassword(String password) {
    if (password.length < 8) return "Password must be at least 8 characters.";
    if (!password.contains(RegExp(r'[0-9]')))
      return "Password must contain a number.";
    if (!password.contains(RegExp(r'[A-Z]')))
      return "Password must contain an uppercase letter.";
    return null; // ผ่านทุกกฎ
  }

  Future<void> signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Please enter email and password.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getFriendlyErrorMessage(e.code));
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signUp() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("Please fill in all fields.");
      return;
    }

    // 🔥 2. เรียกใช้ฟังก์ชันตรวจสอบรหัสผ่านตรงนี้
    String? passwordError = _validatePassword(_passwordController.text);
    if (passwordError != null) {
      _showError(passwordError); // แจ้งเตือนถ้าไม่ผ่านกฎ
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        // สร้างข้อมูลเริ่มต้นใน Firestore (รวมถึง avatar_type เริ่มต้น)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'username': _emailController.text.split('@')[0],
          'avatar_type': 'male', // ✅ ค่าเริ่มต้นเป็นผู้ชาย
          'config': {'hold_duration': 1.0, 'sensitivity': 60},
          'stats': {
            'sessions': 0,
            'total_minutes': 0
          } // ✅ แก้ total_hours -> total_minutes
        });

        // Sign out เพื่อให้ผู้ใช้ Login ใหม่
        await FirebaseAuth.instance.signOut();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          showLoginPage = true;
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getFriendlyErrorMessage(e.code));
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 220,
                  child: Image.asset(
                    'assets/rally_logo_square.png', // เช็คชื่อไฟล์ให้ตรง
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 25),

                Text(
                  showLoginPage ? 'Welcome Back!' : 'Create Account',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      color: _textColor),
                ),
                const SizedBox(height: 10),
                Text(
                  showLoginPage
                      ? 'Please sign in to continue'
                      : 'Sign up to start training',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                _buildTextField(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.email_outlined),
                const SizedBox(height: 15),

                // ✅ ช่อง Password พร้อมปุ่มตา
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isVisible: _isPasswordVisible,
                  onToggleVisibility: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),

                if (!showLoginPage) ...[
                  const SizedBox(height: 15),
                  // ✅ ช่อง Confirm Password พร้อมปุ่มตา
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isVisible: _isConfirmPasswordVisible,
                    onToggleVisibility: () => setState(() =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ],

                const SizedBox(height: 30),

                if (_isLoading)
                  const CircularProgressIndicator(color: _rallyOrange)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: showLoginPage ? signIn : signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rallyOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        showLoginPage ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                  ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showLoginPage ? 'Not a member? ' : 'I am a member! ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: toggleScreens,
                      child: Text(
                        showLoginPage ? 'Register now' : 'Login now',
                        style: const TextStyle(
                            color: _rallyOrange, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ปรับปรุง Widget เพื่อรองรับปุ่มตา (Suffix Icon)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText:
            isPassword && !isVisible, // ซ่อนเมื่อเป็นรหัสผ่านและตายังปิดอยู่
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          // เพิ่มปุ่มตา ถ้าเป็นช่องรหัสผ่าน
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey),
                  onPressed: onToggleVisibility,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
