class GraphUtils {

  static String formatThousandsTick(double value) {
    if (value >= 1000 || value <= -1000) {
      double k = value / 1000;
      // 1.0k invece di 1k se vuoi maggiore precisione
      return k % 1 == 0 ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    } else {
      return value.toInt().toString();
    }
  }
}