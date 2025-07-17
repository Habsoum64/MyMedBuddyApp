import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medication_provider.dart';
import '../models/medication.dart';
import 'custom_cards.dart';

class OptimizedMedicationList extends StatelessWidget {
  final Function(Medication) onEdit;
  final Function(Medication) onDelete;
  final VoidCallback onRetry;

  const OptimizedMedicationList({
    super.key,
    required this.onEdit,
    required this.onDelete,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MedicationProvider, MedicationListData>(
      selector: (_, provider) => MedicationListData(
        medications: provider.medications,
        isLoading: provider.isLoading,
        error: provider.error,
      ),
      builder: (context, data, child) {
        if (data.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (data.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading medications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  data.error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (data.medications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No medications found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Add your first medication to get started',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.medications.length,
          itemBuilder: (context, index) {
            final medication = data.medications[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MedicationCard(
                name: medication.name,
                dosage: medication.dosage,
                frequency: medication.frequency,
                nextDose: _getNextDoseTime(medication),
                onEdit: () => onEdit(medication),
                onTap: () => onEdit(medication),
              ),
            );
          },
        );
      },
    );
  }

  String _getNextDoseTime(Medication medication) {
    // Simple logic - in real app this would be more complex
    if (medication.times.isEmpty) {
      return 'No schedule';
    }
    
    final now = DateTime.now();
    final firstTimeStr = medication.times.first;
    final timeParts = firstTimeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final nextDose = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (nextDose.isBefore(now)) {
      // If time has passed, show next day
      return 'Tomorrow at $firstTimeStr';
    } else {
      return 'Today at $firstTimeStr';
    }
  }
}

class MedicationListData {
  final List<Medication> medications;
  final bool isLoading;
  final String? error;

  MedicationListData({
    required this.medications,
    required this.isLoading,
    this.error,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationListData &&
          runtimeType == other.runtimeType &&
          medications.length == other.medications.length &&
          isLoading == other.isLoading &&
          error == other.error;

  @override
  int get hashCode => medications.length.hashCode ^ isLoading.hashCode ^ error.hashCode;
}
