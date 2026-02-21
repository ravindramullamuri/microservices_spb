import 'nutrient_response.dart';

/// Response model for /api/food-items/with-nutrients endpoint
class FoodItemWithNutrientsResponse {
  final List<FoodItemWithNutrientsItem> content;
  final Pageable pageable;
  final int totalElements;
  final int totalPages;

  FoodItemWithNutrientsResponse({
    required this.content,
    required this.pageable,
    required this.totalElements,
    required this.totalPages,
  });

  factory FoodItemWithNutrientsResponse.fromJson(Map<String, dynamic> json) {
    return FoodItemWithNutrientsResponse(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => FoodItemWithNutrientsItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pageable: json['pageable'] != null
          ? Pageable.fromJson(json['pageable'] as Map<String, dynamic>)
          : Pageable(pageNumber: 0, pageSize: 20),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((e) => e.toJson()).toList(),
      'pageable': pageable.toJson(),
      'totalElements': totalElements,
      'totalPages': totalPages,
    };
  }
}

/// Individual food item with nutrients
class FoodItemWithNutrientsItem {
  final int id;
  final String uuid;
  final int? fdcId;
  final String description;
  final String? brandName;

  // ⭐ NEW FIELDS
  final double? servingSize;
  final String? servingUnit;

  final List<Nutrient> nutrients;

  FoodItemWithNutrientsItem({
    required this.id,
    required this.uuid,
    this.fdcId,
    required this.description,
    this.brandName,
    this.servingSize,
    this.servingUnit,
    required this.nutrients,
  });

  factory FoodItemWithNutrientsItem.fromJson(Map<String, dynamic> json) {
    return FoodItemWithNutrientsItem(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      fdcId: json['fdcId'] != null ? (json['fdcId'] as num).toInt() : null,
      description: json['description'] ?? '',
      brandName: json['brandName'],

      // ⭐ NEW FIELDS
      servingSize: json['servingSize'] != null
          ? (json['servingSize'] as num).toDouble()
          : null,
      servingUnit: json['servingUnit'],

      nutrients: (json['nutrients'] as List<dynamic>?)
          ?.map((e) => Nutrient.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'fdcId': fdcId,
      'description': description,
      'brandName': brandName,

      // ⭐ NEW FIELDS
      'servingSize': servingSize,
      'servingUnit': servingUnit,

      'nutrients': nutrients.map((e) => e.toJson()).toList(),
    };
  }
}


/// Pageable information for pagination
class Pageable {
  final int pageNumber;
  final int pageSize;

  Pageable({
    required this.pageNumber,
    required this.pageSize,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json['pageNumber'] ?? 0,
      pageSize: json['pageSize'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    };
  }
}

