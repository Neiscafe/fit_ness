import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../exercises/exercises_screen.dart';

class WorkoutEditScreen extends ConsumerStatefulWidget {
  const WorkoutEditScreen({super.key, this.workout});
  final WorkoutFull? workout;

  @override
  ConsumerState<WorkoutEditScreen> createState() => _WorkoutEditScreenState();
}

class _WorkoutEditScreenState extends ConsumerState<WorkoutEditScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.workout?.workout.name ?? '');
  late final TextEditingController _group =
      TextEditingController(text: widget.workout?.workout.targetGroup ?? '');
  late final List<WorkoutLine> _lines = [...?widget.workout?.lines];

  @override
  void dispose() {
    _name.dispose();
    _group.dispose();
    super.dispose();
  }

  Future<Exercise?> _pick() => Navigator.push<Exercise>(
        context,
        MaterialPageRoute(builder: (_) => const ExercisesScreen()),
      );

  Future<void> _add() async {
    final e = await _pick();
    if (e != null && mounted) setState(() => _lines.add(WorkoutLine(e, 3)));
  }

  Future<void> _replace(int i) async {
    final e = await _pick();
    if (e != null && mounted) {
      setState(() => _lines[i] = WorkoutLine(e, _lines[i].targetSets));
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final group = _group.text.trim();
    if (name.isEmpty || group.isEmpty) {
      snack(context, 'Preencha o nome e o grupo muscular alvo.');
      return;
    }
    await ref.read(repoProvider).saveWorkout(
          id: widget.workout?.workout.id,
          name: name,
          targetGroup: group,
          lines: _lines,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout == null ? 'NOVO TREINO' : 'EDITAR TREINO'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'NOME DO TREINO',
              hintText: 'Ex.: Peito & Tríceps Neon',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _group,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'GRUPO MUSCULAR ALVO',
              hintText: 'Ex.: Upper Body / Superiores',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXERCÍCIOS',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? kRetroElectricYellow : kRetroHotPink,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${_lines.length} ITENS',
                style: GoogleFonts.chakraPetch(
                  fontWeight: FontWeight.bold,
                  color: isDark ? kRetroNeonCyan : kRetroHotPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Nenhum exercício adicionado ainda.',
                  style: GoogleFonts.chakraPetch(color: theme.hintColor),
                ),
              ),
            ),
          for (var i = 0; i < _lines.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          _lines[i].exercise.name,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          _lines[i].exercise.muscle.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            color: isDark ? kRetroNeonCyan : kRetroHotPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                    IconButton(
                      tooltip: 'Substituir exercício',
                      onPressed: () => _replace(i),
                      icon: Icon(Icons.swap_horiz, color: isDark ? kRetroNeonCyan : kRetroHotPink),
                    ),
                    IconButton(
                      tooltip: 'Remover exercício',
                      onPressed: () => setState(() => _lines.removeAt(i)),
                      icon: const Icon(Icons.delete_outline, color: kRetroNeonRed),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(
                      'SÉRIES ALVO',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    CountStepper(
                      value: _lines[i].targetSets,
                      onChanged: (n) => setState(
                          () => _lines[i] = WorkoutLine(_lines[i].exercise, n)),
                    ),
                  ]),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.add),
            label: const Text('ADICIONAR EXERCÍCIO'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _save,
            child: const Text('SALVAR TREINO'),
          ),
        ],
      ),
    );
  }
}
