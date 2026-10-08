import '../providers/cart_provider.dart';

String buildOrderMessage(Iterable<CartItem> items) {
  final lines = <String>['مرحباً كبّاس، أود طلب قطع الغيار التالية:'];
  var total = 0.0;
  for (final item in items) {
    final subtotal = item.price * item.quantity;
    total += subtotal;
    lines.add(
      '${item.name} × ${item.quantity}: ${subtotal.toStringAsFixed(2)} ج.م',
    );
  }
  lines.add('الإجمالي المعروض: ${total.toStringAsFixed(2)} ج.م');
  lines.add('يرجى تأكيد التوفر والسعر والتوصيل قبل إتمام الطلب.');
  return lines.join('\n');
}
