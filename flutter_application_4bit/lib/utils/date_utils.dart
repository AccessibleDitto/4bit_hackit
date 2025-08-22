class CalendarDateUtils {
  static String getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  static String formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  // Month add helper: keeps day where possible, clamps to month end
  static DateTime addMonths(DateTime dt, int monthsToAdd) {
    final year = dt.year + ((dt.month - 1 + monthsToAdd) ~/ 12);
    final month = ((dt.month - 1 + monthsToAdd) % 12) + 1;
    final day = dt.day;
    final lastDay = _lastDayOfMonth(year, month);
    final clampedDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, clampedDay, dt.hour, dt.minute);
  }

  static int _lastDayOfMonth(int year, int month) {
    final beginningNextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    return beginningNextMonth.subtract(const Duration(days: 1)).day;
  }
}