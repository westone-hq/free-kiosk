class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageFile,
    required this.categoryId,
    this.enabled = true,
    this.soldOut = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int price;
  final String? description;
  final String? imageFile;
  final String categoryId;
  final bool enabled;
  final bool soldOut;
  final int sortOrder;

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toInt(),
      description: json['description'] as String?,
      imageFile: json['imageFile'] as String?,
      categoryId: json['categoryId'] as String? ?? 'default',
      enabled: json['enabled'] as bool? ?? true,
      soldOut: json['soldOut'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        if (description != null) 'description': description,
        if (imageFile != null) 'imageFile': imageFile,
        'categoryId': categoryId,
        'enabled': enabled,
        'soldOut': soldOut,
        'sortOrder': sortOrder,
      };
}
