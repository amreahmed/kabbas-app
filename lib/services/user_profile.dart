import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> ensureUserProfile(User user) async {
  final database = FirebaseFirestore.instance;
  final reference = database.collection('users').doc(user.uid);
  await database.runTransaction((transaction) async {
    final existing = await transaction.get(reference);
    if (!existing.exists) {
      transaction.set(reference, {
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  });
}
