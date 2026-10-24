import 'package:flutter/material.dart';
import '../pages/workers_page.dart';
import '../pages/attendance_page.dart';
import '../pages/payments_page.dart';
import '../pages/site_management_page.dart';
import '../pages/account_status_page.dart';
import '../services/auth_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, required this.role});

  final String role;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;
  late final List<_NavDestination> destinations = _buildDestinations();

  List<_NavDestination> _buildDestinations() {
    if (widget.role == 'worker') {
      return [
        _NavDestination(
          'Home',
          const Icon(Icons.dashboard_rounded),
          HomePage(role: widget.role, onNavigate: navigateTo),
        ),
        _NavDestination(
          'Profile',
          const Icon(Icons.person_outline),
          const AccountStatusPage(
            title: 'Worker Profile',
            message:
                'Your personal profile and attendance view will be available here.',
          ),
        ),
      ];
    }
    final items = <_NavDestination>[
      _NavDestination(
        'Home',
        const Icon(Icons.dashboard_rounded),
        HomePage(role: widget.role, onNavigate: navigateTo),
      ),
      _NavDestination(
        'Workers',
        const Icon(Icons.groups_rounded),
        const WorkersPage(),
      ),
      _NavDestination(
        'Attendance',
        const Icon(Icons.calendar_month),
        const AttendancePage(),
      ),
      _NavDestination(
        'Profile',
        const Icon(Icons.person_outline),
        const _ProfilePage(),
      ),
      _NavDestination(
        'Payments',
        const Icon(Icons.payments_outlined),
        const PaymentsPage(),
      ),
    ];
    if (widget.role == 'owner') {
      items.add(
        _NavDestination(
          'Sites',
          const Icon(Icons.location_on_outlined),
          const SiteManagementPage(),
        ),
      );
    }
    return items;
  }

  void navigateTo(int index) {
    if (index < 0 || index >= destinations.length) return;
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: destinations.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF11182B),
        selectedItemColor: const Color(0xFFA78BFA),
        unselectedItemColor: Colors.grey,
        onTap: navigateTo,
        items: destinations
            .map(
              (item) =>
                  BottomNavigationBarItem(icon: item.icon, label: item.label),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination(this.label, this.icon, this.page);
  final String label;
  final Icon icon;
  final Widget page;
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: Color(0xFFA78BFA),
          ),
          const SizedBox(height: 12),
          const Text('WorkMate account'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    ),
  );
}

// HOME PAGE

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final String role;

  const HomePage({super.key, required this.role, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WorkMate',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${role[0].toUpperCase()}${role.substring(1)} 👋',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Here is your workforce overview.',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),

              // Total workers
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.groups_rounded, size: 32),
                    SizedBox(height: 16),
                    Text('Total Workers'),
                    SizedBox(height: 8),
                    Text(
                      '0',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Your workforce at a glance'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Present',
                      '0',
                      Icons.check_circle_outline,
                      const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Absent',
                      '0',
                      Icons.cancel_outlined,
                      const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      'Payments',
                      '₹0',
                      Icons.payments_outlined,
                      const Color(0xFFA78BFA),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      'Half-day',
                      '0',
                      Icons.access_time_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (role != 'worker') ...[
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        Icons.person_add_alt_1,
                        'Add Worker',
                        () => onNavigate(1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        Icons.calendar_month,
                        'Attendance',
                        () => onNavigate(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _actionCard(
                        Icons.account_balance_wallet_outlined,
                        'Payments',
                        () => onNavigate(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _actionCard(
                        Icons.bar_chart_rounded,
                        'Reports',
                        () => _showComingSoon(context, 'Reports'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String pageName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$pageName page will be added later.')),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151D32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF151D32),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFA78BFA), size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// PLACEHOLDER PAGES

class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderPage({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: const Color(0xFFA78BFA)),
            const SizedBox(height: 16),
            Text(
              '$title page coming soon',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
