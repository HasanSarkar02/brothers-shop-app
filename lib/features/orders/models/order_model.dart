class OrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final double grandTotal;
  final double shippingCost;
  final String shippingName;
  final String shippingPhone;
  final String shippingAddress;
  final String? notes;
  final String placedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.grandTotal,
    required this.shippingCost,
    required this.shippingName,
    required this.shippingPhone,
    required this.shippingAddress,
    this.notes,
    required this.placedAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: _toInt(json['id']),
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? '',
      grandTotal: _toDouble(json['grand_total']),
      shippingCost: _toDouble(json['shipping_cost']),
      shippingName: json['shipping_name']?.toString() ?? '',
      shippingPhone: json['shipping_phone']?.toString() ?? '',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      notes: json['notes']?.toString(),
      placedAt: json['placed_at']?.toString() ?? '',
      items:
          (json['items'] as List?)
              ?.map((i) => OrderItemModel.fromJson(i))
              .toList() ??
          [],
    );
  }

  // ════════════════════════════════════════
  // Status helpers for UI
  // ════════════════════════════════════════
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

class OrderItemModel {
  final String productName;
  final String? variantInfo;
  final int quantity;
  final double unitAmount;
  final double totalAmount;
  final String? image;

  OrderItemModel({
    required this.productName,
    this.variantInfo,
    required this.quantity,
    required this.unitAmount,
    required this.totalAmount,
    this.image,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productName: json['product_name']?.toString() ?? '',
      variantInfo: json['variant_info']?.toString(),
      quantity: _toInt(json['quantity']),
      unitAmount: _toDouble(json['unit_amount']),
      totalAmount: _toDouble(json['total_amount']),
      image: json['image']?.toString(),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
