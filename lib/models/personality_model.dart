class PersonalityModel {
  final int? id;
  final String name;
  final String tone;
  final String behaviorJson; // JSON string with personality parameters

  PersonalityModel({
    this.id,
    required this.name,
    required this.tone,
    required this.behaviorJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'tone': tone,
      'behavior_json': behaviorJson,
    };
  }

  factory PersonalityModel.fromMap(Map<String, dynamic> map) {
    return PersonalityModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      tone: map['tone'] as String,
      behaviorJson: map['behavior_json'] as String,
    );
  }

  static List<PersonalityModel> defaultPersonalities() {
    return [
      PersonalityModel(
        id: 1,
        name: 'Caring',
        tone: 'caring',
        behaviorJson:
            '{"strictness":0.2,"playfulness":0.3,"mentoring":0.7,"warmth":0.9,"message_length":"short","voice_speed":0.9,"voice_pitch":1.0}',
      ),
      PersonalityModel(
        id: 2,
        name: 'Strict',
        tone: 'strict',
        behaviorJson:
            '{"strictness":0.9,"playfulness":0.1,"mentoring":0.8,"warmth":0.4,"message_length":"short","voice_speed":1.0,"voice_pitch":0.9}',
      ),
      PersonalityModel(
        id: 3,
        name: 'Playful',
        tone: 'playful',
        behaviorJson:
            '{"strictness":0.1,"playfulness":0.9,"mentoring":0.4,"warmth":0.7,"message_length":"medium","voice_speed":1.1,"voice_pitch":1.1}',
      ),
      PersonalityModel(
        id: 4,
        name: 'Motivational',
        tone: 'motivational',
        behaviorJson:
            '{"strictness":0.5,"playfulness":0.4,"mentoring":0.9,"warmth":0.6,"message_length":"medium","voice_speed":1.0,"voice_pitch":1.0}',
      ),
    ];
  }
}
