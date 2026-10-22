import 'lang.dart';

/// Lo que se puede comprar con estrellas en la tienda de Owlito: accesorios y colores de plumas.
class ShopItem {
  const ShopItem(this.id, this.nameEs, this.nameEn, this.price, {this.feathers, this.pattern, this.premium = false});
  final String id;
  final String nameEs;
  final String nameEn;

  /// Precio en estrellas (los trajes Premium no se compran: vienen con Premium).
  final int price;

  String get name => tr(nameEs, nameEn);

  /// Colores de un plumaje (orejas, cuerpo, pecho), o null si es un accesorio.
  final (int, int, int)? feathers;

  /// Dibujo especial del plumaje: 'arcoiris' o 'galaxia' (ver [Owl]).
  final String? pattern;

  /// Solo con Premium.
  final bool premium;

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
  // Trajes Premium 👑: vienen con Premium, sin gastar estrellas.
  ShopItem('astronauta', 'Astronauta', 'Astronaut', 0, premium: true),
  ShopItem('pirata', 'Pirata', 'Pirate', 0, premium: true),
  ShopItem('capa', 'Superhéroe', 'Superhero', 0, premium: true),
  ShopItem('mago', 'Mago', 'Wizard', 0, premium: true),
  ShopItem('tiara', 'Tiara de princesa', 'Princess tiara', 0, premium: true),
  ShopItem('dino', 'Disfraz de dinosaurio', 'Dinosaur costume', 0, premium: true),
  ShopItem('arcoiris', 'Plumas arcoíris', 'Rainbow feathers', 0,
      feathers: (0xFF8E44AD, 0xFFE74C3C, 0xFFFFF4FA), pattern: 'arcoiris', premium: true),
  ShopItem('galaxia', 'Plumas galaxia', 'Galaxy feathers', 0,
      feathers: (0xFF3B2F8F, 0xFF1E1B4B, 0xFF4C3FA0), pattern: 'galaxia', premium: true),
];

ShopItem? shopItem(String? id) => shopItems.where((i) => i.id == id).firstOrNull;
