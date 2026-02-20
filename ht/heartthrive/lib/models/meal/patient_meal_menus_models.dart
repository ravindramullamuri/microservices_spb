
// Patient Meal Menus Models (Option 1 - Reusing Existing Models)

import 'package:heart_thrive/models/meal/food_item_with_nutrients.dart';
import 'package:heart_thrive/models/meal/meal_type_model.dart';

class PatientMealMenusResponse {
  final List<PatientMealMenuModel> content;
  final Pageable pageable;
  final int totalElements;
  final int totalPages;
  final bool last;
  final int size;
  final int number;
  final Sort sort;
  final int numberOfElements;
  final bool first;
  final bool empty;

  PatientMealMenusResponse({
    required this.content,
    required this.pageable,
    required this.totalElements,
    required this.totalPages,
    required this.last,
    required this.size,
    required this.number,
    required this.sort,
    required this.numberOfElements,
    required this.first,
    required this.empty,
  });

  factory PatientMealMenusResponse.fromJson(Map<String, dynamic> json) {
    return PatientMealMenusResponse(
      content: (json['content'] as List<dynamic>)
          .map((e) => PatientMealMenuModel.fromJson(e))
          .toList(),
      pageable: Pageable.fromJson(json['pageable']),
      totalElements: json['totalElements'],
      totalPages: json['totalPages'],
      last: json['last'],
      size: json['size'],
      number: json['number'],
      sort: Sort.fromJson(json['sort']),
      numberOfElements: json['numberOfElements'],
      first: json['first'],
      empty: json['empty'],
    );
  }
}

class PatientMealMenuModel {
  final int id;
  final String uuid;
  final String name;
  final bool active;
  final String createdBy;
  final String createdDate;
  final String lastModifiedBy;
  final String lastModifiedDate;
  final PatientModel patient;
  final MealTypeModel mealType;
  final String latestQuantity;
  final FoodItemWithNutrients latestFoodItemWithNutrients;

  PatientMealMenuModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.active,
    required this.createdBy,
    required this.createdDate,
    required this.lastModifiedBy,
    required this.lastModifiedDate,
    required this.patient,
    required this.mealType,
    required this.latestQuantity,
    required this.latestFoodItemWithNutrients,
  });

  factory PatientMealMenuModel.fromJson(Map<String, dynamic> json) {
    return PatientMealMenuModel(
      id: json['id'],
      uuid: json['uuid'] ?? "",
      name: json['name'] ?? "",
      active: json['active'] ?? false,
      createdBy: json['createdBy'] ?? "",
      createdDate: json['createdDate'] ?? "",
      lastModifiedBy: json['lastModifiedBy'] ?? "",
      lastModifiedDate: json['lastModifiedDate'] ?? "",
      patient: PatientModel.fromJson(json['patient']),
      mealType: MealTypeModel.fromJson(json['mealType']),
      latestQuantity: json['latestQuantity'] ?? "",
      latestFoodItemWithNutrients:
      FoodItemWithNutrients.fromJson(json['latestFoodItemWithNutrients']),
    );
  }
}

class PatientModel {
  final int id;
  final String login;
  final String firstName;
  final String lastName;
  final String email;

  PatientModel({
    required this.id,
    required this.login,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    return PatientModel(
      id: json['id'],
      login: json['login'] ?? "",
      firstName: json['firstName'] ?? "",
      lastName: json['lastName'] ?? "",
      email: json['email'] ?? "",
    );
  }
}

class Pageable {
  final int pageNumber;
  final int pageSize;
  final int offset;
  final bool paged;
  final bool unpaged;
  final Sort sort;

  Pageable({
    required this.pageNumber,
    required this.pageSize,
    required this.offset,
    required this.paged,
    required this.unpaged,
    required this.sort,
  });

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      pageNumber: json['pageNumber'],
      pageSize: json['pageSize'],
      offset: json['offset'],
      paged: json['paged'],
      unpaged: json['unpaged'],
      sort: Sort.fromJson(json['sort']),
    );
  }
}

class Sort {
  final bool sorted;
  final bool unsorted;
  final bool empty;

  Sort({
    required this.sorted,
    required this.unsorted,
    required this.empty,
  });

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      sorted: json['sorted'],
      unsorted: json['unsorted'],
      empty: json['empty'],
    );
  }
}
