import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ApplicationShell extends StatelessWidget {
  final Widget child;

  const ApplicationShell({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/reports');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/transactions/add');
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                Icons.home,
                color: currentIndex == 0 ? Theme.of(context).primaryColor : Colors.grey,
              ),
              onPressed: () => _onItemTapped(0, context),
            ),
            IconButton(
              icon: Icon(
                Icons.list,
                color: currentIndex == 1 ? Theme.of(context).primaryColor : Colors.grey,
              ),
              onPressed: () => _onItemTapped(1, context),
            ),
            const SizedBox(width: 48), // Space for FAB
            IconButton(
              icon: Icon(
                Icons.pie_chart,
                color: currentIndex == 2 ? Theme.of(context).primaryColor : Colors.grey,
              ),
              onPressed: () => _onItemTapped(2, context),
            ),
            IconButton(
              icon: Icon(
                Icons.settings,
                color: currentIndex == 3 ? Theme.of(context).primaryColor : Colors.grey,
              ),
              onPressed: () => _onItemTapped(3, context),
            ),
          ],
        ),
      ),
    );
  }
}
