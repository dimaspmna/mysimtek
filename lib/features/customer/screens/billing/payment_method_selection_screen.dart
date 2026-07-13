import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../providers/billing_provider.dart';
import 'billing_screen.dart';
import 'briva_screen.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  const PaymentMethodSelectionScreen({super.key});

  @override
  State<PaymentMethodSelectionScreen> createState() =>
      _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState
    extends State<PaymentMethodSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillingProvider>().loadActiveBilling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerPayment =
        context.watch<BillingProvider>().activeBilling?.customerPayment;

    final bool midtransDisabled = customerPayment?.isBriva ?? false;
    final bool brivaDisabled = customerPayment?.isMidtrans ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Pilih Metode Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          const Text(
            'Pilih metode pembayaran yang tersedia',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          _PaymentMethodCard(
            imageAsset: 'assets/icon/payment-method/icon_midtrans.png',
            title: 'Midtrans',
            subtitle: 'Bayar via Virtual Account, GoPay, QRIS, dan lainnya',
            disabled: midtransDisabled,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillingScreen()),
              );
            },
            onDisabledTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hanya bisa dilakukan melalui BRIVA saja'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _PaymentMethodCard(
            imageAsset: 'assets/icon/payment-method/icon_briva.png',
            title: 'BRIVA',
            subtitle: 'Bayar melalui BRI Virtual Account (BRIVA)',
            disabled: brivaDisabled,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrivaScreen()),
              );
            },
            onDisabledTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hanya bisa pembayaran melalui Midtrans saja'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool disabled;
  final VoidCallback? onDisabledTap;

  const _PaymentMethodCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? onDisabledTap : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
