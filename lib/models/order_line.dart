class OrderLine {
  const OrderLine({
    required this.menuId,
    required this.nameSnapshot,
    required this.unitPrice,
    required this.quantity,
  });

  final String menuId;
  final String nameSnapshot;
  final int unitPrice;
  final int quantity;

  int get lineTotal => unitPrice * quantity;

  factory OrderLine.fromJson(Map<String, dynamic> json) {
    return OrderLine(
      menuId: json['menuId'] as String,
      nameSnapshot: json['nameSnapshot'] as String,
      unitPrice: (json['unitPrice'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'menuId': menuId,
        'nameSnapshot': nameSnapshot,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };
}
