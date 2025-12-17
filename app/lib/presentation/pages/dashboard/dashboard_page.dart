import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/colors.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/floating_action_button.dart';
import '../../widgets/dashboard_chart_widget.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, Dr. Carvalho',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Resumo do seu dia: 14 de Maio',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.slateLight,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.electricBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.electricBlue),
                          ),
                          child: const Center(
                            child: Text(
                              'DC',
                              style: TextStyle(
                                color: AppColors.electricBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pacientes Hoje',
                            value: '18',
                            icon: Icons.people,
                            color: AppColors.electricBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Pendências',
                            value: '3',
                            icon: Icons.description,
                            color: AppColors.yellow400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Ganhos Estim.',
                            value: 'R\$ 4.2k',
                            icon: Icons.trending_up,
                            color: AppColors.mintGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Plantões',
                            value: '1',
                            icon: Icons.calendar_today,
                            color: AppColors.purple400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Chart Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate800.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up, color: AppColors.mintGreen, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Volume de Atendimento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DashboardChartWidget(
                            data: const [
                              {'name': 'Seg', 'total': 12},
                              {'name': 'Ter', 'total': 19},
                              {'name': 'Qua', 'total': 15},
                              {'name': 'Qui', 'total': 22},
                              {'name': 'Sex', 'total': 10},
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Next Patients
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.slate800.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.slate700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people, color: AppColors.electricBlue, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Próximos Pacientes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _PatientItem(
                            name: 'Ana Silva',
                            lastVisit: '2024-05-10',
                            nextAppointment: '14:30',
                          ),
                          const SizedBox(height: 12),
                          _PatientItem(
                            name: 'João Pereira',
                            lastVisit: '2024-04-22',
                            nextAppointment: '15:15',
                          ),
                          const SizedBox(height: 12),
                          _PatientItem(
                            name: 'Maria Santos',
                            lastVisit: '2024-05-12',
                            nextAppointment: '16:00',
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'Ver agenda completa',
                              style: TextStyle(color: AppColors.electricBlue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomNavBar(currentRoute: '/dashboard'),
          ],
        ),
      ),
      floatingActionButton: const RecordingFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateLight,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientItem extends StatelessWidget {
  final String name;
  final String lastVisit;
  final String nextAppointment;

  const _PatientItem({
    required this.name,
    required this.lastVisit,
    required this.nextAppointment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Última: $lastVisit',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slateLight,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.electricBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              nextAppointment,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

