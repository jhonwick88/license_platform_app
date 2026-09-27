import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../theme/theme_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final isWide = MediaQuery.of(context).size.width > 900;

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
            extended: isWide,
            minExtendedWidth: 220,
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/products');
                  break;
                case 2:
                  context.go('/plans');
                  break;
                case 3:
                  context.go('/licenses');
                  break;
                case 4:
                  context.go('/customers');
                  break;
                case 5:
                  context.go('/installations');
                  break;
                case 6:
                  context.go('/logs');
                  break;
              }
            },
            leading: SizedBox(
              width: isWide ? 200 : 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
                child: isWide
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.shield_outlined,
                              size: 26,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PINTAR LABS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 0.5,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'License Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.outlineVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apps_outlined),
                selectedIcon: Icon(Icons.apps),
                label: Text('Products'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.layers_outlined),
                selectedIcon: Icon(Icons.layers),
                label: Text('Plans & Features'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_key_outlined),
                selectedIcon: Icon(Icons.vpn_key),
                label: Text('Licenses'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Customers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.devices_outlined),
                selectedIcon: Icon(Icons.devices),
                label: Text('Installations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Validation Logs'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: isWide ? 190 : 56,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Theme switcher button
                        if (isWide)
                          InkWell(
                            onTap: () {
                              ref.read(themeProvider.notifier).toggleTheme();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDark ? Icons.dark_mode : Icons.light_mode,
                                    size: 18,
                                    color: isDark ? Colors.amber : Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isDark ? 'Dark Mode' : 'Light Mode',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.swap_horiz,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.outlineVariant,
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          IconButton.filledTonal(
                            icon: Icon(
                              isDark ? Icons.dark_mode : Icons.light_mode,
                              size: 20,
                              color: isDark ? Colors.amber : Colors.orange,
                            ),
                            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                            onPressed: () {
                              ref.read(themeProvider.notifier).toggleTheme();
                            },
                          ),
                        const SizedBox(height: 12),
                        // Logout button
                        if (isWide)
                          InkWell(
                            onTap: () {
                              ref.read(authProvider.notifier).logout();
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout, size: 18, color: Colors.red),
                                  SizedBox(width: 10),
                                  Text(
                                    'Logout',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.red),
                            tooltip: 'Logout',
                            onPressed: () {
                              ref.read(authProvider.notifier).logout();
                            },
                          ),
                      ],
                    ),
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
