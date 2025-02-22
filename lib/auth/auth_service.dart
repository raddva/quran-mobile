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
    } on FirebaseAuthException catch (e) {
      print(e.code);
      print(e.message);
      throw _getFirebaseAuthErrorMessage(e.code);
    } catch (e) {
      throw "An unexpected error occurred. Please try again.";
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

  String _getFirebaseAuthErrorMessage(String? errorCode) {
    switch (errorCode) {
      case "invalid-credential":
        return "Invalid Email or Password";
      case "user-disabled":
        return "This account has been disabled. Please contact support.";
      case "too-many-requests":
        return "Too many failed attempts. Try again later.";
      default:
        return "An unknown error occurred. Please try again.";
    }
  }
}
