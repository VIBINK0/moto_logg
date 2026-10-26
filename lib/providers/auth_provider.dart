import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the instance of [FirebaseAuth].
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Streams the authentication state changes from Firebase Auth.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Exposes the current authenticated [User], or `null` if unauthenticated.
final currentUserProvider = Provider<User?>((ref) {
  final asyncUser = ref.watch(authStateChangesProvider);
  return asyncUser.value ?? FirebaseAuth.instance.currentUser;
});
