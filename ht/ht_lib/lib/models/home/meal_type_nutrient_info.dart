class MealTypeNutrientInfoSummary {
  List<MealTypeNutrientSummaries>? mealTypeNutrientSummaries;

  MealTypeNutrientInfoSummary({this.mealTypeNutrientSummaries});

  MealTypeNutrientInfoSummary.fromJson(Map<String, dynamic> json) {
    if (json['mealTypeNutrientSummaries'] != null) {
      mealTypeNutrientSummaries = <MealTypeNutrientSummaries>[];
      json['mealTypeNutrientSummaries'].forEach((v) {
        mealTypeNutrientSummaries!
            .add(new MealTypeNutrientSummaries.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.mealTypeNutrientSummaries != null) {
      data['mealTypeNutrientSummaries'] =
          this.mealTypeNutrientSummaries!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MealTypeNutrientSummaries {
  MealType? mealType;
  List<Nutrients>? nutrients;

  MealTypeNutrientSummaries({this.mealType, this.nutrients});

  MealTypeNutrientSummaries.fromJson(Map<String, dynamic> json) {
    mealType = json['mealType'] != null
        ? new MealType.fromJson(json['mealType'])
        : null;
    if (json['nutrients'] != null) {
      nutrients = <Nutrients>[];
      json['nutrients'].forEach((v) {
        nutrients!.add(new Nutrients.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.mealType != null) {
      data['mealType'] = this.mealType!.toJson();
    }
    if (this.nutrients != null) {
      data['nutrients'] = this.nutrients!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MealType {
  int? id;
  String? uuid;
  String? name;
  String? description;
  bool? active;
  String? createdBy;
  String? createdDate;
  String? lastModifiedBy;
  String? lastModifiedDate;
  Group? group;

  MealType(
      {this.id,
        this.uuid,
        this.name,
        this.description,
        this.active,
        this.createdBy,
        this.createdDate,
        this.lastModifiedBy,
        this.lastModifiedDate,
        this.group});

  MealType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    name = json['name'];
    description = json['description'];
    active = json['active'];
    createdBy = json['createdBy'];
    createdDate = json['createdDate'];
    lastModifiedBy = json['lastModifiedBy'];
    lastModifiedDate = json['lastModifiedDate'];
    group = json['group'] != null ? new Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['name'] = this.name;
    data['description'] = this.description;
    data['active'] = this.active;
    data['createdBy'] = this.createdBy;
    data['createdDate'] = this.createdDate;
    data['lastModifiedBy'] = this.lastModifiedBy;
    data['lastModifiedDate'] = this.lastModifiedDate;
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    return data;
  }
}

class Group {
  int? id;
  Null? uuid;
  Null? name;
  Null? description;
  Null? active;
  Null? createdBy;
  Null? createdDate;
  Null? lastModifiedBy;
  Null? lastModifiedDate;

  Group(
      {this.id,
        this.uuid,
        this.name,
        this.description,
        this.active,
        this.createdBy,
        this.createdDate,
        this.lastModifiedBy,
        this.lastModifiedDate});

  Group.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    uuid = json['uuid'];
    name = json['name'];
    description = json['description'];
    active = json['active'];
    createdBy = json['createdBy'];
    createdDate = json['createdDate'];
    lastModifiedBy = json['lastModifiedBy'];
    lastModifiedDate = json['lastModifiedDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['uuid'] = this.uuid;
    data['name'] = this.name;
    data['description'] = this.description;
    data['active'] = this.active;
    data['createdBy'] = this.createdBy;
    data['createdDate'] = this.createdDate;
    data['lastModifiedBy'] = this.lastModifiedBy;
    data['lastModifiedDate'] = this.lastModifiedDate;
    return data;
  }
}

class Nutrients {
  String? name;
  int? amount;
  int? minValue;
  int? maxValue;
  String? unitName;

  Nutrients(
      {this.name, this.amount, this.minValue, this.maxValue, this.unitName});

  Nutrients.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    amount = json['amount'];
    minValue = json['minValue'];
    maxValue = json['maxValue'];
    unitName = json['unitName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['amount'] = this.amount;
    data['minValue'] = this.minValue;
    data['maxValue'] = this.maxValue;
    data['unitName'] = this.unitName;
    return data;
  }
}