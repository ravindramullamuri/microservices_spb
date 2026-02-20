class MealTypeModel {
  final int id;
  final String? uuid;
  final String name;
  final String? description;

  MealTypeModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
  });

  factory MealTypeModel.fromJson(Map<String, dynamic> json) {
    return MealTypeModel(
      id: json['id'],
      uuid: json['uuid'],
      name: json['name'],
      description: json['description'],
    );
  }
}
