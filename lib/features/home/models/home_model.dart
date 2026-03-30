import '/../features/product/models/product_model.dart';

class SliderModel {
  final int id;
  final String image;
  final String? title;
  final String? subtitle;
  final String? url;

  SliderModel({
    required this.id,
    required this.image,
    this.title,
    this.subtitle,
    this.url,
  });

  factory SliderModel.fromJson(Map<String, dynamic> json) => SliderModel(
    id: json['id'],
    image: json['image'],
    title: json['title'],
    subtitle: json['subtitle'],
    url: json['url'],
  );
}

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? image;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.image,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'],
    name: json['name'],
    slug: json['slug'],
    image: json['image'],
    icon: json['icon'],
  );
}

class HomeData {
  final List<SliderModel> sliders;
  final List<CategoryModel> featuredCategories;
  final List<ProductModel> flashSaleProducts;
  final List<ProductModel> newArrivals;
  final List<ProductModel> trendingProducts;
  final BestSellers bestSellers;
  final List<PromoBanner> promoBanners;

  HomeData({
    required this.sliders,
    required this.featuredCategories,
    required this.flashSaleProducts,
    required this.newArrivals,
    required this.trendingProducts,
    required this.bestSellers,
    required this.promoBanners,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) => HomeData(
    sliders: (json['sliders'] as List)
        .map((e) => SliderModel.fromJson(e))
        .toList(),
    featuredCategories: (json['featured_categories'] as List)
        .map((e) => CategoryModel.fromJson(e))
        .toList(),
    flashSaleProducts: (json['flash_sale_products'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList(),
    newArrivals: (json['new_arrivals'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList(),
    trendingProducts: (json['trending_products'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList(),
    bestSellers: BestSellers.fromJson(json['best_sellers']),
    promoBanners: (json['promo_banners'] as List)
        .map((e) => PromoBanner.fromJson(e))
        .toList(),
  );
}

class BestSellers {
  final List<ProductModel> all;
  final List<ProductModel> furniture;
  final List<ProductModel> electronics;

  BestSellers({
    required this.all,
    required this.furniture,
    required this.electronics,
  });

  factory BestSellers.fromJson(Map<String, dynamic> json) => BestSellers(
    all: (json['all'] as List).map((e) => ProductModel.fromJson(e)).toList(),
    furniture: (json['furniture'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList(),
    electronics: (json['electronics'] as List)
        .map((e) => ProductModel.fromJson(e))
        .toList(),
  );
}

class PromoBanner {
  final int id;
  final String image;
  final String? url;
  final String? title;

  PromoBanner({required this.id, required this.image, this.url, this.title});

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: json['id'],
    image: json['image'],
    url: json['url'],
    title: json['title'],
  );
}
