class MonthYearUtils {
  static bool isPastMonth(int month, int year) {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    // Se l'anno è minore, è sicuramente un mese passato
    if (year < currentYear) return true;

    // Se è lo stesso anno, ma un mese precedente, è passato
    if (year == currentYear && month < currentMonth) return true;

    return false;
  }

  /// Restituisce il mese successivo a quello fornito.
  /// Se è Dicembre (12), ritorna Gennaio (1).
  static int getNextMonth(int month) {
    return (month % 12) + 1;
  }

  /// Restituisce l'anno corretto considerando il mese successivo.
  /// Se il mese fornito è Dicembre, incrementa l'anno di 1.
  static int getNextYear(int month, int year) {
    return (month == 12) ? (year + 1) : year;
  }

  static bool areMonthYearEquals(DateTime dt1, DateTime dt2) {
    if (dt1.month != dt2.month) return false;
    if (dt1.year != dt2.year) return false;
    return true;
  }

  static bool areMonthYearEqualsToday(DateTime dt) {
    return areMonthYearEquals(dt, DateTime.now());
  }
}