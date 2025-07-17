import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/health_tip_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_cards.dart';
import '../models/medication_log.dart';
import 'health_tips_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh all data
        final medicationProvider = context.read<MedicationProvider>();
        final appointmentProvider = context.read<AppointmentProvider>();
        final healthTipProvider = context.read<HealthTipProvider>();
        
        await Future.wait([
          medicationProvider.refreshAllMedicationData(),
          appointmentProvider.refreshAppointments(),
          healthTipProvider.refreshHealthTips(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(context),
            const SizedBox(height: 20),
            
            // Quick stats
            _buildQuickStats(context),
            const SizedBox(height: 20),
            
            // Today's medications
            _buildTodaysMedications(context),
            const SizedBox(height: 20),
            
            // Upcoming appointments
            _buildUpcomingAppointments(context),
            const SizedBox(height: 20),
            
            // Featured health tips
            _buildFeaturedHealthTips(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 
        ? 'morning' 
        : now.hour < 17 
            ? 'afternoon' 
            : 'evening';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
            theme.primaryColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTimeIcon(now.hour),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good $timeOfDay!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stay on top of your health today',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(now),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTimeIcon(int hour) {
    if (hour < 12) {
      return Icons.wb_sunny;
    } else if (hour < 17) {
      return Icons.wb_sunny_outlined;
    } else {
      return Icons.nights_stay;
    }
  }

  Widget _buildQuickStats(BuildContext context) {
    // Split the Consumer3 into separate, more targeted consumers
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMedicationStats(context)),
            const SizedBox(width: 8),
            Expanded(child: _buildAppointmentStats(context)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildAdherenceStats(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationStats(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
        final todaysMeds = medicationProvider.getTodaysMedications();
        final takenCount = todaysMeds.where((log) => log.status == MedicationStatus.taken).length;
        final missedCount = todaysMeds.where((log) => log.status == MedicationStatus.missed).length;
        final lateCount = todaysMeds.where((log) => log.status == MedicationStatus.late).length;
        final pendingCount = todaysMeds.where((log) => log.status == MedicationStatus.pending).length;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medication,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Medications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$takenCount/${todaysMeds.length}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 24,
                ),
              ),
              Text(
                todaysMeds.isEmpty ? 'No medications' : 'Taken today',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusIndicator(context, 'T', takenCount, Colors.green),
                  _buildStatusIndicator(context, 'P', pendingCount, Colors.blue),
                  _buildStatusIndicator(context, 'L', lateCount, Colors.orange),
                  _buildStatusIndicator(context, 'M', missedCount, Colors.red),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppointmentStats(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final upcomingAppointments = appointmentProvider.upcomingAppointments;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Appointments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                upcomingAppointments.length.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontSize: 24,
                ),
              ),
              Text(
                upcomingAppointments.isEmpty
                    ? 'No appointments'
                    : upcomingAppointments.length == 1
                        ? 'Upcoming'
                        : 'Upcoming',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdherenceStats(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
        final adherenceRate = medicationProvider.todayAdherenceRate;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: adherenceRate >= 80 ? Colors.green : adherenceRate >= 60 ? Colors.orange : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Adherence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${adherenceRate.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: adherenceRate >= 80 ? Colors.green : adherenceRate >= 60 ? Colors.orange : Colors.red,
                  fontSize: 24,
                ),
              ),
              Text(
                adherenceRate >= 80 ? 'Excellent!' : adherenceRate >= 60 ? 'Good' : 'Needs improvement',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysMedications(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medicationProvider, child) {
        final upcomingMeds = medicationProvider.getUpcomingMedications();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.medication,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today\'s Medications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to medications tab
                    context.read<NavigationProvider>().setCurrentIndex(1);
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (upcomingMeds.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No pending medications for today',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...upcomingMeds.take(3).map((log) {
                return MedicationCard(
                  name: log.medicationName,
                  dosage: 'Next dose',
                  frequency: DateFormat('HH:mm').format(log.scheduledTime),
                  nextDose: _getTimeUntilDose(log.scheduledTime),
                  nextDoseStatus: log.status,
                  onTaken: () => _markMedicationTaken(context, log),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, appointmentProvider, child) {
        final upcomingAppointments = appointmentProvider.nextAppointments;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to appointments tab
                    context.read<NavigationProvider>().setCurrentIndex(2);
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (upcomingAppointments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event_available, size: 48, color: Colors.blue),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No upcoming appointments',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your schedule is clear for now',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...upcomingAppointments.take(2).map((appointment) {
                final isToday = _isToday(appointment.dateTime);
                
                return AppointmentCard(
                  title: appointment.title,
                  doctorName: appointment.doctorName,
                  location: appointment.location,
                  dateTime: appointment.dateTime,
                  type: appointment.type,
                  statusColor: isToday ? Colors.orange : Colors.blue,
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedHealthTips(BuildContext context) {
    return Consumer<HealthTipProvider>(
      builder: (context, healthTipProvider, child) {
        final featuredTips = healthTipProvider.featuredTips;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Featured Health Tips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to health tips tab
                    context.read<NavigationProvider>().setCurrentIndex(3);
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (featuredTips.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 48, color: Colors.amber),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No health tips available',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Check back later for health insights',
                            style: TextStyle(color: Colors.amber),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...featuredTips.take(2).map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HealthTipCard(
                  title: tip.title,
                  category: tip.category,
                  readingTime: tip.readingTime,
                  tags: tip.tags,
                  onTap: () => _showHealthTipDetail(context, tip.id),
                ),
              )),
          ],
        );
      },
    );
  }

  String _getTimeUntilDose(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);
    
    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return 'In ${difference.inMinutes}m';
    }
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  void _markMedicationTaken(BuildContext context, MedicationLog log) {
    final medicationProvider = context.read<MedicationProvider>();
    medicationProvider.logMedicationTaken(
      log.medicationId,
      log.medicationName,
      log.scheduledTime,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${log.medicationName} marked as taken'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showHealthTipDetail(BuildContext context, String tipId) {
    // Find the health tip by ID
    final healthTipProvider = context.read<HealthTipProvider>();
    final healthTip = healthTipProvider.healthTips.firstWhere(
      (tip) => tip.id == tipId,
      orElse: () => healthTipProvider.healthTips.first,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HealthTipDetailScreen(healthTip: healthTip),
      ),
    );
  }

}
