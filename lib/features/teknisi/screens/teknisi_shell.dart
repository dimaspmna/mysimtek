import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'teknisi_dashboard_screen.dart';
import 'teknisi_profile_screen.dart';
import 'tickets/teknisi_ticket_list_screen.dart';
import 'psb/psb_list_screen.dart';

class TeknisiShell extends StatefulWidget {
  const TeknisiShell({super.key});

  @override
  State<TeknisiShell> createState() => _TeknisiShellState();
}

class _TeknisiShellState extends State<TeknisiShell> {
  int _index = 0;

  final _screens = const [
    TeknisiDashboardScreen(),
    PsbListScreen(),
    TeknisiTicketListScreen(),
    TeknisiProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            activeIcon: Icon(Icons.build_circle),
            label: 'Tiket PSB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_sharp),
            label: 'Tiket TRB',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
