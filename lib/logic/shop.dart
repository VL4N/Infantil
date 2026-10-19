/// Lo que se puede comprar con estrellas en la tienda de Owlito: accesorios y colores de plumas.
class ShopItem {
  const ShopItem(this.id, this.name, this.price, {this.feathers});
  final String id;
  final String name;
  final int price;

  /// Colores de un plumaje (orejas, cuerpo, pecho), o null si es un accesorio.
  final (int, int, int)? feathers;

  bool get isFeathers => feathers != null;
}

const shopItems = [
  ShopItem('gorro', 'Gorro de fiesta', 15),
  ShopItem('azul', 'Plumas azules', 20, feathers: (0xFF2F6FB5, 0xFF4A90D9, 0xFFCFE4FA)),
  ShopItem('rosa', 'Plumas rosadas', 20, feathers: (0xFFC9558E, 0xFFE77FB0, 0xFFFADCEB)),
  ShopItem('lentes', 'Lentes de sol', 25),
  ShopItem('verde', 'Plumas verdes', 30, feathers: (0xFF2F8A5A, 0xFF4CAF7A, 0xFFD4F0DF)),
  ShopItem('mono', 'Corbatín', 35),
  ShopItem('bufanda', 'Bufanda', 50),
  ShopItem('corona', 'Corona', 80),
  ShopItem('dorado', 'Plumas doradas', 100, feathers: (0xFFB8801A, 0xFFE0A526, 0xFFFFF1C2)),
];

ShopItem? shopItem(String? id) => shopItems.where((i) => i.id == id).firstOrNull;
