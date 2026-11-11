import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'drill_library_screen.dart';

class PracticePlannerScreen extends StatefulWidget {
  const PracticePlannerScreen({super.key, required this.teamId, required this.teamName});
  final String teamId;
  final String teamName;

  @override
  State<PracticePlannerScreen> createState() => _PracticePlannerScreenState();
}

class _PracticePlannerScreenState extends State<PracticePlannerScreen> {
  final title = TextEditingController(text: 'Next practice');
  final activities = <_Activity>[];
  final plans = <_Practice>[];
  String? editingId;
  bool loading = true;
  bool saving = false;

  String get storageKey => 'cxp.local.practices.v1.${widget.teamId}';
  int get duration => activities.fold(0, (sum, a) => sum + a.minutes);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as List<dynamic>;
        plans.addAll(data.map((e) => _Practice.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        if (mounted) _notice('Saved practices could not be loaded.');
      }
    }
    if (mounted) setState(() => loading = false);
  }

  void _notice(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }

  Future<void> _save() async {
    if (saving) return;
    final name = title.text.trim();
    if (name.isEmpty || activities.isEmpty) {
      _notice('Enter a title and add at least one activity.');
      return;
    }
    setState(() => saving = true);
    final id = editingId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final next = _Practice(id, name, activities.map((a) => _Activity(a.name, a.minutes, drillId: a.drillId)).toList());
    final index = plans.indexWhere((p) => p.id == id);
    if (index < 0) {
      plans.add(next);
    } else {
      plans[index] = next;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final ok = await prefs.setString(storageKey, jsonEncode(plans.map((p) => p.toJson()).toList()));
      if (!ok) throw StateError('Local save failed');
      editingId = id;
      _notice('Practice saved on this device.');
    } catch (_) {
      if (index < 0) {
        plans.removeWhere((p) => p.id == id);
      }
      _notice('Could not save practice.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _addActivity({String? preset, int minutes = 10}) async {
    final nameController = TextEditingController(text: preset ?? '');
    final minuteController = TextEditingController(text: minutes.toString());
    final result = await showDialog<_Activity>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Practice activity'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, maxLength: 100, decoration: const InputDecoration(labelText: 'Activity')),
          TextField(controller: minuteController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutes (1–180)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final value = int.tryParse(minuteController.text.trim());
            final name = nameController.text.trim();
            if (name.isNotEmpty && value != null && value >= 1 && value <= 180) {
              Navigator.pop(context, _Activity(name, value));
            }
          }, child: const Text('Add')),
        ],
      ),
    );
    nameController.dispose();
    minuteController.dispose();
    if (result != null && mounted) setState(() => activities.add(result));
  }

  Future<void> _browseDrills() async {
    final selected = await Navigator.push<CoachingDrill>(
      context,
      MaterialPageRoute(builder: (_) => const DrillLibraryScreen()),
    );
    if (selected != null && mounted) {
      setState(() => activities.add(_Activity(selected.name, selected.minutes, drillId: selected.id)));
    }
  }

  void _open(_Practice plan) {
    setState(() {
      editingId = plan.id;
      title.text = plan.title;
      activities..clear()..addAll(plan.activities.map((a) => _Activity(a.name, a.minutes, drillId: a.drillId)));
    });
  }

  void _new() {
    setState(() {
      editingId = null;
      title.text = 'Next practice';
      activities.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Practice Planner — ${widget.teamName}')),
    body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Build a practice', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: 'Practice title', border: OutlineInputBorder())),
        Text('Total: $duration minutes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _browseDrills, icon: const Icon(Icons.menu_book), label: const Text('Browse drill library')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => _addActivity(), icon: const Icon(Icons.add), label: const Text('Custom activity')),
        for (var i = 0; i < activities.length; i++)
          Card(child: ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(activities[i].name),
            subtitle: Text('${activities[i].minutes} minutes${activities[i].drillId == null ? '' : ' · Library drill'}'),
            onTap: activities[i].drillId == null ? null : () {
              final drill = starterDrills.where((d) => d.id == activities[i].drillId).firstOrNull;
              if (drill != null) Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DrillDetailScreen(drill: drill)));
            },
            trailing: IconButton(
              tooltip: 'Remove activity',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => activities.removeAt(i)),
            ),
          )),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save), label: const Text('Save practice'))),
          const SizedBox(width: 8),
          OutlinedButton(onPressed: _new, child: const Text('New')),
        ]),
        const SizedBox(height: 24),
        Text('Saved practices', style: Theme.of(context).textTheme.titleLarge),
        if (plans.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No saved practices yet.')),
        for (final plan in plans)
          Card(child: ListTile(
            title: Text(plan.title),
            subtitle: Text('${plan.activities.length} activities · ${plan.activities.fold<int>(0, (sum, a) => sum + a.minutes)} minutes'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _open(plan),
          )),
      ],
    ),
  );
}

class _Activity {
  _Activity(this.name, this.minutes, {this.drillId});
  final String name;
  final int minutes;
  final String? drillId;
  factory _Activity.fromJson(Map<String, dynamic> j) => _Activity(j['name'] as String, j['minutes'] as int, drillId: j['drillId'] as String?);
  Map<String, dynamic> toJson() => {'name': name, 'minutes': minutes, if (drillId != null) 'drillId': drillId};
}

class _Practice {
  _Practice(this.id, this.title, this.activities);
  final String id;
  final String title;
  final List<_Activity> activities;
  factory _Practice.fromJson(Map<String, dynamic> j) => _Practice(
    j['id'] as String,
    j['title'] as String,
    (j['activities'] as List<dynamic>).map((a) => _Activity.fromJson(a as Map<String, dynamic>)).toList(),
  );
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'activities': activities.map((a) => a.toJson()).toList()};
}
