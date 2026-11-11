import 'package:flutter/material.dart';

/// Curated, offline starter content. No player information or network calls.
class CoachingDrill {
  const CoachingDrill({
    required this.id,
    required this.name,
    required this.minutes,
    required this.skill,
    required this.level,
    required this.age,
    required this.equipment,
    required this.objective,
    required this.steps,
    required this.coachingCues,
  });
  final String id, name, skill, level, age, equipment, objective;
  final int minutes;
  final List<String> steps, coachingCues;
}

const starterDrills = <CoachingDrill>[
  CoachingDrill(id:'warmup',name:'Dynamic warm-up',minutes:10,skill:'Movement',level:'All levels',age:'All ages',equipment:'Cones (optional)',objective:'Prepare players to move safely and attentively.',steps:['Jog and change direction across half court.','Add lateral shuffles, skips and controlled backpedals.','Finish with short reaction starts.'],coachingCues:['Use controlled movements.','Increase intensity gradually.']),
  CoachingDrill(id:'handles',name:'Ball handling stations',minutes:15,skill:'Ball handling',level:'Beginner',age:'Youth',equipment:'One basketball per player, cones',objective:'Build confident control with either hand.',steps:['Set up three stations: stationary control, cone dribble, change of pace.','Rotate groups every four minutes.','Finish with a controlled weak-hand challenge.'],coachingCues:['Eyes up when ready.','Keep the ball protected.']),
  CoachingDrill(id:'form',name:'Form shooting',minutes:10,skill:'Shooting',level:'Beginner',age:'All ages',equipment:'Basketballs, baskets',objective:'Develop repeatable close-range shooting mechanics.',steps:['Begin close to the basket.','Shoot in pairs and track makes.','Step back only when form remains consistent.'],coachingCues:['Balance and follow-through.','Prioritize quality over distance.']),
  CoachingDrill(id:'passing',name:'Passing and cutting',minutes:15,skill:'Offense',level:'Intermediate',age:'Youth and up',equipment:'Basketballs, cones',objective:'Practice passing, moving and receiving in space.',steps:['Arrange three lines around the perimeter.','Pass and cut toward the basket, then fill an open spot.','Add a defender once the timing is consistent.'],coachingCues:['Move immediately after the pass.','Show a target hand.']),
  CoachingDrill(id:'defense',name:'Defensive slides and closeouts',minutes:15,skill:'Defense',level:'Intermediate',age:'Youth and up',equipment:'Cones',objective:'Improve stance, positioning and controlled closeouts.',steps:['Practice stance and short lateral slides.','Close out from help position to a marked attacker.','Add a live one-on-one finish.'],coachingCues:['Avoid crossing feet during short slides.','Close out under control.']),
  CoachingDrill(id:'advantage',name:'3-on-3 advantage game',minutes:20,skill:'Decision making',level:'Intermediate',age:'Youth and up',equipment:'Basketball, half court',objective:'Recognize spacing and quick decisions.',steps:['Play three-on-three from a designated start.','Limit dribbles to encourage passing and cuts.','Pause briefly to discuss an open option.'],coachingCues:['Read the defender.','Keep useful spacing.']),
  CoachingDrill(id:'scrimmage',name:'Controlled scrimmage',minutes:20,skill:'Team play',level:'All levels',age:'All ages',equipment:'Basketball, court',objective:'Apply the practice focus in game-like conditions.',steps:['Divide into balanced teams.','Set one focus rule, such as pass and cut.','Play short periods with feedback between them.'],coachingCues:['Reinforce the practice objective.','Keep substitutions equitable.']),
  CoachingDrill(id:'freethrow',name:'Free throws and cool-down',minutes:10,skill:'Shooting',level:'All levels',age:'All ages',equipment:'Basketballs, baskets',objective:'Practice a repeatable routine and finish practice calmly.',steps:['Shoot sets of two free throws.','Track personal consistency, not rankings.','Finish with a short team recap.'],coachingCues:['Use the same routine each time.','Praise focus and improvement.']),
];

/// Returns a selected drill to the practice planner; does not save a plan.
class DrillLibraryScreen extends StatefulWidget {
  const DrillLibraryScreen({super.key});
  @override
  State<DrillLibraryScreen> createState() => _DrillLibraryScreenState();
}

class _DrillLibraryScreenState extends State<DrillLibraryScreen> {
  String query = '';
  String skill = 'All';
  String level = 'All';
  @override
  Widget build(BuildContext context) {
    final skills = ['All', ...{for (final drill in starterDrills) drill.skill}];
    final levels = ['All', 'Beginner', 'Intermediate', 'All levels'];
    final results = starterDrills.where((drill) =>
      (skill == 'All' || drill.skill == skill) &&
      (level == 'All' || drill.level == level) &&
      ('${drill.name} ${drill.objective} ${drill.skill}'.toLowerCase().contains(query.toLowerCase()))
    ).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Basketball Drill Library')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search drills', border: OutlineInputBorder()),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 12, children: [
          DropdownButton<String>(value: skill, items: skills.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => skill = value!)),
          DropdownButton<String>(value: level, items: levels.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(), onChanged: (value) => setState(() => level = value!)),
        ]),
        Text('${results.length} drills', style: Theme.of(context).textTheme.labelLarge),
        for (final drill in results)
          Card(child: ListTile(
            title: Text(drill.name),
            subtitle: Text('${drill.minutes} min · ${drill.skill} · ${drill.level}\n${drill.objective}'),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final chosen = await Navigator.push<CoachingDrill>(context, MaterialPageRoute(builder: (_) => DrillDetailScreen(drill: drill)));
              if (chosen != null && context.mounted) Navigator.pop(context, chosen);
            },
          )),
        if (results.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No drills match these filters.')),
      ]),
    );
  }
}

class DrillDetailScreen extends StatelessWidget {
  const DrillDetailScreen({super.key, required this.drill});
  final CoachingDrill drill;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(drill.name)),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(drill.objective, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Text('${drill.minutes} min · ${drill.age} · ${drill.level}'),
      Text('Equipment: ${drill.equipment}'),
      const SizedBox(height: 20),
      Text('Instructions', style: Theme.of(context).textTheme.titleLarge),
      for (var i=0; i<drill.steps.length; i++) ListTile(leading: CircleAvatar(child: Text('${i+1}')), title: Text(drill.steps[i])),
      const SizedBox(height: 12),
      Text('Coaching cues', style: Theme.of(context).textTheme.titleLarge),
      for (final cue in drill.coachingCues) ListTile(leading: const Icon(Icons.tips_and_updates_outlined), title: Text(cue)),
      const SizedBox(height: 20),
      FilledButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Add to practice'),
        onPressed: () => Navigator.pop(context, drill),
      ),
    ]),
  );
}
