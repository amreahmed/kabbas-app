import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_scrap_app/screens/privacy_screen.dart';
import 'package:hvac_scrap_app/providers/cart_provider.dart';
import 'package:hvac_scrap_app/services/order_message.dart';

void main() {
  testWidgets('privacy and external deletion are readable before sign-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: PrivacyScreen(),
        ),
      ),
    );
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('طلب حذف الحساب خارج التطبيق'),
      400,
    );
    expect(find.text('طلب حذف الحساب خارج التطبيق'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('WhatsApp order has quantities and total without clearing the cart', () {
    final cart = CartProvider();
    cart.addItem('a', 'ضاغط', 125.50);
    cart.addItem('a', 'ضاغط', 125.50);
    cart.addItem('b', 'صمام', 40);
    final message = buildOrderMessage(cart.items.values);
    expect(message, contains('ضاغط × 2: 251.00'));
    expect(message, contains('291.00'));
    expect(cart.itemCount, 2);
    expect(cart.totalAmount, 291);
  });
}
