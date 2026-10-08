import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Never remove the login identity before its associated data is removed.
Future<void> runAccountDeletion({
  required Future<void> Function() freezeAccount,
  required Future<void> Function() deleteData,
  required Future<void> Function() deleteIdentity,
}) async {
  await freezeAccount();
  await deleteData();
  await deleteIdentity();
}

Future<void> deleteCurrentAccount(User user) async {
  final database = FirebaseFirestore.instance;
  final profile = database.collection('users').doc(user.uid);
  await runAccountDeletion(
    freezeAccount: () => profile.set({
      'deletionRequestedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
    deleteData: () async {
      for (final collection in [
        'maintenance_orders',
        'scrap_orders',
        'pipe_installation_orders',
      ]) {
        while (true) {
          final page = await database
              .collection(collection)
              .where('userId', isEqualTo: user.uid)
              .limit(100)
              .get(const GetOptions(source: Source.server));
          if (page.docs.isEmpty) break;
          final batch = database.batch();
          for (final document in page.docs) {
            batch.delete(document.reference);
          }
          await batch.commit();
        }
      }
      await profile.delete();
    },
    deleteIdentity: user.delete,
  );
}
