import 'package:drift/drift.dart';

import 'database.dart';

class WorkoutLine {
  const WorkoutLine(this.exercise, this.targetSets);

  final Exercise exercise;
  final int targetSets;
}

class WorkoutFull {
  const WorkoutFull(this.workout, this.lines);

  final Workout workout;
  final List<WorkoutLine> lines;
}

class SessionItem {
  const SessionItem({
    required this.se,
    required this.exercise,
    required this.original,
    required this.sets,
    required this.prev,
  });

  final SessionExercise se;
  final Exercise exercise;
  final Exercise? original;
  final List<SetLog> sets;

  /// Séries da última vez que este exercício foi feito (em qualquer treino).
  final List<SetLog> prev;
}

class SessionFull {
  const SessionFull(this.session, this.items);

  final Session session;
  final List<SessionItem> items;

  int get totalSets => items.fold(0, (a, i) => a + i.sets.length);
}

class Repo {
  final AppDatabase db;

  Repo(this.db);

  /// Carrega uma vez e recarrega sempre que alguma das tabelas mudar.
  Stream<T> _watch<T>(
    Future<T> Function() load,
    Iterable<ResultSetImplementation> tables,
  ) async* {
    yield await load();
    await for (final _
        in db.tableUpdates(TableUpdateQuery.onAllTables(tables))) {
      yield await load();
    }
  }

  // ---------------------------------------------------------------- exercícios

  Stream<List<Exercise>> watchExercises() => _watch(
        () => (db.select(db.exercises)
              ..where((e) => e.archived.equals(false))
              ..orderBy([(e) => OrderingTerm.asc(e.name)]))
            .get(),
        [db.exercises],
      );

  Future<Exercise> createExercise(String name, String muscle) async {
    final id = await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
              name: name, muscle: muscle, isCustom: const Value(true)),
        );
    return (db.select(db.exercises)..where((e) => e.id.equals(id))).getSingle();
  }

  // -------------------------------------------------------------------- treinos

  Future<List<WorkoutFull>> _loadWorkouts() async {
    final q = db.select(db.workouts).join([
      leftOuterJoin(
        db.workoutExercises,
        db.workoutExercises.workoutId.equalsExp(db.workouts.id),
      ),
      leftOuterJoin(
        db.exercises,
        db.exercises.id.equalsExp(db.workoutExercises.exerciseId),
      ),
    ]);
    q.where(db.workouts.archived.equals(false));
    q.orderBy([
      OrderingTerm.desc(db.workouts.createdAt),
      OrderingTerm.desc(db.workouts.id),
      OrderingTerm.asc(db.workoutExercises.position),
    ]);
    final rows = await q.get();
    final groups = <int, (Workout, List<WorkoutLine>)>{};
    for (final r in rows) {
      final w = r.readTable(db.workouts);
      final g = groups.putIfAbsent(w.id, () => (w, <WorkoutLine>[]));
      final we = r.readTableOrNull(db.workoutExercises);
      final ex = r.readTableOrNull(db.exercises);
      if (we != null && ex != null) g.$2.add(WorkoutLine(ex, we.targetSets));
    }
    return [for (final g in groups.values) WorkoutFull(g.$1, g.$2)];
  }

  Stream<List<WorkoutFull>> watchWorkouts() =>
      _watch(_loadWorkouts, [db.workouts, db.workoutExercises, db.exercises]);

  Future<void> saveWorkout({
    int? id,
    required String name,
    required String targetGroup,
    required List<WorkoutLine> lines,
  }) {
    return db.transaction(() async {
      final int wid;
      if (id == null) {
        wid = await db.into(db.workouts).insert(
              WorkoutsCompanion.insert(name: name, targetGroup: targetGroup),
            );
      } else {
        wid = id;
        await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
          WorkoutsCompanion(name: Value(name), targetGroup: Value(targetGroup)),
        );
        await (db.delete(db.workoutExercises)
              ..where((w) => w.workoutId.equals(id)))
            .go();
      }
      for (var i = 0; i < lines.length; i++) {
        await db.into(db.workoutExercises).insert(
              WorkoutExercisesCompanion.insert(
                workoutId: wid,
                position: i,
                exerciseId: lines[i].exercise.id,
                targetSets: lines[i].targetSets,
              ),
            );
      }
    });
  }

  /// Arquivar (e não apagar) mantém o histórico íntegro.
  Future<void> archiveWorkout(int id) =>
      (db.update(db.workouts)..where((w) => w.id.equals(id)))
          .write(const WorkoutsCompanion(archived: Value(true)));

  // ------------------------------------------------------------------- sessões

  Future<Session?> _activeRow() => (db.select(db.sessions)
        ..where((s) => s.finishedAt.isNull())
        ..limit(1))
      .getSingleOrNull();

  Future<List<SetLog>> previousSets(int exerciseId, {DateTime? before}) async {
    Expression<bool> cond = db.sessionExercises.exerciseId.equals(exerciseId) &
        db.sessions.finishedAt.isNotNull();
    if (before != null) {
      cond = cond & db.sessions.finishedAt.isSmallerThanValue(before);
    }
    final q = db.select(db.sessionExercises).join([
      innerJoin(
          db.sessions, db.sessions.id.equalsExp(db.sessionExercises.sessionId)),
    ])
      ..where(cond)
      ..orderBy([
        OrderingTerm.desc(db.sessions.finishedAt),
        OrderingTerm.asc(db.sessionExercises.position),
      ]);
    final rows = await q.get();
    for (final r in rows) {
      final se = r.readTable(db.sessionExercises);
      final sets = await (db.select(db.setLogs)
            ..where((s) => s.sessionExerciseId.equals(se.id))
            ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
          .get();
      if (sets.isNotEmpty) return sets;
    }
    return const <SetLog>[];
  }

  Future<SessionFull> _loadSession(Session s, {bool withPrev = true}) async {
    final exMap = {
      for (final e in await db.select(db.exercises).get()) e.id: e
    };
    final ses = await (db.select(db.sessionExercises)
          ..where((t) => t.sessionId.equals(s.id))
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    final sets = ses.isEmpty
        ? <SetLog>[]
        : await (db.select(db.setLogs)
              ..where((t) => t.sessionExerciseId.isIn(ses.map((e) => e.id)))
              ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
            .get();
    final items = <SessionItem>[];
    for (final se in ses) {
      items.add(SessionItem(
        se: se,
        exercise: exMap[se.exerciseId]!,
        original:
            se.originalExerciseId == null ? null : exMap[se.originalExerciseId],
        sets: sets.where((x) => x.sessionExerciseId == se.id).toList(),
        prev: withPrev
            ? await previousSets(se.exerciseId, before: s.finishedAt)
            : const <SetLog>[],
      ));
    }
    return SessionFull(s, items);
  }

  Stream<SessionFull?> watchActive() => _watch<SessionFull?>(() async {
        final s = await _activeRow();
        return s == null ? null : _loadSession(s);
      }, [db.sessions, db.sessionExercises, db.setLogs, db.exercises]);

  Stream<SessionFull?> watchLastFinished() => _watch<SessionFull?>(() async {
        final s = await (db.select(db.sessions)
              ..where((s) => s.finishedAt.isNotNull())
              ..orderBy([(s) => OrderingTerm.desc(s.finishedAt)])
              ..limit(1))
            .getSingleOrNull();
        return s == null ? null : _loadSession(s);
      }, [db.sessions, db.sessionExercises, db.setLogs, db.exercises]);

  Stream<List<SessionFull>> watchHistory() =>
      _watch<List<SessionFull>>(() async {
        final list = await (db.select(db.sessions)
              ..where((s) => s.finishedAt.isNotNull())
              ..orderBy([(s) => OrderingTerm.desc(s.finishedAt)]))
            .get();
        return [for (final s in list) await _loadSession(s, withPrev: false)];
      }, [db.sessions, db.sessionExercises, db.setLogs, db.exercises]);

  Future<SessionFull> loadSession(int id) async {
    final s = await (db.select(db.sessions)..where((t) => t.id.equals(id)))
        .getSingle();
    return _loadSession(s);
  }

  /// Copia o treino modelo para uma nova sessão. Só uma sessão em andamento por vez.
  Future<int> startSession(int workoutId) {
    return db.transaction(() async {
      if (await _activeRow() != null) {
        throw StateError('Já existe um treino em andamento.');
      }
      final w = await (db.select(db.workouts)
            ..where((t) => t.id.equals(workoutId)))
          .getSingle();
      final lines = await (db.select(db.workoutExercises)
            ..where((t) => t.workoutId.equals(workoutId))
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      final sid = await db.into(db.sessions).insert(
            SessionsCompanion.insert(
              workoutId: Value(w.id),
              workoutName: w.name,
              targetGroup: w.targetGroup,
              startedAt: DateTime.now(),
            ),
          );
      for (var i = 0; i < lines.length; i++) {
        await db.into(db.sessionExercises).insert(
              SessionExercisesCompanion.insert(
                sessionId: sid,
                position: i,
                exerciseId: lines[i].exerciseId,
                targetSets: lines[i].targetSets,
              ),
            );
      }
      return sid;
    });
  }

  Future<void> finishSession(int id) =>
      (db.update(db.sessions)..where((s) => s.id.equals(id)))
          .write(SessionsCompanion(finishedAt: Value(DateTime.now())));

  Future<void> cancelSession(int id) {
    return db.transaction(() async {
      final ses = await (db.select(db.sessionExercises)
            ..where((t) => t.sessionId.equals(id)))
          .get();
      final ids = ses.map((e) => e.id).toList();
      await (db.delete(db.setLogs)..where((t) => t.sessionExerciseId.isIn(ids)))
          .go();
      await (db.delete(db.sessionExercises)
            ..where((t) => t.sessionId.equals(id)))
          .go();
      await (db.delete(db.sessions)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> addSessionExercise(int sessionId, int exerciseId,
      {int targetSets = 3}) async {
    final rows = await (db.select(db.sessionExercises)
          ..where((t) => t.sessionId.equals(sessionId)))
        .get();
    final pos =
        rows.fold<int>(-1, (a, r) => r.position > a ? r.position : a) + 1;
    await db.into(db.sessionExercises).insert(
          SessionExercisesCompanion.insert(
            sessionId: sessionId,
            position: pos,
            exerciseId: exerciseId,
            targetSets: targetSets,
          ),
        );
  }

  Future<void> removeSessionExercise(int id) {
    return db.transaction(() async {
      await (db.delete(db.setLogs)
            ..where((t) => t.sessionExerciseId.equals(id)))
          .go();
      await (db.delete(db.sessionExercises)..where((t) => t.id.equals(id)))
          .go();
    });
  }

  /// Troca o exercício só nesta sessão e apaga as séries já registradas nele.
  /// Guarda o exercício original; se voltar ao original, o marcador some.
  Future<void> replaceSessionExercise(SessionExercise se, int newExerciseId) {
    return db.transaction(() async {
      final orig = se.originalExerciseId ?? se.exerciseId;
      await (db.delete(db.setLogs)
            ..where((t) => t.sessionExerciseId.equals(se.id)))
          .go();
      await (db.update(db.sessionExercises)..where((t) => t.id.equals(se.id)))
          .write(
        SessionExercisesCompanion(
          exerciseId: Value(newExerciseId),
          originalExerciseId: Value(newExerciseId == orig ? null : orig),
        ),
      );
    });
  }

  Future<void> setTargetSets(int sessionExerciseId, int n) =>
      (db.update(db.sessionExercises)
            ..where((t) => t.id.equals(sessionExerciseId)))
          .write(SessionExercisesCompanion(targetSets: Value(n < 1 ? 1 : n)));

  Future<void> addSet(int sessionExerciseId, double weightKg, int reps) async {
    final count = (await (db.select(db.setLogs)
              ..where((t) => t.sessionExerciseId.equals(sessionExerciseId)))
            .get())
        .length;
    await db.into(db.setLogs).insert(
          SetLogsCompanion.insert(
            sessionExerciseId: sessionExerciseId,
            setNumber: count + 1,
            weightKg: weightKg,
            reps: reps,
          ),
        );
  }

  Future<void> updateSet(int id, double weightKg, int reps) =>
      (db.update(db.setLogs)..where((t) => t.id.equals(id))).write(
          SetLogsCompanion(weightKg: Value(weightKg), reps: Value(reps)));

  /// Remove a série e renumera as seguintes.
  Future<void> deleteSet(SetLog set) {
    return db.transaction(() async {
      await (db.delete(db.setLogs)..where((t) => t.id.equals(set.id))).go();
      final rest = await (db.select(db.setLogs)
            ..where((t) => t.sessionExerciseId.equals(set.sessionExerciseId))
            ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
          .get();
      for (var i = 0; i < rest.length; i++) {
        if (rest[i].setNumber != i + 1) {
          await (db.update(db.setLogs)..where((t) => t.id.equals(rest[i].id)))
              .write(SetLogsCompanion(setNumber: Value(i + 1)));
        }
      }
    });
  }
}
