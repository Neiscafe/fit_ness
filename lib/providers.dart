import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database.dart';
import 'data/repository.dart';

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repoProvider = Provider<Repo>((ref) => Repo(ref.watch(dbProvider)));

final exercisesProvider =
    StreamProvider<List<Exercise>>((ref) => ref.watch(repoProvider).watchExercises());

final workoutsProvider =
    StreamProvider<List<WorkoutFull>>((ref) => ref.watch(repoProvider).watchWorkouts());

final activeSessionProvider =
    StreamProvider<SessionFull?>((ref) => ref.watch(repoProvider).watchActive());

final lastSessionProvider =
    StreamProvider<SessionFull?>((ref) => ref.watch(repoProvider).watchLastFinished());

final historyProvider =
    StreamProvider<List<SessionFull>>((ref) => ref.watch(repoProvider).watchHistory());

final sessionDetailProvider = FutureProvider.family<SessionFull, int>(
  (ref, id) => ref.watch(repoProvider).loadSession(id),
);
