/// Lo que se puede comprar con estrellas en la tienda de Owlito: ropa y accesorios para el búho.
class ShopItem {
  const ShopItem(this.id, this.name, this.price);
  final String id;
  final String name;
  final int price;
}

const shopItems = [
  ShopItem('gorro', 'Gorro de fiesta', 15),
  ShopItem('lentes', 'Lentes de sol', 25),
  ShopItem('mono', 'Corbatín', 35),
  ShopItem('bufanda', 'Bufanda', 50),
  ShopItem('corona', 'Corona', 80),
];
