import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/format.dart';
import '../../core/muscles.dart';
import '../../core/theme.dart';
import '../../providers.dart';

/// Lista de exercícios. Ao tocar em um, a tela fecha devolvendo o [Exercise] escolhido.
class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final nameCtrl = TextEditingController(text: _search.text.trim());
    var muscle = kMuscles.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: kRetroHotPink),
            const SizedBox(width: 8),
            Text('NOVO EXERCÍCIO', style: GoogleFonts.righteous(fontSize: 18)),
          ],
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'NOME DO EXERCÍCIO',
              hintText: 'Ex.: Supino Reto com Barra',
            ),
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            initialSelection: muscle,
            label: const Text('GRUPO MUSCULAR'),
            expandedInsets: EdgeInsets.zero,
            textStyle: GoogleFonts.chakraPetch(),
            dropdownMenuEntries: [
              for (final m in kMuscles) DropdownMenuEntry(value: m, label: m),
            ],
            onSelected: (v) => muscle = v ?? muscle,
          ),
        ]),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CRIAR'),
          ),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok != true || name.isEmpty) return;
    final ex = await ref.read(repoProvider).createExercise(name, muscle);
    if (mounted) Navigator.pop(context, ex);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(exercisesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('EXERCÍCIOS')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: Text('NOVO EXERCÍCIO', style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
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
            loading: () => const Center(child: CircularProgressIndicator(color: kRetroHotPink)),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (all) {
              final list = all
                  .where((e) =>
                      _q.isEmpty || norm(e.name).contains(_q) || norm(e.muscle).contains(_q))
                  .toList();
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Nenhum exercício encontrado. Toque em NOVO EXERCÍCIO para cadastrar.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.chakraPetch(fontSize: 14),
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96, left: 8, right: 8),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                        e.name,
                        style: GoogleFonts.chakraPetch(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2E134E) : const Color(0xFFF3E4F8),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDark ? kRetroNeonCyan : kRetroHotPink,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              e.muscle.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? kRetroNeonCyan : kRetroHotPink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: isDark ? kRetroNeonCyan : kRetroHotPink,
                      ),
                      onTap: () => Navigator.pop(context, e),
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
