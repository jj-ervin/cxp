/// Basketball playing-surface configuration owned by the basketball sport
/// pack. Dimensions are stored in feet so rendering stays independent of the
/// user's display units and canvas size.
library;

enum CourtStandard { nba, ncaa, highSchool, middleSchool, fiba, custom }

enum CourtExtent { half, full }

enum CourtSurface { hardwood, blacktop }

class CourtDimensions {
  const CourtDimensions({
    required this.lengthFeet,
    required this.widthFeet,
    required this.laneWidthFeet,
    required this.freeThrowLineFeet,
    required this.threePointRadiusFeet,
    required this.cornerThreeDistanceFeet,
    required this.basketOffsetFeet,
    required this.restrictedArcRadiusFeet,
  });

  final double lengthFeet;
  final double widthFeet;
  final double laneWidthFeet;
  final double freeThrowLineFeet;
  final double threePointRadiusFeet;
  final double cornerThreeDistanceFeet;
  final double basketOffsetFeet;
  final double restrictedArcRadiusFeet;

  Map<String, dynamic> toJson() => {
    'lengthFeet': lengthFeet,
    'widthFeet': widthFeet,
    'laneWidthFeet': laneWidthFeet,
    'freeThrowLineFeet': freeThrowLineFeet,
    'threePointRadiusFeet': threePointRadiusFeet,
    'cornerThreeDistanceFeet': cornerThreeDistanceFeet,
    'basketOffsetFeet': basketOffsetFeet,
    'restrictedArcRadiusFeet': restrictedArcRadiusFeet,
  };

  factory CourtDimensions.fromJson(Map<String, dynamic> json) => CourtDimensions(
    lengthFeet: (json['lengthFeet'] as num).toDouble(),
    widthFeet: (json['widthFeet'] as num).toDouble(),
    laneWidthFeet: (json['laneWidthFeet'] as num).toDouble(),
    freeThrowLineFeet: (json['freeThrowLineFeet'] as num).toDouble(),
    threePointRadiusFeet: (json['threePointRadiusFeet'] as num).toDouble(),
    cornerThreeDistanceFeet: (json['cornerThreeDistanceFeet'] as num).toDouble(),
    basketOffsetFeet: (json['basketOffsetFeet'] as num).toDouble(),
    restrictedArcRadiusFeet: (json['restrictedArcRadiusFeet'] as num).toDouble(),
  );
}

class CourtConfiguration {
  const CourtConfiguration({
    required this.standard,
    this.extent = CourtExtent.half,
    this.surface = CourtSurface.hardwood,
    this.customDimensions,
  });

  static const defaultValue = CourtConfiguration(standard: CourtStandard.nba);

  final CourtStandard standard;
  final CourtExtent extent;
  final CourtSurface surface;
  final CourtDimensions? customDimensions;

  CourtDimensions get dimensions => customDimensions ?? dimensionsFor(standard);

  double get displayedLengthFeet => extent == CourtExtent.full ? dimensions.lengthFeet : dimensions.lengthFeet / 2;

  CourtConfiguration copyWith({
    CourtStandard? standard,
    CourtExtent? extent,
    CourtSurface? surface,
    CourtDimensions? customDimensions,
    bool clearCustomDimensions = false,
  }) {
    return CourtConfiguration(
      standard: standard ?? this.standard,
      extent: extent ?? this.extent,
      surface: surface ?? this.surface,
      customDimensions: clearCustomDimensions ? null : customDimensions ?? this.customDimensions,
    );
  }

  Map<String, dynamic> toJson() => {
    'standard': standard.name,
    'extent': extent.name,
    'surface': surface.name,
    if (customDimensions != null) 'customDimensions': customDimensions!.toJson(),
  };

  factory CourtConfiguration.fromJson(Map<String, dynamic> json) => CourtConfiguration(
    standard: CourtStandard.values.byName(json['standard'] as String),
    extent: CourtExtent.values.byName(json['extent'] as String? ?? CourtExtent.half.name),
    surface: CourtSurface.values.byName(json['surface'] as String? ?? CourtSurface.hardwood.name),
    customDimensions: json['customDimensions'] == null
        ? null
        : CourtDimensions.fromJson(json['customDimensions'] as Map<String, dynamic>),
  );
}

CourtDimensions dimensionsFor(CourtStandard standard) {
  switch (standard) {
    case CourtStandard.nba:
      return const CourtDimensions(
        lengthFeet: 94,
        widthFeet: 50,
        laneWidthFeet: 16,
        freeThrowLineFeet: 19,
        threePointRadiusFeet: 23.75,
        cornerThreeDistanceFeet: 22,
        basketOffsetFeet: 5.25,
        restrictedArcRadiusFeet: 4,
      );
    case CourtStandard.ncaa:
      return const CourtDimensions(
        lengthFeet: 94,
        widthFeet: 50,
        laneWidthFeet: 12,
        freeThrowLineFeet: 19,
        threePointRadiusFeet: 22.1458,
        cornerThreeDistanceFeet: 22.1458,
        basketOffsetFeet: 5.25,
        restrictedArcRadiusFeet: 4,
      );
    case CourtStandard.highSchool:
      return const CourtDimensions(
        lengthFeet: 84,
        widthFeet: 50,
        laneWidthFeet: 12,
        freeThrowLineFeet: 19,
        threePointRadiusFeet: 19.75,
        cornerThreeDistanceFeet: 19.75,
        basketOffsetFeet: 5.25,
        restrictedArcRadiusFeet: 0,
      );
    case CourtStandard.middleSchool:
      return const CourtDimensions(
        lengthFeet: 74,
        widthFeet: 42,
        laneWidthFeet: 12,
        freeThrowLineFeet: 19,
        threePointRadiusFeet: 19.75,
        cornerThreeDistanceFeet: 19.75,
        basketOffsetFeet: 5.25,
        restrictedArcRadiusFeet: 0,
      );
    case CourtStandard.fiba:
      return const CourtDimensions(
        lengthFeet: 91.86,
        widthFeet: 49.21,
        laneWidthFeet: 16.08,
        freeThrowLineFeet: 18.96,
        threePointRadiusFeet: 22.15,
        cornerThreeDistanceFeet: 21.65,
        basketOffsetFeet: 5.17,
        restrictedArcRadiusFeet: 4.1,
      );
    case CourtStandard.custom:
      return dimensionsFor(CourtStandard.nba);
  }
}

extension CourtStandardLabel on CourtStandard {
  String get label => switch (this) {
    CourtStandard.nba => 'NBA',
    CourtStandard.ncaa => 'NCAA',
    CourtStandard.highSchool => 'High school',
    CourtStandard.middleSchool => 'Middle school',
    CourtStandard.fiba => 'FIBA / European',
    CourtStandard.custom => 'Custom',
  };
}

extension CourtExtentLabel on CourtExtent {
  String get label => this == CourtExtent.half ? 'Half court' : 'Full court';
}

extension CourtSurfaceLabel on CourtSurface {
  String get label => this == CourtSurface.hardwood ? 'Indoor hardwood' : 'Outdoor blacktop';
}
