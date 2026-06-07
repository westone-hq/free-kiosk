// lib/models/store.dart
class Store {
  const Store({
    required this.id,
    required this.name,
    this.address,
    this.logoFile,
  });

  final String id;
  final String name;
  final String? address;
  final String? logoFile;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      logoFile: json['logoFile'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (logoFile != null) 'logoFile': logoFile,
      };
}
