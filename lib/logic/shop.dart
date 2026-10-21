import 'lang.dart';

/// Lo que se puede comprar con estrellas en la tienda de Owlito: accesorios y colores de plumas.
class ShopItem {
  const ShopItem(this.id, this.nameEs, this.nameEn, this.price, {this.feathers});
  final String id;
  final String nameEs;
  final String nameEn;
  final int price;

  String get name => tr(nameEs, nameEn);

  /// Colores de un plumaje (orejas, cuerpo, pecho), o null si es un accesorio.
  final (int, int, int)? feathers;

  bool get isFeathers => feathers != null;
}

const shopItems = [
  ShopItem('gorro', 'Gorro de fiesta', 'Party hat', 15),
  ShopItem('azul', 'Plumas azules', 'Blue feathers', 20, feathers: (0xFF2F6FB5, 0xFF4A90D9, 0xFFCFE4FA)),
  ShopItem('rosa', 'Plumas rosadas', 'Pink feathers', 20, feathers: (0xFFC9558E, 0xFFE77FB0, 0xFFFADCEB)),
  ShopItem('lentes', 'Lentes de sol', 'Sunglasses', 25),
  ShopItem('verde', 'Plumas verdes', 'Green feathers', 30, feathers: (0xFF2F8A5A, 0xFF4CAF7A, 0xFFD4F0DF)),
  ShopItem('mono', 'Corbatín', 'Bow tie', 35),
  ShopItem('bufanda', 'Bufanda', 'Scarf', 50),
  ShopItem('corona', 'Corona', 'Crown', 80),
  ShopItem('dorado', 'Plumas doradas', 'Golden feathers', 100, feathers: (0xFFB8801A, 0xFFE0A526, 0xFFFFF1C2)),
];

ShopItem? shopItem(String? id) => shopItems.where((i) => i.id == id).firstOrNull;
