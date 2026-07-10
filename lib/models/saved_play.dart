/// Prototype-scoped version of the `Play` shape defined in
/// `docs/architecture/domain-model.md`. This intentionally does not carry
/// the full domain model's fields yet (`organization_id`, `group_id`,
/// `sport`, `family`, `formation`, `personnel`, `tags`, `version`,
/// `owner: OwnershipRecord`, `superseded_by`) — there is no
/// organization/team/auth layer in this prototype to hang those on. This
/// is a local-only, single-user play record; see CXP.15's DEV-PATH entry
/// for what's deliberately deferred.
library;

import 'play_frame.dart';

class SavedPlay {
  const SavedPlay({required this.id, required this.name, required this.frames, required this.createdAt});

  final String id;
  final String name;
  final List<PlayFrameData> frames;
  final DateTime createdAt;

  SavedPlay copyWith({String? name, List<PlayFrameData>? frames}) {
    return SavedPlay(
      id: id,
      name: name ?? this.name,
      frames: frames ?? this.frames,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'frames': [for (final frame in frames) frame.toJson()],
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedPlay.fromJson(Map<String, dynamic> json) {
    return SavedPlay(
      id: json['id'] as String,
      name: json['name'] as String,
      frames: [
        for (final frame in json['frames'] as List<dynamic>)
          PlayFrameData.fromJson(frame as Map<String, dynamic>),
      ],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Simple non-cryptographic id generator — sufficient for a local-only,
/// single-user prototype where ids never need to be unguessable or
/// globally unique across devices. Revisit once there's a real backend.
String generateLocalPlayId() {
  return '${DateTime.now().microsecondsSinceEpoch}';
}
