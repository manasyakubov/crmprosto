import 'package:flutter/foundation.dart';

import '../models.dart';

/// Holds all CRM data and the rules for changing it.
///
/// For now the data lives in memory and starts from [CrmStore.demo]. Firestore
/// and the WhatsApp/Instagram gateways plug in behind the same methods.
class CrmStore extends ChangeNotifier {
  CrmStore({
    required List<Employee> employees,
    required List<Client> clients,
    required List<Message> messages,
    required List<Product> products,
    DateTime Function()? clock,
  })  : _employees = List.of(employees),
        _clients = {for (final c in clients) c.id: c},
        _messages = List.of(messages),
        _products = {for (final p in products) p.sku: p},
        _clock = clock ?? DateTime.now;

  static const replyWindow = Duration(hours: 24);

  final List<Employee> _employees;
  final Map<String, Client> _clients;
  final List<Message> _messages;
  final Map<String, Product> _products;
  final DateTime Function() _clock;
  int _nextId = 1;

  Employee? _currentUser;
  Employee? get currentUser => _currentUser;
  List<Employee> get employees => List.unmodifiable(_employees);

  void signIn(Employee employee) {
    _currentUser = employee;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  Employee? employee(String? id) {
    for (final e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  Client? client(String id) => _clients[id];

  List<Message> messagesFor(String clientId) =>
      _messages.where((m) => m.clientId == clientId).toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));

  Message? lastMessage(String clientId) {
    final list = messagesFor(clientId);
    return list.isEmpty ? null : list.last;
  }

  /// Clients ordered by most recent message first, filtered by [filter] and [query].
  List<Client> inbox({InboxFilter filter = InboxFilter.all, String query = ''}) {
    final q = query.trim().toLowerCase();
    final list = _clients.values.where((c) {
      final matchesFilter = switch (filter) {
        InboxFilter.all => true,
        InboxFilter.mine => c.ownerId != null && c.ownerId == _currentUser?.id,
        InboxFilter.newOnes => c.status == ClientStatus.newLead,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.contact.toLowerCase().replaceAll(' ', '').contains(q.replaceAll(' ', ''));
    }).toList();
    DateTime lastAt(Client c) => lastMessage(c.id)?.sentAt ?? c.firstMessageAt;
    list.sort((a, b) => lastAt(b).compareTo(lastAt(a)));
    return list;
  }

  bool canReply(Client client) => _clock().difference(client.lastIncomingAt) < replyWindow;

  void markRead(String clientId) {
    final c = _clients[clientId];
    if (c == null || c.unread == 0) return;
    c.unread = 0;
    notifyListeners();
  }

  /// Sends a reply. The first employee to answer a client becomes its owner,
  /// and a new client moves to "in work".
  Message? send(String clientId, String text, {String? productSku}) {
    final c = _clients[clientId];
    final me = _currentUser;
    final trimmed = text.trim();
    if (c == null || me == null || trimmed.isEmpty || !canReply(c)) return null;
    final msg = Message(
      id: 'm${_nextId++}',
      clientId: clientId,
      outgoing: true,
      text: trimmed,
      sentAt: _clock(),
      authorId: me.id,
      productSku: productSku,
    );
    _messages.add(msg);
    c.ownerId ??= me.id;
    if (c.status == ClientStatus.newLead) c.status = ClientStatus.inWork;
    notifyListeners();
    return msg;
  }

  Message? offerProduct(String clientId, Product product) =>
      send(clientId, '${product.name}, ${formatPrice(product.price)}', productSku: product.sku);

  /// Records a message that came in from WhatsApp or Instagram.
  void receive(String clientId, String text) {
    final c = _clients[clientId];
    if (c == null) return;
    final now = _clock();
    _messages.add(Message(id: 'm${_nextId++}', clientId: clientId, outgoing: false, text: text, sentAt: now));
    c.lastIncomingAt = now;
    c.unread++;
    notifyListeners();
  }

  void setStatus(String clientId, ClientStatus status) {
    _clients[clientId]?.status = status;
    notifyListeners();
  }

  void assign(String clientId, String? employeeId) {
    _clients[clientId]?.ownerId = employeeId;
    notifyListeners();
  }

  void setNote(String clientId, String note) {
    _clients[clientId]?.note = note;
    notifyListeners();
  }

  Product? product(String sku) => _products[sku];

  List<Product> searchProducts(String query) {
    final q = query.trim().toLowerCase();
    final list = _products.values
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q) || p.category.toLowerCase().contains(q))
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Adds new products and replaces existing ones with the same SKU.
  /// Returns how many were added and how many updated.
  ({int added, int updated}) importProducts(List<Product> products) {
    var added = 0;
    var updated = 0;
    for (final p in products) {
      if (_products.containsKey(p.sku)) {
        updated++;
      } else {
        added++;
      }
      _products[p.sku] = p;
    }
    notifyListeners();
    return (added: added, updated: updated);
  }

  factory CrmStore.demo({DateTime Function()? clock}) {
    final now = (clock ?? DateTime.now)();
    DateTime ago(Duration d) => now.subtract(d);
    const aziz = Employee(id: 'e1', name: 'Азиз', isOwner: true);
    const kamola = Employee(id: 'e2', name: 'Камола');
    final clients = [
      Client(id: 'c1', name: 'Дилноза Каримова', channel: Channel.whatsapp, contact: '+998 90 123 45 67', firstMessageAt: ago(const Duration(minutes: 9)), unread: 2, lastIncomingAt: ago(const Duration(minutes: 5))),
      Client(id: 'c2', name: '@malika.style', channel: Channel.instagram, contact: '@malika.style', firstMessageAt: ago(const Duration(minutes: 20)), unread: 1),
      Client(id: 'c3', name: 'Бахтиёр', channel: Channel.whatsapp, contact: '+998 93 555 12 00', firstMessageAt: ago(const Duration(hours: 2)), status: ClientStatus.inWork, ownerId: 'e1'),
      Client(id: 'c4', name: '@sardor_m', channel: Channel.instagram, contact: '@sardor_m', firstMessageAt: ago(const Duration(hours: 3)), status: ClientStatus.bought, ownerId: 'e1'),
      Client(id: 'c5', name: 'Нигора', channel: Channel.whatsapp, contact: '+998 97 700 44 21', firstMessageAt: ago(const Duration(hours: 26)), status: ClientStatus.inWork, ownerId: 'e2'),
      Client(id: 'c6', name: '@anvar.uz', channel: Channel.instagram, contact: '@anvar.uz', firstMessageAt: ago(const Duration(days: 3)), status: ClientStatus.declined, ownerId: 'e2'),
    ];
    Message inMsg(String id, String c, String t, Duration d) => Message(id: id, clientId: c, outgoing: false, text: t, sentAt: ago(d));
    Message outMsg(String id, String c, String t, Duration d, String by) => Message(id: id, clientId: c, outgoing: true, text: t, sentAt: ago(d), authorId: by);
    final messages = [
      inMsg('d1', 'c1', 'Здравствуйте! Видела у вас синее платье.', const Duration(minutes: 9)),
      inMsg('d2', 'c1', 'Есть размер M?', const Duration(minutes: 5)),
      inMsg('d3', 'c2', 'Сколько стоит доставка в Самарканд?', const Duration(minutes: 20)),
      inMsg('d4', 'c3', 'Беру две штуки, пришлите счёт', const Duration(hours: 2)),
      outMsg('d5', 'c3', 'Отправил счёт, ждём оплату', const Duration(minutes: 110), 'e1'),
      inMsg('d6', 'c4', 'Спасибо, всё получил!', const Duration(hours: 3)),
      inMsg('d7', 'c5', 'Подумаю до завтра', const Duration(hours: 26)),
      outMsg('d8', 'c5', 'Хорошо, напишу завтра', const Duration(hours: 25), 'e2'),
      inMsg('d9', 'c6', 'Дорого, пока не буду', const Duration(days: 3)),
    ];
    const products = [
      Product(sku: 'PR-001', name: 'Платье синее, миди', price: 320000, category: 'Платья', variants: 'S, M, L', stock: 12),
      Product(sku: 'PR-002', name: 'Платье чёрное, макси', price: 380000, category: 'Платья', variants: 'M, L', stock: 4),
      Product(sku: 'PR-003', name: 'Худи оверсайз, бежевое', price: 240000, category: 'Худи', variants: 'M, L, XL', stock: 20),
      Product(sku: 'PR-004', name: 'Брюки палаццо', price: 210000, category: 'Брюки', variants: 'S, M', stock: 7),
      Product(sku: 'PR-005', name: 'Рубашка льняная', price: 190000, category: 'Рубашки', stock: 0),
      Product(sku: 'PR-006', name: 'Сумка кожаная', price: 450000, category: 'Аксессуары', stock: 3),
    ];
    return CrmStore(employees: const [aziz, kamola], clients: clients, messages: messages, products: products, clock: clock);
  }
}

enum InboxFilter {
  all('Все'),
  mine('Мои'),
  newOnes('Новые');

  const InboxFilter(this.title);
  final String title;
}
