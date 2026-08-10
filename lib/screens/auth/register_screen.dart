import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:leafy_path/widgets/app_logo.dart';
import 'package:leafy_path/widgets/custom_text_field.dart';
import 'package:leafy_path/services/auth_service.dart';
import 'package:leafy_path/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final AuthService _authService = AuthService();

  bool _passwordHidden = true;
  bool _confirmPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authService.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Arka plan
          Container(
            color: const Color(0xFFECEFEF),
          ),

          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF52596F).withOpacity(.35),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -100,
            right: -100,
            child: Container(
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF84A98C).withOpacity(.45),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 110,
                sigmaY: 110,
              ),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 35,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    const AppLogo(),

                    const SizedBox(height: 18),

                    const Text(
                      "Yeni Hesap Oluştur",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff4E6E5D),
                      ),
                    ),

                    const SizedBox(height: 30),

                    CustomTextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      labelText: "Ad Soyad",
                      hintText: "Ad Soyad",
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ad soyad boş bırakılamaz";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),

                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      labelText: "E-posta",
                      hintText: "E-posta",
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (!EmailValidator.validate(value ?? "")) {
                          return "Geçerli e-posta giriniz";
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),

                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      labelText: "Şifre",
                      hintText: "Şifre",
                      icon: Icons.lock_outline,
                      obscureText: _passwordHidden,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return "Şifre en az 6 karakter olmalı";
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordHidden
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordHidden = !_passwordHidden;
                          });
                        },
                      ),
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus();
                      },
                    ),

                    const SizedBox(height: 14),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      labelText: "Şifre Tekrar",
                      hintText: "Şifre Tekrar",
                      icon: Icons.lock_outline,
                      obscureText: _confirmPasswordHidden,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return "Şifreler eşleşmiyor";
                        }
                        return null;
                      },
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordHidden
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordHidden =
                                !_confirmPasswordHidden;
                          });
                        },
                      ),
                      onFieldSubmitted: (_) {
                        _confirmPasswordFocus.unfocus();
                      },
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF84A98C),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "KAYIT OL",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: .8,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Zaten hesabın var mı?",
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Giriş Yap",
                            style: TextStyle(
                              color: Color(0xFF4E6E5D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}