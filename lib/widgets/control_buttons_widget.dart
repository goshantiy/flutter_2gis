import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onLoadFromFile;
  final VoidCallback onLoadFromUrl;
  final VoidCallback onLoadSample;
  final VoidCallback onShowEvents;
  final VoidCallback onClearMarkers;
  final VoidCallback onCenterMap;

  const ControlButtonsWidget({
    super.key,
    required this.isLoading,
    required this.onLoadFromFile,
    required this.onLoadFromUrl,
    required this.onLoadSample,
    required this.onShowEvents,
    required this.onClearMarkers,
    required this.onCenterMap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Кнопки загрузки
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onLoadFromFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Загрузить файл'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onLoadFromUrl,
                icon: const Icon(Icons.link),
                label: const Text('Загрузить по URL'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'JSON данные событий:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton.icon(
              onPressed: onLoadSample,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Пример'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Кнопки управления
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onShowEvents,
                icon: const Icon(Icons.add_location),
                label: const Text('Показать события'),
              ),
            ),
            const SizedBox(width: 8),
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
        ElevatedButton.icon(
          onPressed: onCenterMap,
          icon: const Icon(Icons.center_focus_strong),
          label: const Text('Центрировать карту'),
        ),
      ],
    );
  }
}