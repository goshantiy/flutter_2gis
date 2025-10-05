import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/marker_model.dart';

class MarkerCardWidget extends StatelessWidget {
  final MarkerModel marker;
  final VoidCallback onClose;
  final ScrollController scrollController;

  const MarkerCardWidget({
    super.key,
    required this.marker,
    required this.onClose,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          // Фиксированная шапка
          SliverToBoxAdapter(
            child: _buildFixedHeader(),
          ),
          
          // Прокручиваемый контент
          SliverToBoxAdapter(
            child: _buildScrollableContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeader() {
    return Column(
      children: [
        // Drag handle
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header with title and close button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marker.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          marker.isLine ? Icons.block : Icons.event,
                          size: 16,
                          color: marker.isLine ? Colors.red : Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          marker.isLine ? 'Перекрытие движения' : 'Мероприятие',
                          style: TextStyle(
                            fontSize: 14,
                            color: marker.isLine ? Colors.red[700] : Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: Colors.grey),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),

        // Rating и время (если есть дата)
        if (marker.hasDate)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                // Звезды рейтинга
                Row(
                  children: List.generate(5, (index) => Icon(
                    Icons.star_border,
                    size: 16,
                    color: Colors.grey[400],
                  )),
                ),
                const SizedBox(width: 8),
                Text(
                  'нет оценок',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '1 ч 4 мин',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

        // Табы
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              _buildTab('Обзор', true),
              const SizedBox(width: 24),
              _buildTab('Отзывы', false),
              const SizedBox(width: 24),
              _buildTab('Фото', false),
            ],
          ),
        ),
        
        // Разделитель
        Container(
          height: 1,
          color: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildScrollableContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции
          _buildSectionTitle(marker.isLine ? 'О перекрытии' : 'О мероприятии'),
          const SizedBox(height: 16),
          
          // Информация о продолжительности и датах
          if (marker.hasDate) ...[
            _buildDurationAndDatesRow(),
            const SizedBox(height: 20),
          ],

          // Предупреждение о перекрытии
          if (marker.isLine) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'На данном участке будет ограничено или полностью перекрыто движение транспорта',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Описание
          if (marker.description.isNotEmpty) ...[
            Text(
              marker.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Расписание мероприятия
          if (marker.hasDate) ...[
            _buildEventSchedule(),
            const SizedBox(height: 20),
          ],

          // Техническая информация
          _buildTechnicalInfo(),
          
          // Нижние кнопки действий
          const SizedBox(height: 20),
          _buildBottomActions(),
          
          // Дополнительный отступ для удобства прокрутки
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.directions_car,
              label: '1 ч 4 мин',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.bookmark_border,
              label: 'Избранное',
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.share,
              label: 'Поделиться',
              onTap: () => _shareMarker(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.black87 : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 24,
          color: isActive ? Colors.blue : Colors.transparent,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildDurationAndDatesRow() {
    return Row(
      children: [
        // Дни
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.schedule,
            color: Colors.orange[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Дни',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Text(
                '3',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Даты
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Colors.red[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Даты',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              marker.date,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventDay(
          number: 1,
          date: '22.08.2025 20:00-22:30',
          title: 'Первый день фестиваля. Вечернее представление - церемония торжественного открытия',
        ),
        const SizedBox(height: 12),
        _buildEventDay(
          number: 2,
          date: '23.08.2025 20:00-22:30',
          title: 'Второй день фестиваля. Вечернее представление',
        ),
        const SizedBox(height: 12),
        _buildEventDay(
          number: 3,
          date: '24.08.2025 20:00-22:30',
          title: 'Третий день фестиваля. Вечернее представление',
        ),
      ],
    );
  }

  Widget _buildEventDay({
    required int number,
    required String date,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Координаты',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Широта', marker.latitude.toStringAsFixed(6)),
          _buildInfoRow('Долгота', marker.longitude.toStringAsFixed(6)),
          if (marker.isLine && marker.pointsCount != null)
            _buildInfoRow('Точек в маршруте', marker.pointsCount.toString()),
          _buildInfoRow('Тип объекта', marker.isPoint ? 'Место проведения' : 'Перекрытие дороги'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _shareMarker() {
    final shareText = '''
🎯 ${marker.title}

📍 ${marker.isLine ? 'Перекрытие' : 'Мероприятие'}

${marker.description.isNotEmpty ? '📝 ${marker.description}\n' : ''}${marker.hasDate ? '📅 ${marker.date}\n' : ''}
🗺️ Координаты: ${marker.latitude.toStringAsFixed(6)}, ${marker.longitude.toStringAsFixed(6)}

Поделено из приложения 2GIS Maps & Events
    '''.trim();

    // Копируем в буфер обмена
    Clipboard.setData(ClipboardData(text: shareText));
  }
}