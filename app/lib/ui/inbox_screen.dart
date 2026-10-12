import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/crm_store.dart';
import '../models.dart';
import 'chat_view.dart';
import 'side_panel.dart';
import 'theme.dart';

/// Main screen. On a wide screen: chats | conversation | products and client.
/// On a phone: the chat list, and a conversation opens on top of it.
class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  String? _selectedId;

  void _open(BuildContext context, Client client, bool wide) {
    context.read<CrmStore>().markRead(client.id);
    if (wide) {
      setState(() => _selectedId = client.id);
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _PhoneChatPage(clientId: client.id)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1000;
      final medium = constraints.maxWidth >= 700;
      final store = context.watch<CrmStore>();
      final selected = _selectedId == null ? null : store.client(_selectedId!);
      final list = ChatList(selectedId: wide || medium ? _selectedId : null, onOpen: (c) => _open(context, c, medium));

      return Scaffold(
        appBar: const _TopBar(),
        endDrawer: !wide && medium && selected != null ? Drawer(width: 360, child: SidePanel(clientId: selected.id)) : null,
        body: !medium
            ? list
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: wide ? 360 : 320, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: selected == null
                        ? const Center(child: Text('Выберите чат слева', style: TextStyle(color: AppColors.muted)))
                        : ChatView(key: ValueKey(selected.id), clientId: selected.id, showPanelButton: !wide),
                  ),
                  if (wide && selected != null) ...[
                    const VerticalDivider(width: 1),
                    SizedBox(width: 360, child: SidePanel(key: ValueKey('panel-${selected.id}'), clientId: selected.id)),
                  ],
                ],
              ),
      );
    });
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar();

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final me = store.currentUser!;
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
      titleSpacing: 20,
      title: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: const Text('P', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        const Text('PROSTO CRM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
      actions: [
        if (MediaQuery.sizeOf(context).width >= 600)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text(me.name, style: const TextStyle(fontWeight: FontWeight.w600))),
          ),
        IconButton(tooltip: 'Выйти', onPressed: store.signOut, icon: const Icon(Icons.logout)),
        const SizedBox(width: 12),
      ],
    );
  }
}

class ChatList extends StatefulWidget {
  const ChatList({super.key, required this.selectedId, required this.onOpen});

  final String? selectedId;
  final ValueChanged<Client> onOpen;

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  InboxFilter _filter = InboxFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final clients = store.inbox(filter: _filter, query: _query);
    return ColoredBox(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(children: [
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Поиск по имени или номеру',
                prefixIcon: Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Color(0xFFF1F2F4),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              for (final f in InboxFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(f.title),
                    selected: _filter == f,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ]),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: clients.isEmpty
              ? const Center(child: Text('Чатов нет', style: TextStyle(color: AppColors.muted)))
              : ListView.separated(
                  itemCount: clients.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEF0F2)),
                  itemBuilder: (context, i) => _ChatRow(client: clients[i], selected: clients[i].id == widget.selectedId, onTap: () => widget.onOpen(clients[i])),
                ),
        ),
      ]),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.client, required this.selected, required this.onTap});

  final Client client;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = context.read<CrmStore>();
    final last = store.lastMessage(client.id);
    final owner = store.employee(client.ownerId)?.name ?? 'не назначен';
    return Material(
      color: selected ? const Color(0xFFF0F2FC) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Avatar(client.initials, channel: client.channel),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(client.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                  if (last != null) Text(formatTime(last.sentAt), style: const TextStyle(fontSize: 12, color: Color(0xFF6B717C))),
                ]),
                const SizedBox(height: 3),
                Text(
                  last == null ? '' : '${last.outgoing ? 'Вы: ' : ''}${last.text}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(children: [
                  StatusPill(client.status),
                  const SizedBox(width: 6),
                  Expanded(child: Text(owner, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Color(0xFF6B717C)))),
                  if (client.unread > 0)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                      child: Text('${client.unread}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PhoneChatPage extends StatelessWidget {
  const _PhoneChatPage({required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, surfaceTintColor: Colors.white, shape: const Border(bottom: BorderSide(color: AppColors.line))),
      endDrawer: Drawer(width: 340, child: SidePanel(clientId: clientId)),
      body: ChatView(clientId: clientId, showPanelButton: true),
    );
  }
}

String formatTime(DateTime t) {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  if (sameDay) return '${two(t.hour)}:${two(t.minute)}';
  final yesterday = now.subtract(const Duration(days: 1));
  if (t.year == yesterday.year && t.month == yesterday.month && t.day == yesterday.day) return 'Вчера';
  return '${two(t.day)}.${two(t.month)}';
}
