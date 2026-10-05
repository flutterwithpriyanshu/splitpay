import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:splitpay/theme/app_colors.dart';
import 'package:splitpay/widgets/app_ui.dart';
import 'package:splitpay/screens/home_screen.dart';
import 'package:splitpay/screens/wallet_screen.dart';
import 'package:splitpay/screens/friends_screen.dart';
import 'package:splitpay/screens/groups_screen.dart';

/// Lets any screen switch the bottom dock tab
/// (0 home, 1 friends, 2 groups, 3 wallet).
final ValueNotifier<int> mainTabNotifier = ValueNotifier<int>(0);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    mainTabNotifier.value = _currentIndex;
    mainTabNotifier.addListener(_onTabRequested);
  }

  @override
  void dispose() {
    mainTabNotifier.removeListener(_onTabRequested);
    super.dispose();
  }

  void _onTabRequested() {
    final i = mainTabNotifier.value;
    if (i != _currentIndex && mounted) setState(() => _currentIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const FriendsScreen(),
      const GroupsScreen(),
      const WalletScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      // Floating pill dock. Kept in bottomNavigationBar so each tab's own
      // FAB still sits above it instead of hiding behind it.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.sm,
            bottom: AppSpacing.dockBottomGap,
          ),
          child: FloatingDock(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              mainTabNotifier.value = i;
            },
            items: [
              DockItem(Icons.home_rounded, 'home'.tr()),
              DockItem(Icons.people_alt_rounded, 'friends'.tr()),
              DockItem(Icons.groups_rounded, 'groups'.tr()),
              DockItem(Icons.account_balance_wallet_rounded, 'wallet'.tr()),
            ],
          ),
        ),
      ),
    );
  }
}
