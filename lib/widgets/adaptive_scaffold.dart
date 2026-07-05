import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../core/app_colors.dart';

class NavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int badge;
  const NavItem({required this.icon, this.activeIcon, required this.label, this.badge = 0});
}

class AdaptiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<NavItem> items;
  final String? userName;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.items,
    this.userName,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) return _buildDesktop(context);
    if (Responsive.isTablet(context)) return _buildTablet(context);
    return _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: body,
      bottomNavigationBar: _BottomNav(items: items, selectedIndex: selectedIndex, onTap: onDestinationSelected),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }

  Widget _buildTablet(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Row(children: [
        NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          selectedIconTheme: IconThemeData(color: AppColors.primary),
          selectedLabelTextStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelTextStyle: const TextStyle(fontSize: 11),
          destinations: items.map((e) => NavigationRailDestination(
            icon: e.badge > 0
                ? Badge(label: Text('${e.badge > 99 ? "99+" : e.badge}'), child: Icon(e.icon))
                : Icon(e.icon),
            selectedIcon: Icon(e.activeIcon ?? e.icon),
            label: Text(e.label),
          )).toList(),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: body),
      ]),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Row(children: [
        SizedBox(
          width: 220,
          child: Material(
            color: Colors.white,
            elevation: 1,
            child: Column(children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  Container(width: 32, height: 32,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)))),
                  const SizedBox(width: 10),
                  const Text('MaterialesYa', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              ),
              const SizedBox(height: 16),
              ...List.generate(items.length, (i) {
                final item = items[i];
                final selected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ListTile(
                    selected: selected,
                    selectedTileColor: AppColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: item.badge > 0
                        ? Badge(label: Text('${item.badge > 99 ? "99+" : item.badge}'),
                            child: Icon(selected ? (item.activeIcon ?? item.icon) : item.icon,
                              color: selected ? AppColors.primary : Colors.grey.shade600))
                        : Icon(selected ? (item.activeIcon ?? item.icon) : item.icon,
                            color: selected ? AppColors.primary : Colors.grey.shade600),
                    title: Text(item.label, style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : Colors.grey.shade800,
                      fontSize: 14,
                    )),
                    onTap: () => onDestinationSelected(i),
                  ),
                );
              }),
              const Spacer(),
              if (userName != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.primary,
                      child: Text(userName![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 10),
                    Expanded(child: Text(userName!, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                  ]),
                ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        const VerticalDivider(thickness: 1, width: 1),
        Expanded(child: body),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.items, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    item.badge > 0
                        ? Badge(label: Text('${item.badge > 99 ? "99+" : item.badge}'),
                            child: Icon(selected ? (item.activeIcon ?? item.icon) : item.icon,
                              color: selected ? AppColors.primary : Colors.grey, size: 22))
                        : Icon(selected ? (item.activeIcon ?? item.icon) : item.icon,
                            color: selected ? AppColors.primary : Colors.grey, size: 22),
                    const SizedBox(height: 2),
                    Text(item.label, style: TextStyle(
                      fontSize: 10,
                      color: selected ? AppColors.primary : Colors.grey,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    )),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
