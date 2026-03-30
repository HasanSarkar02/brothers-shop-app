class CartModel {
  final int cartId;
  final int productId;
  final int? variantId;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final double itemTotal;
  final int? stockLimit;
  final bool allowBackorders;
  final bool inStock;

  CartModel({
    required this.cartId,
    required this.productId,
    this.variantId,
    required this.name,
    this.image,
    required this.price,
    required this.quantity,
    required this.itemTotal,
    this.stockLimit,
    this.allowBackorders = false,
    this.inStock = true,
  });

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

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      cartId: _toInt(json['cart_id']),
      productId: _toInt(json['product_id']),
      variantId: json['variant_id'] != null ? _toInt(json['variant_id']) : null,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
      price: _toDouble(json['price']),
      quantity: _toInt(json['quantity']),
      itemTotal: _toDouble(json['item_total']),
      stockLimit: json['stock_limit'] != null
          ? _toInt(json['stock_limit'])
          : null,
      allowBackorders: json['allow_backorders'] == true,
      inStock: json['in_stock'] == true || json['in_stock'] == 1,
    );
  }

  CartModel copyWith({int? quantity, double? itemTotal}) {
    return CartModel(
      cartId: cartId,
      productId: productId,
      variantId: variantId,
      name: name,
      image: image,
      price: price,
      quantity: quantity ?? this.quantity,
      itemTotal: itemTotal ?? this.itemTotal,
      stockLimit: stockLimit,
      allowBackorders: allowBackorders,
      inStock: inStock,
    );
  }
}

class CartSummary {
  final List<CartModel> items;
  final int cartCount;
  final double cartTotal;
  final double savings;
  final bool isEmpty;

  CartSummary({
    required this.items,
    required this.cartCount,
    required this.cartTotal,
    required this.savings,
    required this.isEmpty,
  });

  factory CartSummary.empty() => CartSummary(
    items: [],
    cartCount: 0,
    cartTotal: 0,
    savings: 0,
    isEmpty: true,
  );
}
