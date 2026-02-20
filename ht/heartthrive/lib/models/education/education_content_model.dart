enum EducationCategory {
  diet,
  lifestyle,
  medications,
  diseaseManagement,
  all,
}

extension EducationCategoryExtension on EducationCategory {
  String get displayName {
    switch (this) {
      case EducationCategory.diet:
        return 'Diet';
      case EducationCategory.lifestyle:
        return 'Lifestyle';
      case EducationCategory.medications:
        return 'Medications';
      case EducationCategory.diseaseManagement:
        return 'Disease Management';
      case EducationCategory.all:
        return 'All';
    }
  }

  String get icon {
    switch (this) {
      case EducationCategory.diet:
        return '🍎';
      case EducationCategory.lifestyle:
        return '🏃';
      case EducationCategory.medications:
        return '💊';
      case EducationCategory.diseaseManagement:
        return '❤️';
      case EducationCategory.all:
        return '📚';
    }
  }
}

class EducationContent {
  final String id;
  final String title;
  final String description;
  final String content; // Full article content
  final EducationCategory category;
  final String? imagePath; // Path to infographic/image
  final int readTime; // Read time in minutes
  final List<String> tags; // Keywords for search
  final bool hasInfographic; // Whether content includes visual/infographic
  final DateTime? publishedDate;
  final String? author;

  EducationContent({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.category,
    this.imagePath,
    required this.readTime,
    this.tags = const [],
    this.hasInfographic = false,
    this.publishedDate,
    this.author,
  });

  // Factory constructor for creating from JSON (if needed for API integration)
  factory EducationContent.fromJson(Map<String, dynamic> json) {
    return EducationContent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      category: _categoryFromString(json['category'] ?? 'all'),
      imagePath: json['imagePath'],
      readTime: json['readTime'] ?? 5,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      hasInfographic: json['hasInfographic'] ?? false,
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'])
          : null,
      author: json['author'],
    );
  }

  // Convert to JSON (if needed for API integration)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'category': category.name,
      'imagePath': imagePath,
      'readTime': readTime,
      'tags': tags,
      'hasInfographic': hasInfographic,
      'publishedDate': publishedDate?.toIso8601String(),
      'author': author,
    };
  }

  // Helper method to convert string to category
  static EducationCategory _categoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'diet':
        return EducationCategory.diet;
      case 'lifestyle':
        return EducationCategory.lifestyle;
      case 'medications':
        return EducationCategory.medications;
      case 'diseasemanagement':
      case 'disease_management':
        return EducationCategory.diseaseManagement;
      default:
        return EducationCategory.all;
    }
  }

  // Check if content matches search query
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return title.toLowerCase().contains(lowerQuery) ||
        description.toLowerCase().contains(lowerQuery) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
        content.toLowerCase().contains(lowerQuery);
  }
}

