import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:to_do/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showErrorDialog(
        'Data belum lengkap',
        'Silakan masukkan email dan kata sandi terlebih dahulu.',
      );
      return;
    }
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan. Silakan coba lagi.';
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'wrong-password') {
        message = 'Email atau kata sandi yang Anda masukkan salah.';
      }
      _showErrorDialog('Gagal Masuk', message);
    } catch (e) {
      _showErrorDialog(
        'Gagal Masuk',
        'Terjadi kesalahan yang tidak diketahui.',
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authService = AuthService();
      final user = await authService.signInWithGoogle();
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Masuk dengan Google dibatalkan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal Masuk dengan Google', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF86B6F6);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/reading_illustration.png',
                height: 150,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Masuk ke Akun Anda",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: emailController,
                    decoration: _buildInputDecoration(
                      label: "Email",
                      primaryColor: primaryColor,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _buildInputDecoration(
                      label: "Kata Sandi",
                      primaryColor: primaryColor,
                    ), // DIUBAH
                  ),
                  const SizedBox(height: 20),
                  _buildRememberAndForgot(primaryColor),
                  const SizedBox(height: 30),
                  _buildLoginButton(primaryColor),
                  const SizedBox(height: 20),
                  _buildRegisterLink(primaryColor),
                  const SizedBox(height: 30),
                  const Text(
                    "atau masuk dengan",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialIconsRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET PEMBANTU ---

  InputDecoration _buildInputDecoration({
    required String label,
    required Color primaryColor,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      floatingLabelStyle: TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.bold,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2.0),
      ),
    );
  }

  Widget _buildRememberAndForgot(Color activeColor) {
    return Row(
      children: [
        Switch(
          value: rememberMe,
          onChanged: (value) => setState(() => rememberMe = value),
          activeColor: activeColor,
        ),
        const Text("Ingat saya"),
        const Spacer(),
        TextButton(
          onPressed: () {},
          child: Text("Lupa Kata Sandi?", style: TextStyle(color: activeColor)),
        ),
      ],
    );
  }

  Widget _buildSocialIconsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          Icon(
            FontAwesomeIcons.facebookF,
            color: Colors.grey.shade700,
            size: 20,
          ),
          () {},
        ),
        const SizedBox(width: 25),
        _buildSocialButton(
          Icon(FontAwesomeIcons.twitter, color: Colors.grey.shade700, size: 20),
          () {},
        ),
        const SizedBox(width: 25),
        _buildSocialButton(
          Image.asset(
            'assets/google_logo.png',
            height: 20,
            width: 20,
            errorBuilder:
                (context, error, stackTrace) => Icon(
                  FontAwesomeIcons.google,
                  color: Colors.grey.shade700,
                  size: 20,
                ),
          ),
          _signInWithGoogle,
        ),
      ],
    );
  }

  Widget _buildSocialButton(Widget iconWidget, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: iconWidget,
      ),
    );
  }

  Widget _buildLoginButton(Color backgroundColor) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: login,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "MASUK",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(Color linkColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Belum punya akun? "),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/signup'),
          child: Text(
            "Daftar di sini",
            style: TextStyle(fontWeight: FontWeight.bold, color: linkColor),
          ),
        ),
      ],
    );
  }
}
