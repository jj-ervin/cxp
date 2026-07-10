import 'package:flutter/material.dart';

import '../../data/play_repository.dart';
import '../../models/saved_play.dart';

/// CXP.15 — lists locally saved plays. Tapping a play pops this screen
/// with the selected `SavedPlay` as the result; the court editor loads it
/// into the active session. This is the minimal "play database" named in
/// `CXP-OVERVIEW.md`'s v0.1 definition — no search, tags, or folders yet
/// (those are the next iteration once there's more than a handful of
/// plays to organize).
class PlayLibraryScreen extends StatefulWidget {
  const PlayLibraryScreen({super.key, required this.repository});

  final PlayRepository repository;

  @override
  State<PlayLibraryScreen> createState() => _PlayLibraryScreenState();
}

class _PlayLibraryScreenState extends State<PlayLibraryScreen> {
  late Future<List<SavedPlay>> _playsFuture;

  @override
  void initState() {
    super.initState();
    _playsFuture = widget.repository.loadAll();
  }

  void _refresh() {
    setState(() {
      _playsFuture = widget.repository.loadAll();
    });
  }

  Future<void> _delete(SavedPlay play) async {
    await widget.repository.delete(play.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Plays')),
      body: FutureBuilder<List<SavedPlay>>(
        future: _playsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final plays = snapshot.data!;
          if (plays.isEmpty) {
            return const Center(child: Text('No saved plays yet.'));
          }
          final sorted = [...plays]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.builder(
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final play = sorted[index];
              return ListTile(
                title: Text(play.name),
                subtitle: Text('${play.frames.length} frame(s) · ${_formatDate(play.createdAt)}'),
                onTap: () => Navigator.of(context).pop(play),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _delete(play),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
