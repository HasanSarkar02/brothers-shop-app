// lib/features/checkout/models/checkout_model.dart

class CheckoutSummaryModel {
  final List<CheckoutItem> items;
  final double subtotal;
  final double shippingCost;
  final double grandTotal;
  final CheckoutUser? user;
  final List<dynamic> savedAddresses;

  CheckoutSummaryModel({
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.grandTotal,
    this.user,
    this.savedAddresses = const [],
  });

  factory CheckoutSummaryModel.fromJson(Map<String, dynamic> json) {
    return CheckoutSummaryModel(
      items:
          (json['items'] as List?)
              ?.map((item) => CheckoutItem.fromJson(item))
              .toList() ??
          [],
      subtotal: _toDouble(json['subtotal']),
      shippingCost: _toDouble(json['shipping_cost']),
      grandTotal: _toDouble(json['grand_total']),
      user: json['user'] != null ? CheckoutUser.fromJson(json['user']) : null,
      savedAddresses: json['saved_addresses'] ?? [],
    );
  }
}

class CheckoutItem {
  final int cartId;
  final int productId;
  final String name;
  final String? variant;
  final String? image;
  final double unitPrice;
  final int quantity;
  final double itemTotal;

  CheckoutItem({
    required this.cartId,
    required this.productId,
    required this.name,
    this.variant,
    this.image,
    required this.unitPrice,
    required this.quantity,
    required this.itemTotal,
  });

  factory CheckoutItem.fromJson(Map<String, dynamic> json) {
    return CheckoutItem(
      cartId: _toInt(json['cart_id']), // ✅ Safe int parse
      productId: _toInt(json['product_id']), // ✅ Safe int parse
      name: json['name']?.toString() ?? '',
      variant: json['variant']?.toString(),
      image: json['image']?.toString(),
      unitPrice: _toDouble(json['unit_price']), // ✅ Safe double parse
      quantity: _toInt(json['quantity']), // ✅ Safe int parse
      itemTotal: _toDouble(json['item_total']), // ✅ Safe double parse
    );
  }
}

class CheckoutUser {
  final String name;
  final String email;
  final String phone;

  CheckoutUser({required this.name, required this.email, required this.phone});

  factory CheckoutUser.fromJson(Map<String, dynamic> json) {
    return CheckoutUser(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

// ── Order Placement Response Model ──
class OrderResponseModel {
  final int orderId;
  final String orderNumber;
  final double grandTotal;
  final String status;
  final String placedAt;
  final bool newAccount;
  final String? token;

  OrderResponseModel({
    required this.orderId,
    required this.orderNumber,
    required this.grandTotal,
    required this.status,
    required this.placedAt,
    this.newAccount = false,
    this.token,
  });

  factory OrderResponseModel.fromJson(Map<String, dynamic> json) {
    return OrderResponseModel(
      orderId: _toInt(json['order_id']), // ✅ Safe
      orderNumber: json['order_number']?.toString() ?? '',
      grandTotal: _toDouble(json['grand_total']), // ✅ Safe
      status: json['status']?.toString() ?? '',
      placedAt: json['placed_at']?.toString() ?? '',
      newAccount:
          json['new_account'] == true ||
          json['new_account'] == 1 ||
          json['new_account'] == '1', // ✅ Safe bool
      token: json['token']?.toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
