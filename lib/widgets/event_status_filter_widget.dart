import 'package:flutter/material.dart';
import '../models/event_status.dart';

class EventStatusFilterWidget extends StatelessWidget {
  final EventStatus selectedStatus;
  final Function(EventStatus) onStatusSelected;

  const EventStatusFilterWidget({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильтр по статусу:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: EventStatus.values.map((status) {
            return FilterChip(
              label: Text(status.displayName),
              selected: selectedStatus == status,
              onSelected: (selected) {
                if (selected) onStatusSelected(status);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}