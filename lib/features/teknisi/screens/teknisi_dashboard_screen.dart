import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/teknisi_provider.dart';
import 'tickets/teknisi_ticket_list_screen.dart';
import 'psb/psb_list_screen.dart';
import 'riwayat/riwayat_tugas_screen.dart';
import 'infrastruktur/infrastruktur_map_screen.dart';

class TeknisiDashboardScreen extends StatefulWidget {
  const TeknisiDashboardScreen({super.key});

  @override
  State<TeknisiDashboardScreen> createState() => _TeknisiDashboardScreenState();
}

class _TeknisiDashboardScreenState extends State<TeknisiDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<TeknisiProvider>();
      prov.loadTickets();
      prov.loadPsbTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Image.asset('assets/icon/app_landscape.png', height: 32),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.primary,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifikasi segera hadir')),
            ),
          ),
        ],
      ),
      body: Consumer<TeknisiProvider>(
        builder: (context, prov, _) {
          final activeTickets = prov.tickets
              .where(
                (t) =>
                    t.status.toLowerCase() == 'open' ||
                    t.status.toLowerCase() == 'in_progress',
              )
              .length;
          final activePsb = prov.psbTickets
              .where(
                (t) =>
                    t.status.toLowerCase() == 'open' ||
                    t.status.toLowerCase() == 'in_progress',
              )
              .length;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await prov.loadTickets();
              await prov.loadPsbTickets();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Hero Card ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromARGB(255, 251, 73, 14),
                        AppColors.primary,
                        AppColors.primaryLight,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.30),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TEKNISI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selamat Datang, $firstName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Stat Cards ───────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      label: 'Tiket PSB',
                      count: activePsb,
                      icon: Icons.build_circle_outlined,
                      color: Colors.blue,
                      iconColor: Colors.white,
                      bg: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Tiket TRB',
                      count: activeTickets,
                      icon: Icons.warning_amber_outlined,
                      color: Colors.red,
                      iconColor: Colors.white,
                      bg: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Menu',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 12),
                _buildMenuGrid(context),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      _MenuItem(
        iconData: Icons.build_circle_outlined,
        iconBg: AppColors.primary.withValues(alpha: 0.12),
        iconColor: AppColors.primary,
        label: 'Tiket PSB',
        subtitle: 'Tugas Pasang Baru',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PsbListScreen()),
        ),
      ),
      _MenuItem(
        iconData: Icons.warning_amber_outlined,
        iconBg: AppColors.primary.withValues(alpha: 0.12),
        iconColor: AppColors.primary,
        label: 'Tiket TRB',
        subtitle: 'Tugas TRB & penanganan masalah',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeknisiTicketListScreen()),
        ),
      ),
      _MenuItem(
        iconData: Icons.history_outlined,
        iconBg: AppColors.primary.withValues(alpha: 0.12),
        iconColor: AppColors.primary,
        label: 'Riwayat Tugas',
        subtitle: 'Daftar tiket yang telah dikerjakan',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RiwayatTugasScreen()),
        ),
      ),
      _MenuItem(
        iconData: Icons.cable_outlined,
        iconBg: AppColors.primary.withValues(alpha: 0.12),
        iconColor: AppColors.primary,
        label: 'Data Infrastruktur',
        subtitle: 'ODP, OTB & jaringan',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InfrastrukturMapScreen()),
        ),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: menus.map((m) => _MenuCard(item: m)).toList(),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Menu card data ──────────────────────────────────────────────────────────

class _MenuItem {
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _MenuCard extends StatelessWidget {
  final _MenuItem item;

  const _MenuCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.iconData, color: item.iconColor, size: 30),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
