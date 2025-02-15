import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> sendEmailVerifLink() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> sendPassResetLink(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
    }
  }

  Future<UserCredential?> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();

      final googleAuth = await googleUser?.authentication;

      final cred = GoogleAuthProvider.credential(
          idToken: googleAuth?.idToken, accessToken: googleAuth?.accessToken);

      return await _auth.signInWithCredential(cred);
    } catch (e) {
      print(e.toString());
    }

    return null;
  }

  Future<User?> createUserWithEmail(
      String name, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = cred.user;

      if (user != null) {
        await user.updateProfile(displayName: name);
        await user.reload();
        final updatedUser = _auth.currentUser;

        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "display_name": updatedUser?.displayName,
          "email": user.email,
          "created_at": FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      print('Error code: ${e.code}');
      print('Error message: ${e.message}');
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      print("error");
    }

    return null;
  }

  Future<bool> updateUserInfo(String name, String email) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await user.updateProfile(displayName: name);

        await user.verifyBeforeUpdateEmail(email);

        await user.reload();
        final updatedUser = _auth.currentUser;

        await _firestore.collection("users").doc(user.uid).update({
          "display_name": updatedUser?.displayName,
          "email": updatedUser?.email,
        });

        return true;
      }
    } catch (e) {
      print("Error updating user info: $e");
    }
    return false;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("error");
    }
  }
}
