import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../data/database.dart';
import '../../data/repository.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../exercises/exercises_screen.dart';
import 'set_edit_screen.dart';

class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  Future<void> _finish(BuildContext context, WidgetRef ref, SessionFull s) async {
    final total = s.totalSets;
    final ok = await confirm(
      context,
      title: 'Concluir treino?',
      message: total == 0
          ? 'Nenhuma série foi registrada. Deseja concluir mesmo assim?'
          : 'Você registrou $total ${total == 1 ? 'série' : 'séries'}. Deseja concluir o treino?',
      confirmLabel: 'Concluir',
    );
    if (!ok || !context.mounted) return;
    await ref.read(repoProvider).finishSession(s.session.id);
    if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, SessionFull s) async {
    final ok = await confirm(
      context,
      title: 'Cancelar treino?',
      message: 'Todas as séries registradas neste treino serão apagadas.',
      confirmLabel: 'Cancelar treino',
    );
    if (!ok || !context.mounted) return;
    await ref.read(repoProvider).cancelSession(s.session.id);
    if (context.mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _addExercise(BuildContext context, WidgetRef ref, SessionFull s) async {
    final e = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisesScreen()),
    );
    if (e != null) await ref.read(repoProvider).addSessionExercise(s.session.id, e.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(activeSessionProvider).valueOrNull;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator(color: kRetroHotPink)),
      );
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            s.session.workoutName.toUpperCase(),
            style: GoogleFonts.righteous(
              fontSize: 18,
              color: isDark ? kRetroNeonCyan : kRetroHotPink,
            ),
          ),
          Text(
            s.session.targetGroup.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? kRetroElectricYellow : Colors.black87,
            ),
          ),
        ]),
        actions: [
          PopupMenuButton<String>(
            iconColor: isDark ? kRetroNeonCyan : kRetroHotPink,
            onSelected: (v) {
              if (v == 'cancel') _cancel(context, ref, s);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'cancel',
                child: Text('Cancelar treino', style: GoogleFonts.chakraPetch()),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (final it in s.items) _ExerciseCard(session: s, item: it),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _addExercise(context, ref, s),
            icon: const Icon(Icons.add),
            label: const Text('ADICIONAR EXERCÍCIO'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => _finish(context, ref, s),
            child: const Text('CONCLUIR TREINO'),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({required this.session, required this.item});
  final SessionFull session;
  final SessionItem item;

  Future<void> _replace(BuildContext context, WidgetRef ref) async {
    final e = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(builder: (_) => const ExercisesScreen()),
    );
    if (e == null || e.id == item.exercise.id || !context.mounted) return;
    if (item.sets.isNotEmpty) {
      final ok = await confirm(
        context,
        title: 'Substituir exercício?',
        message: 'As séries já registradas em ${item.exercise.name} serão apagadas.',
        confirmLabel: 'Substituir',
      );
      if (!ok) return;
    }
    await ref.read(repoProvider).replaceSessionExercise(item.se, e.id);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final ok = await confirm(
      context,
      title: 'Remover exercício?',
      message: item.sets.isEmpty
          ? 'O exercício sai deste treino.'
          : 'O exercício e as séries registradas nele saem deste treino.',
      confirmLabel: 'Remover',
    );
    if (ok) await ref.read(repoProvider).removeSessionExercise(item.se.id);
  }

  void _openSet(BuildContext context, {SetLog? editing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetEditScreen(
          item: item,
          setNumber: editing?.setNumber ?? item.sets.length + 1,
          editing: editing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final repo = ref.read(repoProvider);
    final target = item.se.targetSets;
    final progress = (item.sets.length / target).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  item.exercise.name,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  item.exercise.muscle.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? kRetroNeonCyan : kRetroHotPink,
                  ),
                ),
              ]),
            ),
            PopupMenuButton<String>(
              iconColor: isDark ? kRetroNeonCyan : kRetroHotPink,
              onSelected: (v) {
                if (v == 'replace') _replace(context, ref);
                if (v == 'remove') _remove(context, ref);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'replace',
                  child: Text('Substituir exercício', style: GoogleFonts.chakraPetch()),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Remover exercício', style: GoogleFonts.chakraPetch()),
                ),
              ],
            ),
          ]),
          if (item.original != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                'Original: ${item.original!.name}',
                style: GoogleFonts.chakraPetch(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: theme.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${item.sets.length} DE $target SÉRIES ALVO',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? kRetroElectricYellow : kRetroHotPink,
                  ),
                ),
              ),
              CountStepper(
                value: target,
                onChanged: (n) => repo.setTargetSets(item.se.id, n),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: isDark ? const Color(0xFF2C1548) : const Color(0xFFEADBEE),
                color: isDark ? kRetroNeonCyan : kRetroHotPink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              item.prev.isEmpty
                  ? 'Sem registro anterior'
                  : 'ÚLTIMA VEZ: ${item.prev.map((s) => '${fmtKg(s.weightKg)}×${s.reps}').join('  |  ')}',
              style: GoogleFonts.chakraPetch(
                fontSize: 11,
                color: theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (item.sets.isNotEmpty) const Divider(height: 20),
          for (final set in item.sets)
            ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(right: 8),
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? kRetroHotPink : const Color(0xFFFFD0E5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? kRetroNeonCyan : kRetroHotPink,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${set.setNumber}',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : kRetroHotPink,
                    ),
                  ),
                ),
              ),
              title: Text(
                '${fmtKg(set.weightKg)} kg × ${set.reps} reps',
                style: GoogleFonts.orbitron(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SetDeltas(set, setByNumber(item.prev, set.setNumber)),
              ),
              trailing: Icon(Icons.edit_outlined, size: 18, color: isDark ? kRetroNeonCyan : kRetroHotPink),
              onTap: () => _openSet(context, editing: set),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openSet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('ADICIONAR SÉRIE'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
