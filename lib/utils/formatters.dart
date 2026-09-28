String formatDuration(Duration d) {
  if (d.isNegative || d == Duration.zero) return '00:00:00';
  final days = d.inDays;
  final hours = d.inHours.remainder(24);
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  String pad(int n) => n.toString().padLeft(2, '0');
  if (days > 0) {
    return '${days}d ${pad(hours)}:${pad(minutes)}:${pad(seconds)}';
  }
  return '${pad(hours)}:${pad(minutes)}:${pad(seconds)}';
}

String formatPrice(double value, String currency) {
  if (value <= 0) return '—';
  final symbol = currency == 'USD' ? r'$' : '€';
  final decimals = value >= 100 ? 0 : 2;
  return '$symbol${value.toStringAsFixed(decimals)}';
}
