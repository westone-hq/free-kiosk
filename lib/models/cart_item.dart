/// 손님 화면 장바구니 한 줄 (로컬·메모리용)
class CartItem {
  const CartItem({
    required this.menuId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  final String menuId;
  final String name;
  final int unitPrice;
  final int quantity;

  int get lineTotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      menuId: json['menuId'] as String,
      name: json['name'] as String,
      unitPrice: (json['unitPrice'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'menuId': menuId,
        'name': name,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };
}
