import 'package:flutter_test/flutter_test.dart';
import 'package:prosto_crm/data/crm_store.dart';
import 'package:prosto_crm/models.dart';

void main() {
  late DateTime now;
  late CrmStore store;

  setUp(() {
    now = DateTime(2026, 10, 12, 14, 0);
    store = CrmStore.demo(clock: () => now);
    store.signIn(store.employees.first);
  });

  test('first reply assigns the client and moves it to "in work"', () {
    final client = store.client('c1')!;
    expect(client.ownerId, isNull);
    expect(client.status, ClientStatus.newLead);

    final sent = store.send('c1', '  Да, есть  ');

    expect(sent!.text, 'Да, есть');
    expect(sent.authorId, 'e1');
    expect(client.ownerId, 'e1');
    expect(client.status, ClientStatus.inWork);
    expect(store.lastMessage('c1'), sent);
  });

  test('a reply does not take a client from another employee', () {
    store.signIn(store.employees.last);
    store.send('c3', 'Здравствуйте');
    expect(store.client('c3')!.ownerId, 'e1');
  });

  test('replies are blocked 24 hours after the last incoming message', () {
    expect(store.canReply(store.client('c5')!), isFalse);
    expect(store.send('c5', 'Привет'), isNull);

    store.receive('c5', 'Я вернулась');
    expect(store.canReply(store.client('c5')!), isTrue);
    expect(store.client('c5')!.unread, 1);
    expect(store.send('c5', 'Рады!'), isNotNull);
  });

  test('offering a product sends its name and price', () {
    final product = store.product('PR-001')!;
    final msg = store.offerProduct('c2', product);
    expect(msg!.productSku, 'PR-001');
    expect(msg.text, 'Платье синее, миди, 320 000 сум');
  });

  test('inbox filters and search', () {
    expect(store.inbox().first.id, 'c1');
    expect(store.inbox(filter: InboxFilter.mine).map((c) => c.id), ['c3', 'c4']);
    expect(store.inbox(filter: InboxFilter.newOnes).map((c) => c.id), ['c1', 'c2']);
    expect(store.inbox(query: '90123').single.id, 'c1');
    expect(store.inbox(query: 'нигора').single.id, 'c5');
  });

  test('import adds new products and updates existing by SKU', () {
    final counts = store.importProducts(const [
      Product(sku: 'PR-001', name: 'Платье синее, миди', price: 299000),
      Product(sku: 'NEW-1', name: 'Ремень', price: 99000),
    ]);
    expect(counts, (added: 1, updated: 1));
    expect(store.product('PR-001')!.price, 299000);
    expect(store.searchProducts('рем').single.sku, 'NEW-1');
  });

  test('price formatting groups thousands', () {
    expect(formatPrice(320000), '320 000 сум');
    expect(formatPrice(1250000), '1 250 000 сум');
    expect(formatPrice(900), '900 сум');
  });
}
