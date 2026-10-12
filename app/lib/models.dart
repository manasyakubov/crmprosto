enum Channel {
  whatsapp('WhatsApp', 'WA'),
  instagram('Instagram', 'IG');

  const Channel(this.title, this.short);
  final String title;
  final String short;
}

enum ClientStatus {
  newLead('Новый'),
  inWork('В работе'),
  bought('Купил'),
  declined('Отказ');

  const ClientStatus(this.title);
  final String title;
}

class Employee {
  const Employee({required this.id, required this.name, this.isOwner = false});

  final String id;
  final String name;
  final bool isOwner;

  String get initials => name.isEmpty ? '?' : name.substring(0, name.length < 2 ? 1 : 2).toUpperCase();
}

class Client {
  Client({
    required this.id,
    required this.name,
    required this.channel,
    required this.contact,
    required this.firstMessageAt,
    this.status = ClientStatus.newLead,
    this.ownerId,
    this.note = '',
    this.unread = 0,
    DateTime? lastIncomingAt,
  }) : lastIncomingAt = lastIncomingAt ?? firstMessageAt;

  final String id;
  final String name;
  final Channel channel;

  /// Phone number for WhatsApp, username for Instagram.
  final String contact;
  final DateTime firstMessageAt;
  ClientStatus status;
  String? ownerId;
  String note;
  int unread;

  /// Meta only allows free-form replies within 24 hours of the client's last message.
  DateTime lastIncomingAt;

  String get initials {
    final parts = name.replaceAll('@', '').split(RegExp(r'[\s._]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class Message {
  const Message({
    required this.id,
    required this.clientId,
    required this.outgoing,
    required this.text,
    required this.sentAt,
    this.authorId,
    this.productSku,
  });

  final String id;
  final String clientId;
  final bool outgoing;
  final String text;
  final DateTime sentAt;

  /// Employee who sent an outgoing message.
  final String? authorId;

  /// Set when the message is a product offer.
  final String? productSku;
}

class Product {
  const Product({
    required this.sku,
    required this.name,
    required this.price,
    this.category = '',
    this.variants = '',
    this.stock,
    this.photoUrl = '',
    this.description = '',
  });

  final String sku;
  final String name;

  /// Price in sum, whole numbers.
  final int price;
  final String category;
  final String variants;
  final int? stock;
  final String photoUrl;
  final String description;

  String get stockLabel {
    final parts = <String>[
      if (variants.isNotEmpty) variants,
      if (stock == null) 'наличие не указано' else if (stock == 0) 'нет в наличии' else '$stock шт',
    ];
    return parts.join(' · ');
  }
}

String formatPrice(int sum) {
  final digits = sum.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return '$buf сум';
}
