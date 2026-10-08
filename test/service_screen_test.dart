import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hvac_scrap_app/screens/home_screen.dart';
import 'package:hvac_scrap_app/screens/maintenance_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  GoogleFonts.config.allowRuntimeFetching = false;
  setUpAll(() async => Firebase.initializeApp());

  Widget app(Widget screen) => MaterialApp(
    home: Directionality(textDirection: TextDirection.rtl, child: screen),
  );

  testWidgets('home opens the pipe installation form on a narrow phone', (
    tester,
  ) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const HomeScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('تأسيس مواسير التكييفات'), 300);
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأسيس مواسير التكييفات'));
    await tester.pumpAndSettle();
    expect(find.text('عنوان المعاينة بالتفصيل *'), findsOneWidget);
    expect(find.text('عدد التكييفات المطلوب تأسيسها *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pipe installation requires address and valid unit count', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const MaintenanceScreen(isPipeInstallation: true)),
    );
    await tester.enterText(find.byType(TextField).at(0), 'عميل اختبار');
    await tester.enterText(find.byType(TextField).at(1), '01012345678');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('إرسال طلب التأسيس'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال طلب التأسيس'));
    await tester.pump();
    expect(
      find.text('اكتب عنوان المعاينة وعدد التكييفات من 1 إلى 100'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'maintenance retains the original form and description validation',
    (tester) async {
      await tester.pumpWidget(app(const MaintenanceScreen()));
      expect(find.text('عنوان المعاينة بالتفصيل *'), findsNothing);
      await tester.enterText(find.byType(TextField).at(0), 'عميل اختبار');
      await tester.enterText(find.byType(TextField).at(1), '01012345678');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('إرسال طلب الصيانة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إرسال طلب الصيانة'));
      await tester.pump();
      expect(find.text('من فضلك اكتب وصف للعطل أو ارفع صورة!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
