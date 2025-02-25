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

      if (googleUser == null) {
        print("Google Sign-In canceled by user.");
        return null;
      }

      final googleAuth = await googleUser.authentication;

      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(cred);
      final user = userCredential.user;

      if (user != null) {
        final userDoc =
            await _firestore.collection("users").doc(user.uid).get();

        if (!userDoc.exists) {
          await _firestore.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "display_name": user.displayName ?? "Unknown",
            "email": user.email,
            "created_at": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: ${e.toString()}");
      return null;
    }
  }

  Future<AuthResult> createUserWithEmail(
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

      return AuthResult(user: user);
    } on FirebaseAuthException catch (e) {
      if (e.code == "password-does-not-meet-requirements") {
        final RegExp regex = RegExp(r"\[([^\]]+)\]");
        final match = regex.firstMatch(e.message ?? "");
        if (match != null) {
          return AuthResult(
              errors:
                  match.group(1)?.split(", ").map((s) => s.trim()).toList());
        }
      }
      return AuthResult(errors: [e.message ?? "An error occurred"]);
    } catch (e) {
      return AuthResult(
          errors: ["An unexpected error occurred. Please try again."]);
    }
  }

  Future<AuthResult> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return AuthResult(user: cred.user);
    } on FirebaseAuthException catch (e) {
      print("Error Code: ${e.code}");
      print("Error Message: ${e.message}");
      return AuthResult(errors: [_getFirebaseAuthErrorMessage(e.code)]);
    } catch (e) {
      return AuthResult(
          errors: ["An unexpected error occurred. Please try again."]);
    }
  }

  Future<bool> updateUserInfo(String name, String email) async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await user.updateProfile(displayName: name);
        await user.reload();
        user = _auth.currentUser;

        if (user?.email != email) {
          await user?.verifyBeforeUpdateEmail(email);
          print(
              "Verification email sent. User must verify before email updates.");
        }

        await _firestore.collection("users").doc(user?.uid).update({
          "display_name": user?.displayName,
          "email": user?.email,
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

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case "invalid-credential":
        return "Authentication failed. Please check your email and password.";
      case "user-disabled":
        return "This user account has been disabled.";
      case "too-many-requests":
        return "Too many failed login attempts. Please try again later.";
      default:
        return "Authentication failed. An unknown error occured.";
    }
  }
}

class AuthResult {
  final User? user;
  final List<String>? errors;

  AuthResult({this.user, this.errors});
}
