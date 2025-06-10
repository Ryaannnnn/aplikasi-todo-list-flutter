import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // --- FUNGSI LOGIC SIGNUP ---
  Future<void> signUp() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showErrorDialog(
        'Data belum lengkap',
        'Silakan isi semua field yang tersedia.',
      );
      return;
    }

    // Validasi format email
    final email = emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showErrorDialog(
        'Format Email Salah',
        'Masukkan email dengan format yang benar.',
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('todoapp')
          .doc(credential.user!.uid)
          .set({
            'email': credential.user!.email,
            'username': nameController.text.trim(),
            'password': passwordController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Pendaftaran Berhasil'),
                content: const Text(
                  'Akun Anda berhasil dibuat! Silakan login untuk melanjutkan.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan. Coba lagi nanti.';
      if (e.code == 'email-already-in-use') {
        message =
            'Email ini sudah digunakan. Silakan gunakan email lain atau login.';
      } else if (e.code == 'weak-password') {
        message = 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email yang Anda masukkan tidak valid.';
      }
      _showErrorDialog('Pendaftaran Gagal', message);
    } catch (e) {
      _showErrorDialog(
        'Pendaftaran Gagal',
        'Terjadi kesalahan yang tidak diketahui.',
      );
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
          // BAGIAN ATAS (HEADER)
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

          // BAGIAN BAWAH (FORM)
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
                    "Buat Akun Baru",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: nameController,
                    decoration: _buildInputDecoration(
                      label: "Nama Lengkap",
                      primaryColor: primaryColor,
                    ),
                    keyboardType: TextInputType.name,
                  ),
                  const SizedBox(height: 20),
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
                      label: "Password",
                      primaryColor: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSignUpButton(primaryColor),
                  const SizedBox(height: 20),
                  _buildLoginLink(primaryColor),
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

  Widget _buildSignUpButton(Color backgroundColor) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: signUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          "DAFTAR",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink(Color linkColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? "),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text(
            "Login",
            style: TextStyle(fontWeight: FontWeight.bold, color: linkColor),
          ),
        ),
      ],
    );
  }
}
