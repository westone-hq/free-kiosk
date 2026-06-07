class Category {
  const Category({
    required this.id,
    required this.name,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final bool enabled;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      enabled: json['enabled'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'enabled': enabled,
        'sortOrder': sortOrder,
      };
}
