class AnimalRecord {
  AnimalRecord({
    required this.id,
    required this.name,
    required this.earTag,
    required this.breed,
    required this.sex,
    required this.ageMonths,
    required this.dateOfBirth,
    required this.farm,
    required this.owner,
    required this.healthNotes,
    required this.imagePaths,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String earTag;
  final String breed;
  final String sex;
  final int ageMonths;
  final DateTime? dateOfBirth;
  final String farm;
  final String owner;
  final String healthNotes;
  final List<String> imagePaths;
  final DateTime createdAt;

  factory AnimalRecord.fromJson(Map<String, dynamic> json) {
    return AnimalRecord(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      earTag: json['ear_tag']?.toString() ?? '',
      breed: json['breed']?.toString() ?? '',
      sex: json['sex']?.toString() ?? '',
      ageMonths: (json['age_months'] as num?)?.toInt() ?? 0,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(
              json['date_of_birth'].toString(),
            )
          : null,
      farm: json['farm']?.toString() ?? '',
      owner: json['owner']?.toString() ?? '',
      healthNotes: json['health_notes']?.toString() ?? '',
      imagePaths: json['image_paths'] != null
          ? List<String>.from(json['image_paths'])
          : [],
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ear_tag': earTag,
      'breed': breed,
      'sex': sex,
      'age_months': ageMonths,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'farm': farm,
      'owner': owner,
      'health_notes': healthNotes,
      'image_paths': imagePaths,
      'created_at': createdAt.toIso8601String(),
    };
  }
}