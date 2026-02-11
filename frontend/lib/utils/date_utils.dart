class AppDateUtils {
  /// Converts ISO date (YYYY-MM-DD) to display format (DD/MM/YYYY)
  static String? isoToDisplay(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    try {
      final parts = isoDate.split('-');
      if (parts.length != 3) return isoDate;
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (e) {
      return isoDate;
    }
  }

  /// Converts display format (DD/MM/YYYY) to ISO date (YYYY-MM-DD)
  static String? displayToIso(String? displayDate) {
    if (displayDate == null || displayDate.isEmpty) return null;
    try {
      final parts = displayDate.split('/');
      if (parts.length != 3) return displayDate;
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    } catch (e) {
      return displayDate;
    }
  }

  /// Formats DateTime object to DD/MM/YYYY
  static String formatDateTime(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
