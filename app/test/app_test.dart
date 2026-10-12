import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prosto_crm/data/crm_store.dart';
import 'package:prosto_crm/main.dart';
import 'package:prosto_crm/ui/chat_view.dart';

void main() {
  testWidgets('sign in, open a chat and offer a product', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final store = CrmStore.demo();
    await tester.pumpWidget(ProstoCrmApp(store: store));

    await tester.tap(find.textContaining('Войти как Азиз'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите чат слева'), findsOneWidget);

    await tester.tap(find.text('Дилноза Каримова'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ChatView), matching: find.text('Есть размер M?')), findsOneWidget);
    expect(find.text('Предложить'), findsWidgets);

    await tester.tap(find.text('Предложить').first);
    await tester.pumpAndSettle();

    expect(store.lastMessage('c1')!.productSku, isNotNull);
    expect(find.textContaining('Ответственный: Азиз'), findsOneWidget);
  });

  testWidgets('phone layout opens a chat on its own page', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProstoCrmApp(store: CrmStore.demo()));
    await tester.tap(find.textContaining('Войти как Камола'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Бахтиёр'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ChatView), matching: find.text('Отправил счёт, ждём оплату')), findsOneWidget);
  });
}
