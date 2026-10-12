import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/crm_store.dart';
import '../data/product_import.dart';
import '../models.dart';
import 'theme.dart';

/// Right-hand panel next to a conversation: product catalog and client card.
class SidePanel extends StatelessWidget {
  const SidePanel({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: DefaultTabController(
        length: 2,
        child: Column(children: [
          const TabBar(
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [Tab(text: 'Товары'), Tab(text: 'Клиент')],
          ),
          Expanded(
            child: TabBarView(children: [
              ProductsTab(clientId: clientId),
              ClientTab(clientId: clientId),
            ]),
          ),
        ]),
      ),
    );
  }
}

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key, required this.clientId});

  final String clientId;

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  String _query = '';

  Future<void> _import() async {
    final store = context.read<CrmStore>();
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (picked.isEmpty) return;
    final result = parseProductsXlsx(await picked.single.readAsBytes());
    final counts = store.importProducts(result.products);
    final skipped = result.errors.isEmpty ? '' : '\nПропущено строк: ${result.errors.length}. ${result.errors.take(3).join('; ')}';
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text('Добавлено товаров: ${counts.added}, обновлено: ${counts.updated}.$skipped'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final client = store.client(widget.clientId)!;
    final canReply = store.canReply(client);
    final products = store.searchProducts(_query);
    final isOwner = store.currentUser?.isOwner ?? false;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Найти товар', prefixIcon: Icon(Icons.search, size: 20)),
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 6),
            IconButton(tooltip: 'Загрузить товары из Excel', onPressed: _import, icon: const Icon(Icons.upload_file)),
          ],
        ]),
      ),
      Expanded(
        child: products.isEmpty
            ? const Center(child: Text('Ничего не найдено', style: TextStyle(color: AppColors.muted)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final p = products[i];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      ProductPhoto(p),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(formatPrice(p.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(p.stockLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF6B717C))),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                        onPressed: canReply ? () => store.offerProduct(client.id, p) : null,
                        child: const Text('Предложить'),
                      ),
                    ]),
                  );
                },
              ),
      ),
    ]);
  }
}

class ClientTab extends StatefulWidget {
  const ClientTab({super.key, required this.clientId});

  final String clientId;

  @override
  State<ClientTab> createState() => _ClientTabState();
}

class _ClientTabState extends State<ClientTab> {
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: context.read<CrmStore>().client(widget.clientId)!.note);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final client = store.client(widget.clientId)!;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(client.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('${client.channel.title}: ${client.contact}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
      const SizedBox(height: 20),
      const Text('Статус', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final s in ClientStatus.values)
          ChoiceChip(
            label: Text(s.title),
            selected: client.status == s,
            showCheckmark: false,
            selectedColor: AppColors.status(s).$1,
            onSelected: (_) => store.setStatus(client.id, s),
          ),
      ]),
      const SizedBox(height: 20),
      DropdownButtonFormField<String?>(
        initialValue: client.ownerId,
        decoration: const InputDecoration(labelText: 'Ответственный'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Не назначен')),
          for (final e in store.employees) DropdownMenuItem(value: e.id, child: Text(e.name)),
        ],
        onChanged: (id) => store.assign(client.id, id),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: _note,
        minLines: 4,
        maxLines: 8,
        onChanged: (v) => store.setNote(client.id, v),
        decoration: const InputDecoration(labelText: 'Заметка', hintText: 'Например: хочет синее платье, размер M', alignLabelWithHint: true),
      ),
    ]);
  }
}
