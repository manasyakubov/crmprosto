import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prosto_crm/data/product_import.dart';

void main() {
  test('reads the Excel template', () {
    final bytes = File('test/fixtures/products_template.xlsx').readAsBytesSync();
    final result = parseProductsXlsx(bytes);
    expect(result.errors, isEmpty);
    expect(result.products, hasLength(2));
    final dress = result.products.first;
    expect(dress.sku, 'PR-001');
    expect(dress.name, 'Платье синее, миди');
    expect(dress.price, 320000);
    expect(dress.variants, 'S, M, L');
    expect(dress.stock, 12);
    expect(dress.photoUrl, 'pr-001.jpg');
  });

  test('finds columns by header, skips bad rows and reports them', () {
    final result = parseProductRows([
      ['Цена, сум', 'Название', 'Артикул', 'Остаток, шт'],
      ['150 000', 'Шарф', 'A1', ''],
      ['', '', '', ''],
      ['дорого', 'Шапка', 'A2', '3'],
      ['90000', '', 'A3', '1'],
      ['100000', 'Шарф другой', 'A1', '1'],
    ]);
    expect(result.products.single.name, 'Шарф');
    expect(result.products.single.price, 150000);
    expect(result.products.single.stock, isNull);
    expect(result.errors, [
      'Строка 4: цена «дорого» не число',
      'Строка 5: не указано название',
      'Строка 6: артикул A1 повторяется, строка пропущена',
    ]);
  });

  test('rejects a table without name and price columns', () {
    final result = parseProductRows([
      ['Товар', 'Стоимость'],
      ['Шарф', '1'],
    ]);
    expect(result.products, isEmpty);
    expect(result.errors.single, contains('Используйте шаблон'));
  });
}
