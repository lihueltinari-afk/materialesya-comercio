import 'package:intl/intl.dart';

/// Utilidades de fechas para MaterialesYa.
///
/// Las fechas llegan del backend como ISO 8601 UTC.
/// Dart convierte automáticamente a hora local con .toLocal().
/// Mendoza, Argentina es UTC-3 (sin horario de verano).
class FechaUtils {
  static final DateFormat _fechaHora = DateFormat('dd/MM/yyyy HH:mm', 'es');
  static final DateFormat _soloFecha = DateFormat('dd/MM/yyyy', 'es');
  static final DateFormat _soloHora  = DateFormat('HH:mm', 'es');
  static final DateFormat _relativo  = DateFormat('dd MMM, HH:mm', 'es');

  /// Formatea una fecha UTC a "dd/MM/yyyy HH:mm" en hora local argentina.
  static String fechaHora(DateTime? fecha) {
    if (fecha == null) return '';
    return _fechaHora.format(fecha.toLocal());
  }

  /// Formatea a "dd/MM/yyyy".
  static String soloFecha(DateTime? fecha) {
    if (fecha == null) return '';
    return _soloFecha.format(fecha.toLocal());
  }

  /// Formatea a "HH:mm".
  static String soloHora(DateTime? fecha) {
    if (fecha == null) return '';
    return _soloHora.format(fecha.toLocal());
  }

  /// Parsea un string ISO 8601 del backend y convierte a hora local.
  static DateTime? parsear(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso).toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Devuelve cuántos segundos faltan hasta [fecha] desde ahora.
  /// Negativo si ya pasó.
  static int segundosHasta(DateTime? fecha) {
    if (fecha == null) return 0;
    return fecha.toLocal().difference(DateTime.now()).inSeconds;
  }

  /// Formatea duración restante como "4:35" (mm:ss) para countdowns.
  static String countdown(int segundosRestantes) {
    if (segundosRestantes <= 0) return '0:00';
    final m = (segundosRestantes ~/ 60).toString();
    final s = (segundosRestantes % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Texto relativo: "hace 5 min", "ayer", etc.
  static String relativo(DateTime? fecha) {
    if (fecha == null) return '';
    final local = fecha.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inSeconds < 60) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return _relativo.format(local);
  }
}
