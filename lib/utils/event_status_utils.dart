import '../models/event_status.dart';

class EventStatusUtils {
  /// Определяет статус события по дате
  static EventStatus getEventStatus(String dateStr) {
    if (dateStr.isEmpty) {
      return EventStatus.current; // События без даты считаем текущими
    }

    try {
      final eventDate = _parseEventDate(dateStr);
      if (eventDate == null) {
        return EventStatus.current;
      }

      final now = DateTime.now();
      final difference = eventDate.difference(now);

      if (difference.inHours < -24) {
        // Событие прошло более суток назад - серый (будущий)
        return EventStatus.future; // Серый цвет для прошедших/будущих
      } else if (difference.inHours <= 24) {
        // Событие происходит сейчас или в ближайшие сутки - зеленый (идут сейчас)
        return EventStatus.current; // Зеленый цвет
      } else {
        // Событие скоро (в ближайшие дни) - синий (скоро)
        return EventStatus.soon; // Синий цвет
      }
    } catch (e) {
      return EventStatus.current; // Fallback
    }
  }

  /// Парсит дату события из строки
  static DateTime? _parseEventDate(String dateStr) {
    try {
      // Пробуем разные форматы дат
      if (dateStr.contains('.')) {
        // Формат DD.MM.YYYY или DD.MM.YYYY HH:mm
        final parts = dateStr.split(' ');
        final datePart = parts[0];
        final dateComponents = datePart.split('.');

        if (dateComponents.length >= 3) {
          final day = int.parse(dateComponents[0]);
          final month = int.parse(dateComponents[1]);
          final year = int.parse(dateComponents[2]);

          int hour = 12; // По умолчанию полдень
          int minute = 0;

          if (parts.length > 1 && parts[1].contains(':')) {
            final timeParts = parts[1].split(':');
            hour = int.parse(timeParts[0]);
            minute = int.parse(timeParts[1]);
          }

          return DateTime(year, month, day, hour, minute);
        }
      }

      // Пробуем стандартный ISO формат
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}