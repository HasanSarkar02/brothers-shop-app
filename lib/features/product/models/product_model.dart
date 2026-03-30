class ProductModel {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double? discountPrice;
  final double? flashSalePrice;
  final String? flashSaleEnd;
  final String? image;
  final String? category;
  final String? categorySlug;
  final String? brand;
  final bool inStock;
  final bool hasVariants;
  final bool isNew;
  final double avgRating;
  final int reviewsCount;
  final String? badge;
  final String? description;
  final String? sku;
  final List<String> images;
  final List<VariantModel> variants;

  ProductModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.discountPrice,
    this.flashSalePrice,
    this.flashSaleEnd,
    this.image,
    this.category,
    this.categorySlug,
    this.brand,
    required this.hasVariants,
    required this.inStock,
    required this.isNew,
    required this.avgRating,
    required this.reviewsCount,
    this.badge,
    this.description,
    this.sku,
    this.images = const [],
    this.variants = const [],
  });

  // ── Safe type converters ───────────────────────
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

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is int) return v == 1;
    if (v is String) return v == '1' || v == 'true';
    return false;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: _toDouble(json['price']),
      discountPrice: json['discount_price'] != null
          ? _toDouble(json['discount_price'])
          : null,
      flashSalePrice: json['flash_sale_price'] != null
          ? _toDouble(json['flash_sale_price'])
          : null,
      flashSaleEnd: json['flash_sale_end']?.toString(),
      image: json['image']?.toString(),
      category: json['category']?.toString(),
      categorySlug: json['category_slug']?.toString(),
      brand: json['brand']?.toString(),
      hasVariants: _toBool(json['has_variants']),
      inStock: _toBool(json['in_stock']),
      isNew: _toBool(json['is_new']),
      avgRating: _toDouble(json['avg_rating']),
      reviewsCount: _toInt(json['reviews_count']),
      badge: json['badge']?.toString(),
      description: json['description']?.toString(),
      sku: json['sku']?.toString(),

      // ✅ Safe list parsing
      images: () {
        final raw = json['images'];
        if (raw == null) return <String>[];
        if (raw is List) {
          return raw.map((e) => e?.toString() ?? '').toList();
        }
        return <String>[];
      }(),

      variants: () {
        final raw = json['variants'];
        if (raw == null) return <VariantModel>[];
        if (raw is List) {
          return raw
              .whereType<Map<String, dynamic>>()
              .map((e) => VariantModel.fromJson(e))
              .toList();
        }
        return <VariantModel>[];
      }(),
    );
  }

  double get displayPrice => discountPrice ?? price;

  int? get discountPercent {
    if (discountPrice == null) return null;
    if (price == 0) return null;
    return (((price - discountPrice!) / price) * 100).round();
  }
}

// ── Variant Model ──────────────────────────────────
class VariantModel {
  final int id;
  final String? name;
  final String? value;
  final double? price;
  final int? stock;
  final String? image;
  final Map<String, dynamic> attributes;

  VariantModel({
    required this.id,
    this.name,
    this.value,
    this.price,
    this.stock,
    this.image,
    this.attributes = const {},
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

  factory VariantModel.fromJson(Map<String, dynamic> json) {
    return VariantModel(
      id: _toInt(json['id']),
      name: json['name']?.toString(),
      value: json['value']?.toString(),
      price: json['price'] != null ? _toDouble(json['price']) : null,
      stock: json['stock'] != null ? _toInt(json['stock']) : null,
      image: json['image']?.toString(),
      attributes: json['attributes'] is Map
          ? Map<String, dynamic>.from(json['attributes'])
          : {},
    );
  }
}

// ── Product List Meta ──────────────────────────────
class ProductListMeta {
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  ProductListMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory ProductListMeta.fromJson(Map<String, dynamic> json) {
    return ProductListMeta(
      currentPage: _toInt(json['current_page']),
      lastPage: _toInt(json['last_page']),
      total: _toInt(json['total']),
      perPage: _toInt(json['per_page']),
    );
  }

  bool get hasMore => currentPage < lastPage;
}
