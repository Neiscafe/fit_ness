import '../data/database.dart';
import '../data/repository.dart';

/// Melhor série: maior carga; em empate, mais repetições.
SetLog? bestSet(List<SetLog> sets) {
  SetLog? best;
  for (final s in sets) {
    if (best == null ||
        s.weightKg > best.weightKg ||
        (s.weightKg == best.weightKg && s.reps > best.reps)) {
      best = s;
    }
  }
  return best;
}

SetLog? setByNumber(List<SetLog> sets, int number) {
  for (final s in sets) {
    if (s.setNumber == number) return s;
  }
  return null;
}

/// Séries por músculo (só o músculo principal do exercício), da maior para a menor.
List<MapEntry<String, int>> volumeByMuscle(SessionFull s) {
  final m = <String, int>{};
  for (final it in s.items) {
    if (it.sets.isEmpty) continue;
    m[it.exercise.muscle] = (m[it.exercise.muscle] ?? 0) + it.sets.length;
  }
  return m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}
