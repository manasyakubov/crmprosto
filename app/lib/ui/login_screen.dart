import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/crm_store.dart';
import 'theme.dart';

/// Demo sign-in: pick an employee. Replaced by Firebase Auth later.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.read<CrmStore>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: const Text('P', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('PROSTO CRM', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Все сообщения из WhatsApp и Instagram в одном месте.', style: TextStyle(fontSize: 16, color: AppColors.muted, height: 1.5)),
                const SizedBox(height: 32),
                const Text('Демо-версия: выберите сотрудника', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                for (final e in store.employees)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () => store.signIn(e),
                      child: Text(e.isOwner ? 'Войти как ${e.name} (владелец)' : 'Войти как ${e.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
