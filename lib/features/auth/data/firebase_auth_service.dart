import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  Future<User> signIn({required String email, required String password}) async {
    final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return result.user!;
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await FirebaseAuth.instance.signOut();
  }
}
