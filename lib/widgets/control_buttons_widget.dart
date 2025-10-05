import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  final VoidCallback onClearMarkers;
  final VoidCallback onCenterMap;
  final VoidCallback? onShowMarkersList;
  final VoidCallback? onRefreshData;

  const ControlButtonsWidget({
    super.key,
    required this.onClearMarkers,
    required this.onCenterMap,
    this.onShowMarkersList,
    this.onRefreshData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Кнопки управления
        Row(
          children: [
            if (onRefreshData != null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRefreshData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onClearMarkers,
                icon: const Icon(Icons.clear),
                label: const Text('Очистить'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onCenterMap,
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Центрировать'),
              ),
            ),
            if (onShowMarkersList != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onShowMarkersList,
                  icon: const Icon(Icons.list),
                  label: const Text('Список объектов'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}