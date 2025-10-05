import 'package:flutter/material.dart';

class ControlButtonsWidget extends StatelessWidget {
  const ControlButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Убираем все кнопки управления - оставляем только фильтры
    return const SizedBox.shrink();
  }
}