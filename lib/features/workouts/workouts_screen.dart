import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../session/session_screen.dart';
import 'workout_edit_screen.dart';

class WorkoutsScreen extends ConsumerStatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _start(WorkoutFull w) async {
    try {
      await ref.read(repoProvider).startSession(w.workout.id);
    } on StateError {
      if (mounted) snack(context, 'Já existe um treino em andamento.');
      return;
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(workoutsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('ESCOLHA O TREINO')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutEditScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'NOVO TREINO',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _q = norm(v)),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou grupo muscular...',
              prefixIcon: Icon(Icons.search, color: isDark ? kRetroNeonCyan : kRetroHotPink),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        setState(() => _q = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: kRetroHotPink),
            ),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (all) {
              final list = all
                  .where((w) =>
                      _q.isEmpty ||
                      norm(w.workout.name).contains(_q) ||
                      norm(w.workout.targetGroup).contains(_q))
                  .toList();
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      all.isEmpty
                          ? 'Nenhum treino ainda. Toque em NOVO TREINO para cadastrar.'
                          : 'Nenhum treino encontrado.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chakraPetch(fontSize: 15),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final w = list[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _start(w),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      w.workout.name.toUpperCase(),
                                      style: GoogleFonts.righteous(
                                        fontSize: 18,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2C134E) : const Color(0xFFF3E4F8),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDark ? kRetroNeonCyan : kRetroHotPink,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      w.workout.targetGroup.toUpperCase(),
                                      style: GoogleFonts.orbitron(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? kRetroNeonCyan : kRetroHotPink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (w.lines.isEmpty)
                                Text('Sem exercícios registrados',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor))
                              else
                                for (final l in w.lines)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.arrow_right,
                                          size: 16,
                                          color: kRetroHotPink,
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${l.exercise.name} ',
                                            style: GoogleFonts.chakraPetch(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '(${l.exercise.muscle} · ${l.targetSets}s)',
                                            style: GoogleFonts.chakraPetch(
                                              fontSize: 12,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kRetroHotPink,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          'INICIAR TREINO',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                          PopupMenuButton<String>(
                            iconColor: isDark ? kRetroNeonCyan : kRetroHotPink,
                            onSelected: (v) async {
                              if (v == 'edit') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => WorkoutEditScreen(workout: w)),
                                );
                              } else if (v == 'archive') {
                                final ok = await confirm(
                                  context,
                                  title: 'Arquivar treino?',
                                  message:
                                      'Ele some da lista, mas o histórico dos treinos já feitos continua salvo.',
                                  confirmLabel: 'Arquivar',
                                );
                                if (ok) {
                                  await ref.read(repoProvider).archiveWorkout(w.workout.id);
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar', style: GoogleFonts.chakraPetch()),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('Arquivar', style: GoogleFonts.chakraPetch()),
                              ),
                            ],
                          ),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
