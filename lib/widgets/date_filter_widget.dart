import 'package:flutter/material.dart';

class DateFilterWidget extends StatelessWidget {
  final Set<String> availableDates;
  final String? selectedDate;
  final Function(String?) onDateSelected;

  const DateFilterWidget({
    super.key,
    required this.availableDates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableDates.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Фильтр по дате:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Все'),
              selected: selectedDate == null,
              onSelected: (selected) {
                if (selected) onDateSelected(null);
              },
            ),
            ...availableDates.map((date) => FilterChip(
              label: Text(date),
              selected: selectedDate == date,
              onSelected: (selected) {
                onDateSelected(selected ? date : null);
              },
            )).toList(),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}