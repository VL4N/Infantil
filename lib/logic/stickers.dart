import 'lang.dart';

/// Una página del álbum de stickers. Las páginas Premium solo se llenan con Premium.
class StickerPage {
  const StickerPage(this.key, this.nameEs, this.nameEn, this.stickers, {this.premium = false});
  final String key;
  final String nameEs;
  final String nameEn;
  final List<String> stickers;
  final bool premium;

  String get name => tr(nameEs, nameEn);
}

/// Estrellas extra al completar una página.
const pageBonus = 10;

/// Dibujos de emojis antiguos, para que se vean también en teléfonos con Android 7.
const stickerPages = [
  StickerPage('granja', 'Granja', 'Farm', ['🐶', '🐱', '🐮', '🐷', '🦆', '🐴', '🐔', '🐑']),
  StickerPage('frutas', 'Frutas', 'Fruits', ['🍎', '🍌', '🍇', '🍊', '🍓', '🍐', '🍉', '🍒']),
  StickerPage('mar', 'Mar', 'Sea', ['🐋', '🐬', '🐙', '🦈', '🦀', '🐢', '🐚', '🦑']),
  StickerPage('espacio', 'Espacio', 'Space', ['🚀', '🌙', '⭐', '☀️', '🌍', '👽', '☄️', '🌟'], premium: true),
  StickerPage('selva', 'Selva', 'Jungle', ['🦁', '🐵', '🐘', '🐯', '🐍', '🐊', '🐆', '🐗'], premium: true),
  StickerPage('dulces', 'Dulces', 'Sweets', ['🍦', '🍰', '🍩', '🍪', '🍭', '🍬', '🍫', '🍮'], premium: true),
];

int get totalStickers => stickerPages.fold(0, (n, p) => n + p.stickers.length);

/// La página de un sticker (cada sticker es "página:dibujo", porque un dibujo puede repetirse).
StickerPage pageOf(String sticker) => stickerPages.firstWhere((p) => sticker.startsWith('${p.key}:'));
String stickerId(StickerPage page, String picture) => '${page.key}:$picture';
String stickerPicture(String sticker) => sticker.substring(sticker.indexOf(':') + 1);
