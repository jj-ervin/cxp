import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../court_editor/court_editor_screen.dart';
import '../practice_planner/practice_planner_screen.dart';

/// Small standalone coaching entry point. Team data remains on this device;
/// this is not an organization account or multi-user roster service.
class CoachingHomeScreen extends StatefulWidget {
  const CoachingHomeScreen({super.key});

  @override
  State<CoachingHomeScreen> createState() => _CoachingHomeScreenState();
}

class _CoachingHomeScreenState extends State<CoachingHomeScreen> {
  static const _storageKey = 'cxp.local.teams.v1';
  final List<_LocalTeam> _teams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (!mounted) return;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _teams.addAll(decoded.map((value) =>
            _LocalTeam.fromJson(value as Map<String, dynamic>)));
      } on FormatException {
        _showError('Saved teams could not be read.');
      } on TypeError {
        _showError('Saved team data has an unexpected format.');
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
      _storageKey,
      jsonEncode(_teams.map((team) => team.toJson()).toList()),
    );
    if (!success && mounted) _showError('Unable to save changes on this device.');
  }

  void _showError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  Future<String?> _askForName(String title, {String? initial}) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _addTeam() async {
    final name = await _askForName('Create basketball team');
    if (name == null || !mounted) return;
    setState(() => _teams.add(_LocalTeam(name: name)));
    await _save();
  }

  Future<void> _addPlayer(_LocalTeam team) async {
    final name = await _askForName('Add player to ${team.name}');
    if (name == null || !mounted) return;
    setState(() => team.players.add(name));
    await _save();
  }

  Future<void> _removePlayer(_LocalTeam team, int index) async {
    setState(() => team.players.removeAt(index));
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CXP — Coaching Workspace')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Basketball', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                const Text('Your teams and coaching tools, all in one place.'),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sports_basketball),
                    title: const Text('Play Editor'),
                    subtitle: const Text('Open your existing court and playbook tools'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CourtEditorScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text('My Teams', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    FilledButton.icon(
                      onPressed: _addTeam,
                      icon: const Icon(Icons.add),
                      label: const Text('New team'),
                    ),
                  ],
                ),
                if (_teams.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text('No teams yet. Create your first basketball team.'),
                  ),
                for (final team in _teams)
                  Card(
                    child: ExpansionTile(
                      key: ValueKey(team.id),
                      title: Text(team.name),
                      subtitle: Text('${team.players.length} players · Stored locally'),
                      children: [
                        for (var i = 0; i < team.players.length; i++)
                          ListTile(
                            title: Text(team.players[i]),
                            trailing: IconButton(
                              tooltip: 'Remove player',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _removePlayer(team, i),
                            ),
                          ),
                        ListTile(
                          leading: const Icon(Icons.event_note),
                          title: const Text('Practice planner'),
                          subtitle: const Text('Build and save timed practices'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => PracticePlannerScreen(teamId: team.id, teamName: team.name),
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_add_alt),
                          title: const Text('Add player'),
                          onTap: () => _addPlayer(team),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'This early workspace stores team names and player names only on this device. '
                  'It does not provide account sync or organization permissions. '
                  'Avoid entering sensitive information about minors.',
                ),
              ],
            ),
    );
  }
}

class _LocalTeam {
  _LocalTeam({required this.name, List<String>? players, String? id})
      : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        players = players ?? [];

  final String id;
  final String name;
  final List<String> players;

  factory _LocalTeam.fromJson(Map<String, dynamic> json) => _LocalTeam(
        id: json['id'] as String,
        name: json['name'] as String,
        players: (json['players'] as List<dynamic>).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'players': players,
      };
}
