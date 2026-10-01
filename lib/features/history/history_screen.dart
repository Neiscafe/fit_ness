import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/stats.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('HISTÓRICO DE TREINOS')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kRetroHotPink)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Nenhum treino concluído ainda.',
                style: GoogleFonts.chakraPetch(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              final vol = volumeByMuscle(s).map((e) => '${e.key} ${e.value}').join(' • ');
              final dateStr = fmtDate(s.session.finishedAt ?? s.session.startedAt);
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.session.workoutName.toUpperCase(),
                          style: GoogleFonts.righteous(
                            fontSize: 16,
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
                          dateStr,
                          style: GoogleFonts.chakraPetch(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? kRetroNeonCyan : kRetroHotPink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.session.targetGroup.toUpperCase(),
                          style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? kRetroElectricYellow : kRetroHotPink,
                          ),
                        ),
                        if (vol.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              vol,
                              style: GoogleFonts.chakraPetch(
                                fontSize: 12,
                                color: theme.hintColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kRetroHotPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${s.totalSets} SÉRIES',
                      style: GoogleFonts.orbitron(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SessionDetailScreen(s.session.id)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
