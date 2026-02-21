import 'nutrients_model.dart';
/// =======================
/// MODELS 1
/// =======================
class FoodLogPageResponse {
  final List<FoodLogEntry> content;
  final Pageable? pageable;
  final int? totalElements;
  final int? totalPages;
  final bool? last;
  final int? size;
  final int? number;
  final Sort? sort;
  final bool? first;
  final int? numberOfElements;
  final bool? empty;

  FoodLogPageResponse({
    required this.content,
    this.pageable,
    this.totalElements,
    this.totalPages,
    this.last,
    this.size,
    this.number,
    this.sort,
    this.first,
    this.numberOfElements,
    this.empty,
  });

  factory FoodLogPageResponse.fromJson(Map<String, dynamic> json) {
    return FoodLogPageResponse(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => FoodLogEntry.fromJson(e))
          .toList(),
      pageable:
      json['pageable'] != null ? Pageable.fromJson(json['pageable']) : null,
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
      last: json['last'],
      size: json['size'],
      number: json['number'],
      sort: json['sort'] != null ? Sort.fromJson(json['sort']) : null,
      first: json['first'],
      numberOfElements: json['numberOfElements'],
      empty: json['empty'],
    );
  }
}


class FoodLogEntry {
  final int? id;
  final String? uuid;
  final String? logDate;
  final String? quantity;
  final MealType? mealType;
  final FoodItemWithNutrients? foodItemWithNutrients;
  final List<ActualNutrientIntake> actualNutrientIntakes;

  FoodLogEntry({
    this.id,
    this.uuid,
    this.logDate,
    this.quantity,
    this.mealType,
    this.foodItemWithNutrients,
    required this.actualNutrientIntakes,
  });

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    return FoodLogEntry(
      id: json['id'],
      uuid: json['uuid'],
      logDate: json['logDate'],
      quantity: json['quantity'],
      mealType: json['mealType'] != null
          ? MealType.fromJson(json['mealType'])
          : null,
      foodItemWithNutrients: json['foodItemWithNutrients'] != null
          ? FoodItemWithNutrients.fromJson(json['foodItemWithNutrients'])
          : null,
      actualNutrientIntakes:
      (json['actualNutrientIntakes'] as List<dynamic>? ?? [])
          .map((e) => ActualNutrientIntake.fromJson(e))
          .toList(),
    );
  }
}


class MealType {
  final int? id;
  final String? uuid;
  final String? name;
  final String? description;

  MealType({
    this.id,
    this.uuid,
    this.name,
    this.description,
  });

  factory MealType.fromJson(Map<String, dynamic> json) {
    return MealType(
      id: json['id'],
      uuid: json['uuid'],
      name: json['name'],
      description: json['description'],
    );
  }
}


class FoodItemWithNutrients {
  final int? id;
  final String? uuid;
  final int? fdcId;
  final String? description;
  final String? brandName;
  final double? servingSize;
  final String? servingUnit;
  final List<Nutrients> nutrients;

  FoodItemWithNutrients({
    this.id,
    this.uuid,
    this.fdcId,
    this.description,
    this.brandName,
    this.servingSize,
    this.servingUnit,
    required this.nutrients,
  });

  factory FoodItemWithNutrients.fromJson(Map<String, dynamic> json) {
    return FoodItemWithNutrients(
      id: json['id'],
      uuid: json['uuid'],
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,
      description: json['description'],
      brandName: json['brandName'],
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 0.0,
      servingUnit: json['servingUnit'],
      nutrients: (json['nutrients'] as List<dynamic>? ?? [])
          .map((e) => Nutrients.fromJson(e))
          .toList(),
    );
  }
}



class ActualNutrientIntake {
  final int? id;
  final String? nutrientName;
  final double? quantity;
  final String? unitType;

  ActualNutrientIntake({
    this.id,
    this.nutrientName,
    this.quantity,
    this.unitType,
  });

  factory ActualNutrientIntake.fromJson(Map<String, dynamic> json) {
    return ActualNutrientIntake(
      id: json['id'],
      nutrientName: json['nutrientName'],
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitType: json['unitType'],
    );
  }
}
class Pageable {
  final int? pageNumber;
  final int? pageSize;
  final Sort? sort;
  final int? offset;
  final bool? paged;
  final bool? unpaged;

  Pageable({
    this.pageNumber,
    this.pageSize,
    this.sort,
    this.offset,
    this.paged,
    this.unpaged,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
      sort: json['sort'] != null ? Sort.fromJson(json['sort']) : null,
      offset: json['offset'],
      paged: json['paged'],
      unpaged: json['unpaged'],
    );
  }
}
class Sort {
  final bool? sorted;
  final bool? unsorted;
  final bool? empty;

  Sort({
    this.sorted,
    this.unsorted,
    this.empty,
  });

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      sorted: json['sorted'],
      unsorted: json['unsorted'],
      empty: json['empty'],
    );
  }
}
