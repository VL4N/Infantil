import 'lang.dart';

/// Lo que se puede comprar con estrellas en la tienda de Owlito: accesorios y colores de plumas.
class ShopItem {
  const ShopItem(this.id, this.nameEs, this.nameEn, this.price,
      {this.feathers, this.pattern, this.premium = false, this.medals = 0});
  final String id;
  final String nameEs;
  final String nameEn;

  /// Precio en estrellas (los trajes Premium no se compran: vienen con Premium).
  final int price;

  String get name => tr(nameEs, nameEn);

  /// Colores de un plumaje (orejas, cuerpo, pecho), o null si es un accesorio.
  final (int, int, int)? feathers;

  /// Dibujo especial del plumaje: 'arcoiris', 'galaxia', 'lunares', 'fuego' o 'diamante' (ver [Owl]).
  final String? pattern;

  /// Solo con Premium.
  final bool premium;

  /// Premio del camino de medallas: se reclama al juntar estas medallas (no se compra).
  final int medals;

  bool get isFeathers => feathers != null;
}

const shopItems = [
  // Ropa y accesorios.
  ShopItem('gorro', 'Gorro de fiesta', 'Party hat', 15),
  ShopItem('lentes', 'Lentes de sol', 'Sunglasses', 25),
  ShopItem('lazo', 'Lazo', 'Hair bow', 30),
  ShopItem('mono', 'Corbatín', 'Bow tie', 35),
  ShopItem('flor', 'Flor', 'Flower', 40),
  ShopItem('gorra', 'Gorra', 'Cap', 45),
  ShopItem('bufanda', 'Bufanda', 'Scarf', 50),
  ShopItem('collar', 'Collar de perlas', 'Pearl necklace', 60),
  ShopItem('audifonos', 'Audífonos', 'Headphones', 70),
  ShopItem('chef', 'Gorro de chef', 'Chef hat', 80),
  ShopItem('corona', 'Corona', 'Crown', 90),
  ShopItem('vaquero', 'Sombrero de vaquero', 'Cowboy hat', 120),
  // Plumajes.
  ShopItem('azul', 'Plumas azules', 'Blue feathers', 20, feathers: (0xFF2F6FB5, 0xFF4A90D9, 0xFFCFE4FA)),
  ShopItem('rosa', 'Plumas rosadas', 'Pink feathers', 20, feathers: (0xFFC9558E, 0xFFE77FB0, 0xFFFADCEB)),
  ShopItem('verde', 'Plumas verdes', 'Green feathers', 30, feathers: (0xFF2F8A5A, 0xFF4CAF7A, 0xFFD4F0DF)),
  ShopItem('naranja', 'Plumas naranjas', 'Orange feathers', 30, feathers: (0xFFC8661E, 0xFFF08A3C, 0xFFFFE2C8)),
  ShopItem('morado', 'Plumas moradas', 'Purple feathers', 40, feathers: (0xFF5B3A9E, 0xFF8162F0, 0xFFE3DAFF)),
  ShopItem('rojo', 'Plumas rojas', 'Red feathers', 45, feathers: (0xFFA8323A, 0xFFD9484F, 0xFFFFDADC)),
  ShopItem('nieve', 'Plumas de nieve', 'Snowy feathers', 70, feathers: (0xFFB9C0CC, 0xFFDDE2EA, 0xFFFFFFFF)),
  ShopItem('dorado', 'Plumas doradas', 'Golden feathers', 100, feathers: (0xFFB8801A, 0xFFE0A526, 0xFFFFF1C2)),
  ShopItem('plateado', 'Plumas plateadas', 'Silver feathers', 120, feathers: (0xFF7D8799, 0xFFA9B3C4, 0xFFE9EDF3)),
  ShopItem('lunares', 'Plumas con lunares', 'Polka-dot feathers', 150,
      feathers: (0xFF1F8A8A, 0xFF2EB5B5, 0xFFD6F5F5), pattern: 'lunares'),
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
  // Premios del camino de medallas 🏅: no se compran, se ganan jugando todos los días.
  ShopItem('lentes_estrella', 'Lentes de estrella', 'Star glasses', 0, medals: 3),
  ShopItem('fuego', 'Plumas de fuego', 'Fire feathers', 0,
      feathers: (0xFFB03A2E, 0xFFE8572B, 0xFFFFE0B2), pattern: 'fuego', medals: 7),
  ShopItem('caballero', 'Casco de caballero', 'Knight helmet', 0, medals: 12),
  ShopItem('diamante', 'Plumas de diamante', 'Diamond feathers', 0,
      feathers: (0xFF3D8FB8, 0xFF8FD3F0, 0xFFE6F7FF), pattern: 'diamante', medals: 18),
  ShopItem('campeon', 'Traje de campeón', 'Champion outfit', 0, medals: 25),
];

/// Premios del camino de medallas, en orden.
final medalRewards = [for (final i in shopItems) if (i.medals > 0) i]..sort((a, b) => a.medals.compareTo(b.medals));

ShopItem? shopItem(String? id) => shopItems.where((i) => i.id == id).firstOrNull;
