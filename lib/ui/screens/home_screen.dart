import 'package:flutter/material.dart';

import '../../data/models/cashier_session.dart';
import '../../data/repositories/auth_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.authRepository,
    required this.onLoggedOut,
  });

  final CashierSession session;
  final AuthRepository authRepository;
  final VoidCallback onLoggedOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ethiomark Bingo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepository.logout(session.cashierId);
              onLoggedOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cashier: ${session.cashierId}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Category: ${session.category}'),
                    const SizedBox(height: 8),
                    Text(
                      'Package balance: ${session.packageBalance} birr',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Phase 1 complete',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Offline SQLite, encrypted package, and login are working. '
              'Next steps: game screen, report page, and package deposit modal.',
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Game screen — coming in Phase 2'),
                  ),
                );
              },
              icon: const Icon(Icons.casino),
              label: const Text('Start game (Phase 2)'),
            ),
          ],
        ),
      ),
    );
  }
}
