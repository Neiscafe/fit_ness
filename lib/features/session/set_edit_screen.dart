import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Adiciona uma série nova ou edita uma existente (quando [editing] não é nulo).
class SetEditScreen extends ConsumerStatefulWidget {
  const SetEditScreen({super.key, required this.item, required this.setNumber, this.editing});
  final SessionItem item;
  final int setNumber;
  final SetLog? editing;

  @override
  ConsumerState<SetEditScreen> createState() => _SetEditScreenState();
}

class _SetEditScreenState extends ConsumerState<SetEditScreen> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    // Sugestão inicial: a própria série (edição) > mesma série da última vez >
    // série anterior desta sessão > última série da última vez.
    final seed = widget.editing ??
        setByNumber(it.prev, widget.setNumber) ??
        (it.sets.isNotEmpty ? it.sets.last : null) ??
        (it.prev.isNotEmpty ? it.prev.last : null);
    _weight = TextEditingController(text: seed == null ? '' : fmtKg(seed.weightKg));
    _reps = TextEditingController(text: seed == null ? '' : '${seed.reps}');
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final w = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final r = int.tryParse(_reps.text.trim());
    if (w == null || w < 0 || r == null || r <= 0) {
      snack(context, 'Informe o peso em kg e um número de repetições maior que zero.');
      return;
    }
    final repo = ref.read(repoProvider);
    final editing = widget.editing;
    if (editing == null) {
      await repo.addSet(widget.item.se.id, w, r);
    } else {
      await repo.updateSet(editing.id, w, r);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final editing = widget.editing;
    if (editing == null) return;
    final ok = await confirm(
      context,
      title: 'Excluir série?',
      message: 'As séries seguintes serão renumeradas.',
      confirmLabel: 'Excluir',
    );
    if (!ok || !mounted) return;
    await ref.read(repoProvider).deleteSet(editing);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final it = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: Text(it.exercise.name.toUpperCase()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF23103D) : const Color(0xFFF6E8F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? kRetroNeonCyan : kRetroHotPink,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SÉRIE ${widget.setNumber} DE ${it.se.targetSets}',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? kRetroElectricYellow : kRetroHotPink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  it.prev.isEmpty
                      ? 'Sem registro anterior'
                      : 'ÚLTIMA VEZ: ${it.prev.map((s) => '${fmtKg(s.weightKg)}×${s.reps}').join('  |  ')}',
                  style: GoogleFonts.chakraPetch(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _NumberField(
            controller: _weight,
            label: 'PESO DA SÉRIE',
            suffix: 'kg',
            step: 2.5,
            decimal: true,
          ),
          const SizedBox(height: 20),
          _NumberField(
            controller: _reps,
            label: 'REPETIÇÕES',
            suffix: 'rep',
            step: 1,
            decimal: false,
          ),
          const SizedBox(height: 36),
          FilledButton(
            onPressed: _save,
            child: const Text('SALVAR SÉRIE'),
          ),
          if (widget.editing != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kRetroNeonRed,
                side: const BorderSide(color: kRetroNeonRed, width: 1.5),
              ),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text('EXCLUIR SÉRIE'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.step,
    required this.decimal,
  });
  final TextEditingController controller;
  final String label;
  final String suffix;
  final double step;
  final bool decimal;

  void _bump(double delta) {
    final cur = double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;
    final next = (cur + delta).clamp(0, 100000).toDouble();
    controller.text = decimal ? fmtKg(next) : next.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnBg = isDark ? const Color(0xFF33175A) : const Color(0xFFEADBEE);
    final btnFg = isDark ? kRetroNeonCyan : kRetroHotPink;

    return Row(children: [
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _bump(-step),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: btnFg.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(Icons.remove, size: 24, color: btnFg),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? kRetroElectricYellow : Colors.black87,
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
          ],
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
          ),
        ),
      ),
      const SizedBox(width: 12),
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _bump(step),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: btnBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: btnFg.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Icon(Icons.add, size: 24, color: btnFg),
        ),
      ),
    ]);
  }
}
