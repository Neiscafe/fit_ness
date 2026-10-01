import 'package:intl/intl.dart';

final _kgFormat = NumberFormat('0.##', 'pt_BR');

/// 42.5 -> "42,5"; 40.0 -> "40".
String fmtKg(double v) => _kgFormat.format(v);

String fmtDate(DateTime d) => DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(d);

const _from = 'áàâãäéèêëíìîïóòôõöúùûüç';
const _to = 'aaaaaeeeeiiiiooooouuuuc';

/// Minúsculas e sem acentos, para buscas.
String norm(String s) {
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = _from.indexOf(ch);
    b.write(i < 0 ? ch : _to[i]);
  }
  return b.toString().trim();
}
