import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_scrap_app/services/account_deletion.dart';

void main() {
  test(
    'identity is preserved when cleanup fails so deletion can be retried',
    () async {
      final steps = <String>[];
      await expectLater(
        runAccountDeletion(
          freezeAccount: () async => steps.add('freeze'),
          deleteData: () async {
            steps.add('data');
            throw StateError('offline');
          },
          deleteIdentity: () async => steps.add('identity'),
        ),
        throwsStateError,
      );
      expect(steps, ['freeze', 'data']);
    },
  );
  test('data cleanup precedes deleting login identity', () async {
    final steps = <String>[];
    await runAccountDeletion(
      freezeAccount: () async => steps.add('freeze'),
      deleteData: () async => steps.add('data'),
      deleteIdentity: () async => steps.add('identity'),
    );
    expect(steps, ['freeze', 'data', 'identity']);
  });
  test('a failed freeze prevents all deletion', () async {
    var dataDeleted = false;
    await expectLater(
      runAccountDeletion(
        freezeAccount: () async => throw StateError('denied'),
        deleteData: () async {
          dataDeleted = true;
        },
        deleteIdentity: () async => fail('identity must remain'),
      ),
      throwsStateError,
    );
    expect(dataDeleted, false);
  });
}
