import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    
    int selectedIndex = 0;
    if (location.startsWith('/products')) selectedIndex = 1;
    if (location.startsWith('/plans')) selectedIndex = 2;
    if (location.startsWith('/licenses')) selectedIndex = 3;
    if (location.startsWith('/customers')) selectedIndex = 4;
    if (location.startsWith('/installations')) selectedIndex = 5;
    if (location.startsWith('/logs')) selectedIndex = 6;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0: context.go('/dashboard'); break;
                case 1: context.go('/products'); break;
                case 2: context.go('/plans'); break;
                case 3: context.go('/licenses'); break;
                case 4: context.go('/customers'); break;
                case 5: context.go('/installations'); break;
                case 6: context.go('/logs'); break;
              }
            },
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Icon(Icons.security, size: 32, color: Colors.blueAccent),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.apps), label: Text('Products')),
              NavigationRailDestination(icon: Icon(Icons.view_list), label: Text('Plans & Features')),
              NavigationRailDestination(icon: Icon(Icons.vpn_key), label: Text('Licenses')),
              NavigationRailDestination(icon: Icon(Icons.people), label: Text('Customers')),
              NavigationRailDestination(icon: Icon(Icons.desktop_windows), label: Text('Installations')),
              NavigationRailDestination(icon: Icon(Icons.history), label: Text('Audit Logs')),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    onPressed: () {
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
