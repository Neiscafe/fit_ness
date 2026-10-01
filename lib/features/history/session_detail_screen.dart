import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Visão somente leitura de um treino concluído, com a variação de cada série
/// em relação à última vez que o exercício foi feito antes dele.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen(this.sessionId, {super.key});
  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionDetailProvider(sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('DETALHES DO TREINO')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kRetroHotPink)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (s) => _Body(s),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.s);
  final SessionFull s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final end = s.session.finishedAt;
    final minutes = end?.difference(s.session.startedAt).inMinutes;

    return ListView(
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
                s.session.workoutName.toUpperCase(),
                style: GoogleFonts.righteous(
                  fontSize: 22,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kRetroHotPink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.session.targetGroup.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    fmtDate(end ?? s.session.startedAt),
                    style: GoogleFonts.chakraPetch(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? kRetroNeonCyan : kRetroHotPink,
                    ),
                  ),
                  if (minutes != null) ...[
                    const Spacer(),
                    Icon(Icons.timer_outlined, size: 16, color: isDark ? kRetroElectricYellow : kRetroHotPink),
                    const SizedBox(width: 4),
                    Text(
                      '$minutes min',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? kRetroElectricYellow : kRetroHotPink,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final it in s.items) _ItemCard(it),
        const SizedBox(height: 12),
        Text(
          'SÉRIES POR MÚSCULO',
          style: GoogleFonts.orbitron(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? kRetroElectricYellow : kRetroHotPink,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        VolumeChips(s),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(this.it);
  final SessionItem it;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  it.exercise.name,
                  style: GoogleFonts.chakraPetch(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D164D) : const Color(0xFFEDE0F5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${it.sets.length}/${it.se.targetSets} SÉRIES',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? kRetroNeonCyan : kRetroHotPink,
                  ),
                ),
              ),
            ],
          ),
          Text(
            it.exercise.muscle.toUpperCase(),
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? kRetroNeonCyan : kRetroHotPink,
            ),
          ),
          if (it.original != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Original: ${it.original!.name}',
                style: GoogleFonts.chakraPetch(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (it.sets.isEmpty)
            Text(
              'Sem séries registradas',
              style: GoogleFonts.chakraPetch(fontSize: 12, color: theme.hintColor),
            ),
          for (final set in it.sets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? kRetroHotPink : const Color(0xFFFFD0E5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'SÉRIE ${set.setNumber}',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : kRetroHotPink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${fmtKg(set.weightKg)} kg × ${set.reps} reps',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SetDeltas(set, setByNumber(it.prev, set.setNumber)),
              ]),
            ),
        ]),
      ),
    );
  }
}
