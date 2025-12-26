import 'package:flutter/material.dart';
import 'package:personal_finance/utils/theme.dart';

class ServiceConsultationPage extends StatefulWidget {
  const ServiceConsultationPage({super.key});

  @override
  State<ServiceConsultationPage> createState() =>
      _ServiceConsultationPageState();
}

class _ServiceConsultationPageState extends State<ServiceConsultationPage> {
  // Mock data for services
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'Energía Eléctrica',
      'provider': 'CFE',
      'status': 'Activo',
      'amount': 450.00,
      'dueDate': '25 Dic 2025',
      'icon': Icons.lightbulb_outline,
      'color': Colors.amber,
    },
    {
      'name': 'Internet',
      'provider': 'Telmex',
      'status': 'Pagado',
      'amount': 389.00,
      'dueDate': '10 Ene 2026',
      'icon': Icons.wifi,
      'color': Colors.blue,
    },
    {
      'name': 'Agua Potable',
      'provider': 'Japami',
      'status': 'Pendiente',
      'amount': 210.50,
      'dueDate': '15 Ene 2026',
      'icon': Icons.water_drop_outlined,
      'color': Colors.cyan,
    },
    {
      'name': 'Streaming',
      'provider': 'Netflix',
      'status': 'Activo',
      'amount': 199.00,
      'dueDate': '05 Ene 2026',
      'icon': Icons.movie_outlined,
      'color': Colors.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final FinanceColors colors = Theme.of(context).extension<FinanceColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by parent or theme
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? [const Color(0xFF0F111A), const Color(0xFF1E2130)]
                    : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
          ),
        ),
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withOpacity(0.15),
                  // blur handled by specialized widget or just opacity in this simple version
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Mis Servicios',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Consulta y gestiona tus pagos',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Service Status Overview Card
                    _buildStatusCard(context, colors),

                    const SizedBox(height: 24),
                    Text(
                      'Próximos Vencimientos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return _buildServiceItem(context, service, colors);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    Map<String, dynamic> service,
    FinanceColors colors,
  ) {
    final bool isPaid = service['status'] == 'Pagado';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.glassBackground, // Glass effect
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (service['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              service['icon'] as IconData,
              color: service['color'] as Color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  service['provider'] as String,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${service['amount']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              isPaid
                  ? const Row(
                    children: [
                      Icon(Icons.check, size: 14, color: Colors.green),
                      Text(
                        'Pagado',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    'Vence: ${service['dueDate']}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, FinanceColors colors) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Todo en orden',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Total a pagar este mes',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '\$1,248.50',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}
