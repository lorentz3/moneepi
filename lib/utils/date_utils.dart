import 'package:intl/intl.dart';

class MyDateUtils {
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

  static bool isFutureMonth(int month, int year) {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;
    if (year > currentYear) return true;
    if (year == currentYear && month > currentMonth) return true;
    return false;
  }

  /// true if year1/month1 is before year2/month2
  static bool isBeforeOrEqual(int month1, int year1, int month2, int year2) {
    if (year1 < year2) return true;
    if (year1 == year2 && month1 <= month2) return true;
    return false;
  }

  /// Restituisce il mese successivo a quello fornito.
  /// Se è Dicembre (12), ritorna Gennaio (1).
  static int getNextMonth(int month) {
    return (month % 12) + 1;
  }
  
  /// Restituisce il mese precedente a quello fornito.
  /// Se è Dicembre (12), ritorna Gennaio (1).
  static int getPreviousMonth(int month) {
    if (month == 1) return 12;
    return month - 1;
  }

  /// Restituisce l'anno corretto considerando il mese successivo.
  /// Se il mese fornito è Dicembre, incrementa l'anno di 1.
  static int getNextYear(int month, int year) {
    return (month == 12) ? (year + 1) : year;
  }

  /// Restituisce l'anno corretto considerando il mese precedente.
  /// Se il mese fornito è Gennaio, decrementa l'anno di 1.
  static int getPreviousYear(int month, int year) {
    return (month == 1) ? (year - 1) : year;
  }

  static bool areMonthYearEquals(DateTime dt1, DateTime dt2) {
    if (dt1.month != dt2.month) return false;
    if (dt1.year != dt2.year) return false;
    return true;
  }

  static bool areMonthYearEqualsToday(DateTime dt) {
    return areMonthYearEquals(dt, DateTime.now());
  }

  static String? formatDate(DateTime? dt) {
    if (dt == null) return null;
    return DateFormat('dd MMM yyyy').format(dt);
  }
}