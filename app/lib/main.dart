import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/crm_store.dart';
import 'ui/inbox_screen.dart';
import 'ui/login_screen.dart';
import 'ui/theme.dart';

void main() {
  runApp(ProstoCrmApp(store: CrmStore.demo()));
}

class ProstoCrmApp extends StatelessWidget {
  const ProstoCrmApp({super.key, required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        title: 'PROSTO CRM',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: Consumer<CrmStore>(
          builder: (context, store, _) => store.currentUser == null ? const LoginScreen() : const InboxScreen(),
        ),
      ),
    );
  }
}
