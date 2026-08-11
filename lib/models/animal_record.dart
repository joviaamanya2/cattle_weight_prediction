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
}
