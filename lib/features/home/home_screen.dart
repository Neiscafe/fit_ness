import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../main.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../history/history_screen.dart';
import '../history/session_detail_screen.dart';
import '../session/session_screen.dart';
import '../workouts/workouts_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSessionProvider);
    final last = ref.watch(lastSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const loading = SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(color: kRetroHotPink),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: kRetroHotPink,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: kRetroNeonCyan,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: const NessieIcon(size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              'FIT',
              style: GoogleFonts.righteous(
                fontSize: 22,
                letterSpacing: 2.0,
                color: isDark ? kRetroNeonCyan : kRetroHotPink,
              ),
            ),
            Text(
              'NESS',
              style: GoogleFonts.righteous(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? kRetroElectricYellow : kRetroHotPink,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'GYM APP',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : kRetroHotPink,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bloquear aplicativo (Modo Kiosk)',
            style: IconButton.styleFrom(
                backgroundColor:
                  Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10))),
            icon: Icon(Icons.fullscreen_sharp,
                color: isDark ? kRetroElectricYellow : kRetroPurpleLight,),
            onPressed: () async {
              await startKioskMode();
              if (context.mounted) {
                snack(context, 'Modo Kiosk ativado! O aplicativo está fixado.');
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          active.when(
            data: (s) => s == null ? const _StartCard() : _ContinueCard(s),
            loading: () => loading,
            error: (e, _) => Text('Erro: $e'),
          ),
          const SizedBox(height: 20),
          last.when(
            data: (s) => s == null
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? kRetroCardDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? kRetroCardDarkBorder
                            : const Color(0xFFE2C6F0),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'SEU ÚLTIMO TREINO VAI APARECER AQUI DEPOIS QUE VOCÊ CONCLUIR O PRIMEIRA SESSÃO.',
                      style: GoogleFonts.chakraPetch(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).hintColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _LastCard(s),
            loading: () => loading,
            error: (e, _) => Text('Erro: $e'),
          ),
        ],
      ),
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF2B1040), const Color(0xFF1E0A33)]
                : [const Color(0xFFFFF0F7), const Color(0xFFF3E4F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kRetroNeonCyan,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'PRONTO PARA O TREINO?',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? kRetroElectricYellow : kRetroHotPink,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha um treino e registre suas cargas e repetições.',
            style: GoogleFonts.chakraPetch(fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutsScreen()),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 22),
            label: const Text('COMEÇAR TREINO'),
          ),
        ]),
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard(this.s);

  final SessionFull s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3B124C) : const Color(0xFFFFE0F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: kRetroHotPink,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: kRetroHotPink.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kRetroNeonCyan,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'EM ANDAMENTO',
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          s.session.workoutName.toUpperCase(),
          style: GoogleFonts.righteous(
            fontSize: 22,
            color: isDark ? kRetroElectricYellow : kRetroHotPink,
          ),
        ),
        Text(
          s.session.targetGroup.toUpperCase(),
          style: GoogleFonts.chakraPetch(
            fontWeight: FontWeight.bold,
            color: isDark ? kRetroNeonCyan : const Color(0xFF6B0042),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SessionScreen()),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('CONTINUAR'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'Descartar treino?',
                message:
                    'Todas as séries registradas neste treino serão apagadas.',
                confirmLabel: 'Descartar',
              );
              if (ok) await ref.read(repoProvider).cancelSession(s.session.id);
            },
            child: const Text('DESCARTAR'),
          ),
        ]),
      ]),
    );
  }
}

class _LastCard extends StatelessWidget {
  const _LastCard(this.s);

  final SessionFull s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final when = s.session.finishedAt ?? s.session.startedAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ÚLTIMO TREINO',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? kRetroElectricYellow : kRetroHotPink,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C134E)
                      : const Color(0xFFF3E4F8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: kRetroNeonCyan, width: 1),
                ),
                child: Text(
                  fmtDate(when),
                  style: GoogleFonts.chakraPetch(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? kRetroNeonCyan : kRetroHotPink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            s.session.workoutName,
            style: GoogleFonts.righteous(
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            s.session.targetGroup,
            style: GoogleFonts.chakraPetch(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? kRetroNeonCyan : kRetroHotPink,
            ),
          ),
          const Divider(height: 24),
          for (final it in s.items) _LastExerciseRow(it),
          const Divider(height: 24),
          Text(
            'SÉRIES POR MÚSCULO',
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? kRetroElectricYellow : kRetroHotPink,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          VolumeChips(s),
          const SizedBox(height: 16),
          Row(children: [
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SessionDetailScreen(s.session.id)),
              ),
              child: const Text('DETALHES'),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: const Text('HISTÓRICO'),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _LastExerciseRow extends StatelessWidget {
  const _LastExerciseRow(this.it);

  final SessionItem it;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final best = bestSet(it.sets);
    final prevBest = bestSet(it.prev);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(
              it.exercise.name,
              style: GoogleFonts.chakraPetch(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
        ]),
        const SizedBox(height: 4),
        if (best == null)
          Text('Sem séries registradas',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: theme.hintColor))
        else
          Row(children: [
            Text(
              '${fmtKg(best.weightKg)} kg × ${best.reps}',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? kRetroElectricYellow : Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            SetDeltas(best, prevBest),
          ]),
      ]),
    );
  }
}
