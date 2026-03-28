class ProductModel {
  final String id;
  final String barcode;
  final String name;
  final double priceInr;
  final String imageUrl;
  final String category;

  const ProductModel({
    required this.id,
    required this.barcode,
    required this.name,
    required this.priceInr,
    this.imageUrl = '',
    this.category = 'General',
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      priceInr: (json['priceInr'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'name': name,
        'priceInr': priceInr,
        'imageUrl': imageUrl,
        'category': category,
      };
}
