import 'package:flutter/material.dart';

// 1. شكل المنتج جوه السلة
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });
}

// 2. الذاكرة اللي بتحفظ السلة وتسمّع في الأبلكيشن كله
class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  // دالة إضافة منتج للسلة
  void addItem(String productId, String name, double price) {
    if (_items.containsKey(productId)) {
      // لو المنتج موجود أصلاً، زود الكمية بس
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          price: existing.price,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      // لو مش موجود، ضيفه لأول مرة
      _items.putIfAbsent(
        productId,
        () => CartItem(id: productId, name: name, price: price, quantity: 1),
      );
    }
    notifyListeners(); // ده السطر السحري اللي بيعمل تحديث للشاشات فوراً
  }

  // دالة حذف منتج
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // دالة تفريغ السلة (بعد الدفع)
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
