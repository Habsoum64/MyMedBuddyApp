import 'package:flutter/material.dart';
import '../models/medication_log.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final Color? backgroundColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Border? border;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.elevation,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget cardWidget = Card(
      elevation: elevation ?? 2,
      color: backgroundColor ?? theme.cardColor,
      margin: margin ?? const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
        side: border != null 
          ? BorderSide(
              color: border!.top.color,
              width: border!.top.width,
            )
          : BorderSide.none,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.0),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class MedicationCard extends StatelessWidget {
  final String name;
  final String dosage;
  final String frequency;
  final String nextDose;
  final bool isOverdue;
  final MedicationStatus? nextDoseStatus; // Add status for next dose
  final VoidCallback? onTap;
  final VoidCallback? onTaken;
  final VoidCallback? onEdit;

  const MedicationCard({
    super.key,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDose,
    this.isOverdue = false,
    this.nextDoseStatus,
    this.onTap,
    this.onTaken,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Get status-based styling
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();
    
    return CustomCard(
      onTap: onTap,
      border: _shouldShowBorder() 
        ? Border.all(color: statusColor, width: 2)
        : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medication,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _shouldHighlightText() ? statusColor : null,
                  ),
                ),
              ),
              // Status indicator
              if (nextDoseStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dosage: $dosage',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Frequency: $frequency',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Next: $nextDose',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _shouldHighlightText() ? statusColor : theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onTaken != null)
                ElevatedButton.icon(
                  onPressed: onTaken,
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Taken'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for status-based styling
  Color _getStatusColor() {
    if (nextDoseStatus == null) {
      return isOverdue ? Colors.red : Colors.blue;
    }
    
    switch (nextDoseStatus!) {
      case MedicationStatus.taken:
        return Colors.green;
      case MedicationStatus.missed:
        return Colors.red;
      case MedicationStatus.skipped:
        return Colors.orange;
      case MedicationStatus.late:
        return Colors.amber;
      case MedicationStatus.pending:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    if (nextDoseStatus == null) {
      return isOverdue ? Icons.warning : Icons.schedule;
    }
    
    switch (nextDoseStatus!) {
      case MedicationStatus.taken:
        return Icons.check_circle;
      case MedicationStatus.missed:
        return Icons.cancel;
      case MedicationStatus.skipped:
        return Icons.skip_next;
      case MedicationStatus.late:
        return Icons.access_time;
      case MedicationStatus.pending:
        return Icons.schedule;
    }
  }

  String _getStatusText() {
    if (nextDoseStatus == null) {
      return isOverdue ? 'OVERDUE' : 'PENDING';
    }
    
    return nextDoseStatus!.toString().split('.').last.toUpperCase();
  }

  bool _shouldShowBorder() {
    if (nextDoseStatus == null) {
      return isOverdue;
    }
    
    return nextDoseStatus == MedicationStatus.missed || 
           nextDoseStatus == MedicationStatus.late;
  }

  bool _shouldHighlightText() {
    if (nextDoseStatus == null) {
      return isOverdue;
    }
    
    return nextDoseStatus == MedicationStatus.missed || 
           nextDoseStatus == MedicationStatus.late;
  }
}

class AppointmentCard extends StatelessWidget {
  final String title;
  final String doctorName;
  final String location;
  final DateTime dateTime;
  final String type;
  final Color? statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const AppointmentCard({
    super.key,
    required this.title,
    required this.doctorName,
    required this.location,
    required this.dateTime,
    required this.type,
    this.statusColor,
    this.onTap,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: statusColor ?? theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person, 
                size: 16, 
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                doctorName,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on, 
                size: 16, 
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.teal.shade300.withOpacity(0.2)
                      : theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.teal.shade300
                        : theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: statusColor ?? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.teal.shade300
                      : theme.primaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HealthTipCard extends StatelessWidget {
  final String title;
  final String category;
  final int readingTime;
  final List<String> tags;
  final VoidCallback? onTap;

  const HealthTipCard({
    super.key,
    required this.title,
    required this.category,
    required this.readingTime,
    required this.tags,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CustomCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.teal.shade300
                    : theme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.teal.shade300.withOpacity(0.2)
                      : theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.teal.shade300
                        : theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.schedule, 
                size: 16, 
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                '${readingTime}min read',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: tags.take(3).map((tag) => Chip(
                label: Text(
                  tag,
                  style: theme.textTheme.bodySmall,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.primaryColor;
    
    return CustomCard(
      onTap: onTap,
      backgroundColor: cardColor.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: cardColor,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: cardColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
