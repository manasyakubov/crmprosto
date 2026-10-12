import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/crm_store.dart';
import '../models.dart';
import 'inbox_screen.dart' show formatTime;
import 'theme.dart';

const quickReplies = ['Здравствуйте! Сейчас уточню', 'Есть в наличии', 'Доставка 1–2 дня'];

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.clientId, this.showPanelButton = false});

  final String clientId;

  /// Shows a button that opens products and client details in a drawer.
  final bool showPanelButton;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final sent = context.read<CrmStore>().send(widget.clientId, _input.text);
    if (sent != null) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final client = store.client(widget.clientId)!;
    final messages = store.messagesFor(client.id);
    final owner = store.employee(client.ownerId);
    final canReply = store.canReply(client);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(client.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text('${client.channel.title} · ${client.contact}', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ]),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (owner == null)
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.ink),
                  onPressed: () => store.assign(client.id, store.currentUser!.id),
                  child: const Text('Взять себе'),
                )
              else
                Flexible(
                  child: Chip(
                    label: Text('Ответственный: ${owner.name}', overflow: TextOverflow.ellipsis),
                    side: BorderSide.none,
                    backgroundColor: const Color(0xFFF1F2F4),
                  ),
                ),
              if (widget.showPanelButton) ...[
                const SizedBox(width: 4),
                Builder(
                  builder: (context) => IconButton(
                    tooltip: 'Товары и клиент',
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                    icon: const Icon(Icons.storefront_outlined),
                  ),
                ),
              ],
            ]),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, i) {
            final m = messages[messages.length - 1 - i];
            return _Bubble(message: m, author: store.employee(m.authorId)?.name, product: m.productSku == null ? null : store.product(m.productSku!));
          },
        ),
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: canReply
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final q in quickReplies)
                    ActionChip(label: Text(q), onPressed: () => _input.text = q),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(hintText: 'Напишите ответ. Enter отправляет'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _send,
                    child: const Text('Отправить'),
                  ),
                ]),
              ])
            : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFFFF1DC), borderRadius: BorderRadius.circular(12)),
                child: const Text(
                  'Клиент писал больше 24 часов назад. По правилам Meta ответить можно, только когда он напишет снова '
                  '(в WhatsApp позже можно будет отправить одобренный шаблон).',
                  style: TextStyle(color: Color(0xFF7A4A00), height: 1.4),
                ),
              ),
      ),
    ]);
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, this.author, this.product});

  final Message message;
  final String? author;
  final Product? product;

  @override
  Widget build(BuildContext context) {
    final out = message.outgoing;
    final fg = out ? Colors.white : AppColors.ink;
    return Align(
      alignment: out ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: out ? AppColors.accent : Colors.white,
            border: out ? null : Border.all(color: AppColors.line),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(out ? 14 : 4),
              bottomRight: Radius.circular(out ? 4 : 14),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            if (product != null) ...[ProductPhoto(product!, size: 160), const SizedBox(height: 8)],
            SelectableText(message.text, style: TextStyle(color: fg, fontSize: 15, height: 1.45)),
            const SizedBox(height: 4),
            Text(
              [?author, formatTime(message.sentAt)].join(' · '),
              style: TextStyle(color: fg.withValues(alpha: 0.75), fontSize: 11),
            ),
          ]),
        ),
      ),
    );
  }
}
