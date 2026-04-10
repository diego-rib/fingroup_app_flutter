// lib/core/providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/repositories/firestore_auth_repository.dart';
import '../data/repositories/firestore_expense_repository.dart';
import '../data/repositories/firestore_category_repository.dart';
import '../data/repositories/firestore_recurring_repository.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/domain_repositories.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final googleSignInProvider = Provider<GoogleSignIn>((_) => GoogleSignIn());

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    googleSignIn: ref.watch(googleSignInProvider),
  ),
);

final firestoreServiceProvider = Provider<FirestoreService>(
  (_) => FirestoreService(FirebaseFirestore.instance),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirestoreAuthRepository(
    authService: ref.watch(authServiceProvider),
    firestore: ref.watch(firestoreServiceProvider),
  ),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => FirestoreExpenseRepository(ref.watch(firestoreServiceProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => FirestoreCategoryRepository(ref.watch(firestoreServiceProvider)),
);

final recurringRepositoryProvider = Provider<RecurringExpenseRepository>(
  (ref) => FirestoreRecurringRepository(ref.watch(firestoreServiceProvider)),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

final currentGroupIdProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);
