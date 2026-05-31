import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dannisa_sweet_pos/features/auth/presentation/providers/auth_provider.dart';

// Tab pages
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/dashboard_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/transaksi_tab_page.dart';
import 'package:dannisa_sweet_pos/features/admin/presentation/pages/kelola_tab_page.dart';
//import 'package:dannisa_sweet_pos/features/admin/presentation/pages/profil_page.dart';

const _primary = Color(0xFFE91E8C);
const _primaryDark = Color(0xFFC2185B);

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _currentIndex = 0;

  // Pakai IndexedStack supaya state tiap tab tidak hilang saat pindah tab
  final List<Widget> _pages = const [
    DashboardPage(),
    TransaksiTabPage(),
    KelolaTabPage(),
    //ProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
                index: 0,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Transaksi',
                index: 1,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.manage_search_outlined,
                activeIcon: Icons.manage_search,
                label: 'Kelola',
                index: 2,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 3,
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav Item ───────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  bool get _isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isActive ? _primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isActive ? activeIcon : icon,
              color: _isActive ? _primary : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    _isActive ? FontWeight.w700 : FontWeight.normal,
                color: _isActive ? _primary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}