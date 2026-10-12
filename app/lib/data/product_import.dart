import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

import '../models.dart';

class ProductImportResult {
  const ProductImportResult(this.products, this.errors);

  final List<Product> products;

  /// One line per skipped row, e.g. "Строка 5: не указана цена".
  final List<String> errors;
}

/// Reads products from the first sheet of an .xlsx file made from the
/// template (товары_шаблон.xlsx). Columns are found by their header names,
/// so their order does not matter.
ProductImportResult parseProductsXlsx(List<int> bytes) {
  final Excel excel;
  try {
    excel = Excel.decodeBytes(_relativizeSheetPaths(bytes));
  } catch (_) {
    return const ProductImportResult([], ['Не удалось прочитать файл. Сохраните его в Excel как .xlsx и попробуйте снова.']);
  }
  if (excel.tables.isEmpty) return const ProductImportResult([], ['В файле нет листов']);
  final sheet = excel.tables[excel.tables.keys.first]!;
  final rows = sheet.rows.map((r) => r.map((c) => _text(c?.value)).toList()).toList();
  return parseProductRows(rows);
}

ProductImportResult parseProductRows(List<List<String>> rows) {
  if (rows.isEmpty) return const ProductImportResult([], ['Таблица пустая']);
  final header = rows.first.map((h) => h.toLowerCase()).toList();
  int col(String prefix) => header.indexWhere((h) => h.startsWith(prefix));
  final sku = col('артикул');
  final name = col('название');
  final price = col('цена');
  final category = col('категория');
  final variants = col('размер');
  final stock = col('остаток');
  final photo = col('фото');
  final description = col('описание');
  if (name < 0 || price < 0) {
    return const ProductImportResult([], ['Нет колонок «Название» и «Цена». Используйте шаблон.']);
  }

  final products = <Product>[];
  final errors = <String>[];
  final seen = <String>{};
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    String at(int c) => c >= 0 && c < row.length ? row[c].trim() : '';
    if (row.every((v) => v.trim().isEmpty)) continue;
    final line = i + 1;
    final title = at(name);
    if (title.isEmpty) {
      errors.add('Строка $line: не указано название');
      continue;
    }
    final parsedPrice = _parseInt(at(price));
    if (parsedPrice == null) {
      errors.add('Строка $line: цена «${at(price)}» не число');
      continue;
    }
    final code = at(sku).isNotEmpty ? at(sku) : title;
    if (!seen.add(code)) {
      errors.add('Строка $line: артикул $code повторяется, строка пропущена');
      continue;
    }
    final stockText = at(stock);
    products.add(Product(
      sku: code,
      name: title,
      price: parsedPrice,
      category: at(category),
      variants: at(variants),
      stock: stockText.isEmpty ? null : _parseInt(stockText),
      photoUrl: at(photo),
      description: at(description),
    ));
  }
  return ProductImportResult(products, errors);
}

/// Some programs (openpyxl, which made our template) write sheet paths as
/// "/xl/worksheets/…", which the excel package cannot resolve. Rewrite them
/// to the relative "worksheets/…" form Excel itself uses.
List<int> _relativizeSheetPaths(List<int> bytes) {
  const relsPath = 'xl/_rels/workbook.xml.rels';
  final archive = ZipDecoder().decodeBytes(bytes);
  final rels = archive.findFile(relsPath);
  if (rels == null) return bytes;
  final xml = utf8.decode(rels.content as List<int>);
  if (!xml.contains('Target="/xl/')) return bytes;
  final fixed = Archive();
  for (final f in archive.files) {
    fixed.addFile(f.name == relsPath ? ArchiveFile.string(relsPath, xml.replaceAll('Target="/xl/', 'Target="')) : f);
  }
  return ZipEncoder().encode(fixed)!;
}

int? _parseInt(String s) {
  final cleaned = s.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(RegExp(r'сум$', caseSensitive: false), '');
  final asDouble = double.tryParse(cleaned.replaceAll(',', '.'));
  if (asDouble == null || asDouble < 0) return null;
  return asDouble.round();
}

String _text(CellValue? v) => switch (v) {
      null => '',
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString(),
      _ => v.toString(),
    };
