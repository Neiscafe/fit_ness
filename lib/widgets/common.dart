import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import '../core/format.dart';
import '../core/stats.dart';
import '../core/theme.dart';
import '../data/database.dart';
import '../data/repository.dart';

/// Stylized 90's Loch Ness Monster icon (The meaning behind Fit NESS)
class NessieIcon extends StatelessWidget {
  const NessieIcon({super.key, this.size = 24, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NessiePainter(color: color ?? Colors.white),
    );
  }
}

class _NessiePainter extends CustomPainter {
  _NessiePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Water waves at bottom
    final wavePath = Path();
    wavePath.moveTo(w * 0.05, h * 0.82);
    wavePath.quadraticBezierTo(w * 0.28, h * 0.72, w * 0.50, h * 0.82);
    wavePath.quadraticBezierTo(w * 0.72, h * 0.92, w * 0.95, h * 0.82);
    canvas.drawPath(wavePath, strokePaint);

    // 2. Hump in water (left side)
    final humpPath = Path();
    humpPath.moveTo(w * 0.16, h * 0.80);
    humpPath.quadraticBezierTo(w * 0.28, h * 0.48, w * 0.42, h * 0.80);
    canvas.drawPath(humpPath, strokePaint);

    // 3. Graceful Neck & Head rising from right side
    final neckPath = Path();
    neckPath.moveTo(w * 0.56, h * 0.80);
    neckPath.cubicTo(
      w * 0.62, h * 0.48,
      w * 0.82, h * 0.38,
      w * 0.72, h * 0.16,
    );
    // Head snout turning left
    neckPath.quadraticBezierTo(w * 0.58, h * 0.12, w * 0.46, h * 0.22);
    canvas.drawPath(neckPath, strokePaint);

    // Eye dot
    canvas.drawCircle(Offset(w * 0.62, h * 0.19), w * 0.045, fillPaint);

    // 90s Sweatband across head (cyan accent)
    final sweatbandPaint = Paint()
      ..color = kRetroNeonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.58, h * 0.16),
      Offset(w * 0.72, h * 0.20),
      sweatbandPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _NessiePainter oldDelegate) => oldDelegate.color != color;
}

Future<void> exportarIconeParaPNG(Color color) async {
  // O tamanho ideal base para ícones nas lojas é 1024x1024
  const size = Size(1024, 1024);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final painter = _NessiePainter(color: color);
  painter.paint(canvas, size);

  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());

  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // Salva no dispositivo (ex: no diretório de documentos)
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/meu_icone_gerado.png');
  await file.writeAsBytes(pngBytes);

  print('Ícone salvo em: ${file.path}');
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const NessieIcon(size: 22, color: kRetroHotPink),
          const SizedBox(width: 8),
          Expanded(child: Text(title.toUpperCase())),
        ],
      ),
      content: Text(message),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('VOLTAR'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: kRetroHotPink,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel.toUpperCase()),
        ),
      ],
    ),
  );
  return r ?? false;
}

void snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

/// Variação com seta: verde/amarelo se subiu, vermelho se caiu, cinza se igual.
class Delta extends StatelessWidget {
  const Delta(this.value, this.unit, {super.key});
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.chakraPetch(
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    if (value.abs() < 0.001) {
      final c = Theme.of(context).hintColor;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.remove, size: 12, color: c),
          const SizedBox(width: 2),
          Text('0 $unit', style: style.copyWith(color: c)),
        ]),
      );
    }
    final up = value > 0;
    final color = up ? upColor(context) : downColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          '${up ? '+' : '-'}${fmtKg(value.abs())} $unit',
          style: style.copyWith(color: color),
        ),
      ]),
    );
  }
}

/// Variação de peso e repetições de uma série em relação à série de referência.
class SetDeltas extends StatelessWidget {
  const SetDeltas(this.cur, this.prev, {super.key});
  final SetLog cur;
  final SetLog? prev;

  @override
  Widget build(BuildContext context) {
    final p = prev;
    if (p == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).hintColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'NOVO',
          style: GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: kRetroNeonCyan,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Wrap(spacing: 6, children: [
      Delta(cur.weightKg - p.weightKg, 'kg'),
      Delta((cur.reps - p.reps).toDouble(), 'rep'),
    ]);
  }
}

class CountStepper extends StatelessWidget {
  const CountStepper({super.key, required this.value, required this.onChanged, this.min = 1});
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonBg = isDark ? const Color(0xFF2E1752) : const Color(0xFFEADBEE);
    final buttonFg = isDark ? kRetroNeonCyan : kRetroHotPink;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: buttonFg.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
          onTap: value > min ? () => onChanged(value - 1) : null,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
            ),
            child: Icon(Icons.remove, size: 18, color: value > min ? buttonFg : Colors.grey),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        InkWell(
          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
          onTap: () => onChanged(value + 1),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
            ),
            child: Icon(Icons.add, size: 18, color: buttonFg),
          ),
        ),
      ]),
    );
  }
}

/// "Peito · 6" para cada músculo trabalhado na sessão.
class VolumeChips extends StatelessWidget {
  const VolumeChips(this.session, {super.key});
  final SessionFull session;

  @override
  Widget build(BuildContext context) {
    final vol = volumeByMuscle(session);
    if (vol.isEmpty) return const Text('Nenhuma série registrada.');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(spacing: 8, runSpacing: 6, children: [
      for (final e in vol)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C134E) : const Color(0xFFF3E4F8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? kRetroNeonCyan.withValues(alpha: 0.6) : kRetroHotPink.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.key.toUpperCase(),
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? kRetroElectricYellow : kRetroHotPink,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: kRetroHotPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${e.value}',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}
