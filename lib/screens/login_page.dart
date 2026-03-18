import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _bgController;
  final TextEditingController _emailController = TextEditingController();
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      // 登入成功會自動跳轉，無需額外操作
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _emailController.dispose();
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMsg("請輸入 Email", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.soulseal://login-callback',
      );

      if (mounted) {
        _showMsg("✨ 登入信已寄出！請去信箱點擊連結，App 將自動開啟。", isError: false);
      }
    } catch (e) {
      _showMsg('發送失敗: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      const String webClientId =
          '299613415100-o21eiqtpcgog9vdgb6173duic2f00s7p.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw 'Google 認證資訊不完整 (Token is null)';
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    } catch (e) {
      _showMsg('Google 登入失敗: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _anonymousSignIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } catch (e) {
      _showMsg('進入失敗: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFA67C52),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // 1. 動態背景
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(const Color(0xFF1A237E),
                            const Color(0xFF4A148C), _bgController.value)!,
                        Color.lerp(const Color(0xFF006064),
                            const Color(0xFF311B92), _bgController.value)!,
                      ],
                    ),
                  ),
                );
              },
            ),

            Container(color: Colors.black.withOpacity(0.4)),

            // 3. 內容區
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🗑️ 已刪除 Logo Container

                    const SizedBox(height: 40), // 調整頂部間距
                    const Text(
                      "SoulSeal",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48, // 稍微加大標題
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'Serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "封存靈魂的低語",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          letterSpacing: 6),
                    ),
                    const SizedBox(height: 80), // 與輸入框的間距

                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                      // Email 輸入框
                      TextField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: '輸入 Email 接收登入信',
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Colors.white70),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 發送連結按鈕
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signInWithEmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA67C52),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text("發送登入連結",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.white.withOpacity(0.3))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("或",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5))),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.white.withOpacity(0.3))),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Google 登入
                      _buildSocialButton(
                        text: "使用 Google 繼續",
                        icon: Icons.g_mobiledata,
                        color: Colors.white,
                        textColor: Colors.black87,
                        onTap: _googleSignIn,
                      ),

                      const SizedBox(height: 30),

                      // 訪客入口
                      TextButton(
                        onPressed: _anonymousSignIn,
                        child: const Text(
                          "暫不綁定，以訪客身分進入 >",
                          style: TextStyle(
                              color: Colors.white60,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(width: 10),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
