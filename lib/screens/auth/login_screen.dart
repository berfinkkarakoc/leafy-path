import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:leafy_path/widgets/app_logo.dart';
import 'package:leafy_path/widgets/custom_text_field.dart';
import 'package:leafy_path/widgets/social_login_button.dart';
import 'package:leafy_path/screens/auth/register_screen.dart';
import 'package:leafy_path/services/auth_service.dart';
import 'package:leafy_path/screens/home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();

  bool _sifreGizliMi = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final error = await _authService.signIn(
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
          // 1. Temel Arka Plan (En arka katman - Home Background rengi soft hali)
          Container(color: const Color(0xFFECEFEF)),

          // 2. Figma'daki İlk Renk Topu (#52596F - Üst taraftaki dairesel renk)
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF52596F).withOpacity(0.35),
              ),
            ),
          ),

          // 3. Figma'daki İkinci Renk Topu (#84A98C - Alt taraftaki dairesel renk)
          Positioned(
            bottom: -150,
            left: -100,
            right: -100,
            child: Container(
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF84A98C).withOpacity(0.45),
              ),
            ),
          ),

          // 4. KESKİN ÇİZGİYİ YOK EDEN BLUR (Figma'daki Layer Blur 100+ efekti)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 110.0, sigmaY: 110.0),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 5. Ön Plandaki İçerik Katmanı
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      const AppLogo(),

                      const SizedBox(height: 35),

                      CustomTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        labelText: "E-posta adresiniz",
                        hintText: "E-posta adresiniz",
                        icon: Icons.email_outlined,
                        validator: (value) {
                          if (!EmailValidator.validate(value!)) {
                            return "Geçerli mail giriniz";
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
                        labelText: "Şifreniz",
                        hintText: "Şifreniz",
                        icon: Icons.lock_outline,
                        obscureText: _sifreGizliMi,
                        validator: (value) {
                          if (value!.length < 6) {
                            return "Şifre en az 6 karakter olmalı";
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                          _passwordFocus.unfocus();
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _sifreGizliMi
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _sifreGizliMi = !_sifreGizliMi;
                            });
                          },
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Şifremi unuttum",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF84A98C),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: const Color(
                              0xFF84A98C,
                            ).withOpacity(0.35),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
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
                                  "GİRİŞ YAP",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.black12)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "VEYA",
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.black12)),
                        ],
                      ),

                      const SizedBox(height: 22),

                      SocialLoginButton(
                        text: 'Google ile devam et',
                        iconPath:
                            'https://www.vectorlogo.zone/logos/google/google-icon.svg',
                        onPressed: () {},
                      ),

                      const SizedBox(height: 12),

                      SocialLoginButton(
                        text: 'Facebook ile devam et',
                        iconPath:
                            'https://www.vectorlogo.zone/logos/facebook/facebook-official.svg',
                        onPressed: () {},
                      ),

                      const SizedBox(height: 12),

                      SocialLoginButton(
                        text: 'Apple ile devam et',
                        iconPath:
                            'https://www.vectorlogo.zone/logos/apple/apple-icon.svg',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Hesabın yok mu?",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Kayıt Ol",
                              style: TextStyle(
                                color: Color(0xFF84A98C),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}