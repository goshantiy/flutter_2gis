class DateUtils {
  /// Форматировать диапазон дат
  static String formatDateRange(String? startDate, String? endDate) {
    if (startDate?.isNotEmpty == true && endDate?.isNotEmpty == true) {
      return '$startDate - $endDate';
    } else if (startDate?.isNotEmpty == true) {
      return startDate!;
    }
    return '';
  }
  
  /// Проверить, является ли строка валидной датой
  static bool isValidDate(String? date) {
    if (date == null || date.isEmpty) return false;
    
    // Простая проверка на формат DD.MM.YYYY или DD.MM.YYYY HH:MM
    final dateRegex = RegExp(r'^\d{2}\.\d{2}\.\d{4}(\s\d{2}:\d{2})?$');
    return dateRegex.hasMatch(date);
  }
  
  /// Извлечь дату из строки (убрать время если есть)
  static String extractDate(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return '';
    
    // Если есть время, берем только дату
    if (dateTime.contains(' ')) {
      return dateTime.split(' ')[0];
    }
    
    return dateTime;
  }
  
  /// Сравнить две даты (для сортировки)
  static int compareDates(String date1, String date2) {
    try {
      // Простое сравнение строк для формата DD.MM.YYYY
      final parts1 = date1.split('.');
      final parts2 = date2.split('.');
      
      if (parts1.length == 3 && parts2.length == 3) {
        // Сравниваем год, месяц, день
        final year1 = int.parse(parts1[2]);
        final year2 = int.parse(parts2[2]);
        if (year1 != year2) return year1.compareTo(year2);
        
        final month1 = int.parse(parts1[1]);
        final month2 = int.parse(parts2[1]);
        if (month1 != month2) return month1.compareTo(month2);
        
        final day1 = int.parse(parts1[0]);
        final day2 = int.parse(parts2[0]);
        return day1.compareTo(day2);
      }
    } catch (e) {
      // Если не удалось распарсить, используем строковое сравнение
    }
    
    return date1.compareTo(date2);
  }
}