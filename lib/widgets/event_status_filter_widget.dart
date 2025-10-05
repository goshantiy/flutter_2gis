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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Фильтр по статусу:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: EventStatus.values.map((status) {
            return FilterChip(
              label: Text(
                status.displayName,
                style: const TextStyle(fontSize: 12),
              ),
              selected: selectedStatus == status,
              onSelected: (selected) {
                if (selected) onStatusSelected(status);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}