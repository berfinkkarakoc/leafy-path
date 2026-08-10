import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Giriş yap
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // hata yok, başarılı
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    } catch (e) {
      return "Bir hata oluştu, tekrar deneyin.";
    }
  }

  // Kayıt ol
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Kullanıcının adını Firebase profiline kaydet
      await credential.user?.updateDisplayName(name);
      return null; // hata yok, başarılı
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e.code);
    } catch (e) {
      return "Bir hata oluştu, tekrar deneyin.";
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şu an giriş yapmış kullanıcı var mı
  User? get currentUser => _auth.currentUser;

  // Firebase hata kodlarını Türkçe okunur mesaja çevir
  String _mapErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      case 'wrong-password':
        return "Şifre hatalı.";
      case 'invalid-credential':
        return "E-posta veya şifre hatalı.";
      case 'email-already-in-use':
        return "Bu e-posta zaten kullanımda.";
      case 'invalid-email':
        return "Geçersiz e-posta adresi.";
      case 'weak-password':
        return "Şifre çok zayıf.";
      case 'network-request-failed':
        return "İnternet bağlantınızı kontrol edin.";
      default:
        return "Giriş başarısız: $code";
    }
  }
}