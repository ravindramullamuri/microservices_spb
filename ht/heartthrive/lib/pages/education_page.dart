import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/components/profile_avatar.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:http/http.dart' as http;


import '../constants/heart_thrive_strings_constants.dart';
import '../models/education/education_content_model.dart';
import '../providers/user/user_details_provider.dart';
import '../routes/app_router.dart';
import '../theme/app_theme.dart';
import 'notification_badgeicon_widget.dart';

class EducationPage extends ConsumerStatefulWidget {
  final String? navFromPage;
  const EducationPage({Key? key,this.navFromPage}) : super(key: key);

  @override
  ConsumerState<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends ConsumerState<EducationPage> {
  final TextEditingController _searchController = TextEditingController();
  EducationCategory _selectedCategory = EducationCategory.all;
  List<EducationContent> _filteredContent = [];
  List<EducationContent> _allContent = [];
  bool _isLoading = false;
  String? _errorMessage;
  static final List<EducationContent> _fallbackContent = _initializeStaticArticles();
  @override
  void initState() {
    super.initState();
    _filteredContent = _allContent;
    // Add static articles to all content
    _allContent.addAll(_fallbackContent);
    _fetchEducationContent(category: _selectedCategory);
    _searchController.addListener(_filterContent);
  }

  static List<EducationContent> _initializeStaticArticles() {
    return [

      // Article 11: How Heart Thrive Helps You
      EducationContent(
        id: 'offline-heart-thrive-help',
        title: 'How Heart Thrive Helps You',
        description: 'Heart Thrive is your personal health companion designed to support you in managing heart failure with easy-to-use tools and educational resources.',
        content: '''Heart Thrive is here to support you by helping you:
• Track daily weights
• Monitor sodium intake
• Remember medications
• Log symptoms
• Learn about heart failure in simple terms

You are not alone. Managing heart failure is a team effort—and Heart Thrive is part of your team.

Our goal: Encourage you to remain engaged and in control of your health!''',
        category: EducationCategory.all,
        imagePath: 'lib/assets/education/Education-11.jpg',
        readTime: 2,
        tags: ['Heart Thrive', 'app features', 'support', 'health management'],
        hasInfographic: false,
      ),


      // Article 1: What Is Heart Failure?
      EducationContent(
        id: 'offline-heart-failure-basics',
        title: 'What Is Heart Failure?',
        description: 'Heart failure means your heart is weaker or stiffer than normal and cannot pump blood as well as your body needs.',
        content: '''Because of this, blood and fluid can back up in your body. This can cause:
• Shortness of breath
• Swelling in the legs, feet, or belly
• Feeling tired or weak

This happens because your organs need oxygen and nutrients from blood. When the heart cannot keep up, symptoms start to appear.''',
        category: EducationCategory.diseaseManagement,
        imagePath: 'lib/assets/education/Education-1.jpg',
        readTime: 3,
        tags: ['heart failure', 'symptoms', 'heart health', 'disease management'],
        hasInfographic: false,
      ),

      // Article 2: What Does It Mean to Live with Heart Failure?
      EducationContent(
        id: 'offline-living-with-heart-failure',
        title: 'What Does It Mean to Live with Heart Failure?',
        description: 'Heart failure is a long-term condition, but many people live full lives with the right care.',
        content: '''Thriving with heart failure means:
• Taking medications every day
• Watching your weight and salt (sodium) intake
• Staying active in safe ways
• Paying attention to symptoms

Small daily choices can prevent heart failure symptoms!''',
        category: EducationCategory.diseaseManagement,
        imagePath: 'lib/assets/education/Education-2.jpg',
        readTime: 2,
        tags: ['heart failure', 'lifestyle', 'management', 'living well'],
        hasInfographic: false,
      ),

      // Article 3: Understanding Ejection Fraction (EF)
      EducationContent(
        id: 'offline-ejection-fraction',
        title: 'Understanding Ejection Fraction (EF)',
        description: 'Ejection Fraction is a number that shows how well your heart pumps blood.',
        content: '''• Normal EF: 50–70%
• Reduced EF (HFrEF): The heart pumps out less blood than normal
• Preserved EF (HFpEF): The heart pumps okay, but it is stiff and does not fill well resulting in less blood going out of the heart

You can have symptoms with both types.

Knowing your EF helps your care team choose the best medications and treatments for you.''',
        category: EducationCategory.diseaseManagement,
        imagePath: 'lib/assets/education/Education-3.jpg',
        readTime: 3,
        tags: ['ejection fraction', 'HFrEF', 'HFpEF', 'heart function', 'diagnosis'],
        hasInfographic: false,
      ),

      // Article 4: Why Taking Your Medications Matters
      EducationContent(
        id: 'offline-medications-matter',
        title: 'Why Taking Your Medications Matters',
        description: 'Taking your heart failure medications as prescribed is essential for managing your condition and preventing complications.',
        content: '''Heart failure medications help to:
• Make the heart pump better
• Lower blood pressure
• Remove extra fluid
• Protect the heart from getting weaker

These medicines work best when taken every day, even if you feel okay.

Skipping doses can lead to fluid buildup, worsening symptoms, and hospital visits.

Tip: Take medications at the same time each day and use a pill box or reminders.''',
        category: EducationCategory.medications,
        imagePath: 'lib/assets/education/Education-4.jpg',
        readTime: 3,
        tags: ['medications', 'adherence', 'heart failure', 'treatment'],
        hasInfographic: false,
      ),

      // Article 5: Why You Should Weigh Yourself Every Day
      EducationContent(
        id: 'offline-daily-weight',
        title: 'Why You Should Weigh Yourself Every Day',
        description: 'Daily weights help catch fluid buildup early before symptoms appear.',
        content: '''• Weigh yourself every morning
• Use the same scale
• Wear similar clothing
• Document the number in Heart Thrive

Weight gain can mean fluid buildup before you feel symptoms.''',
        category: EducationCategory.lifestyle,
        imagePath: 'lib/assets/education/Education-5.jpg',
        readTime: 2,
        tags: ['weight', 'monitoring', 'fluid buildup', 'daily tracking'],
        hasInfographic: false,
      ),

      // Article 6: Why Watching Sodium (Salt) Is Important
      EducationContent(
        id: 'offline-sodium-importance',
        title: 'Why Watching Sodium (Salt) Is Important',
        description: 'Sodium can make your body hold onto water, which can lead to symptoms',
        content: '''Too much sodium can cause:
• Swelling
• Shortness of breath
• Weight gain due to excess fluid buildup

Less sodium means less fluid stress on your heart.

Tips:
• Avoid processed and packaged foods
• Read food labels
• Choose fresh foods when possible
• Use the Heart Thrive nutrition database to log food!''',
        category: EducationCategory.diet,
        imagePath: 'lib/assets/education/Education-6.jpg',
        readTime: 3,
        tags: ['sodium', 'salt', 'diet', 'nutrition', 'fluid management'],
        hasInfographic: false,
      ),

      // Article 7: The Importance of Exercise
      EducationContent(
        id: 'offline-exercise-importance',
        title: 'The Importance of Exercise',
        description: 'Regular physical activity is a key component of heart failure management and can improve your overall quality of life.',
        content: '''Exercise helps your:
• Heart work more efficiently
• Muscles stay strong
• Energy and mood improve

Safe activities may include:
• Walking
• Light strength training
• Swimming
• Stretching

A stronger body helps your heart do less work.

Tip: Start slow and increase gradually. Always follow your care team's advice. Join a local gym, exercise with friends, join a fitness class''',
        category: EducationCategory.lifestyle,
        imagePath: 'lib/assets/education/Education-7.jpg',
        readTime: 3,
        tags: ['exercise', 'physical activity', 'fitness', 'lifestyle'],
        hasInfographic: false,
      ),

      // Article 8: Eating Healthy With Heart Failure
      EducationContent(
        id: 'offline-healthy-eating',
        title: 'Eating Healthy With Heart Failure',
        description: 'Healthy eating plays an important role in protecting your heart and managing heart failure. Choosing nutrient-rich foods can help control blood pressure, reduce fluid buildup, and support overall heart function. Aim to build your meals around plenty of fruits and vegetables, lean sources of protein like fish, chicken, or beans, whole grains for lasting energy, and foods that are low in sodium to help prevent swelling and shortness of breath.',
        content: '''Focus on:
• Fruits and vegetables
• Lean proteins (fish, chicken, beans)
• Whole grains
• Low-sodium foods

Good nutrition reduces inflammation, controls weight, and supports heart function.''',
        category: EducationCategory.diet,
        imagePath: 'lib/assets/education/Education-8.jpg',
        readTime: 3,
        tags: ['nutrition', 'healthy eating', 'diet', 'heart health'],
        hasInfographic: false,
      ),

      // Article 9: Watching for Symptoms
      EducationContent(
        id: 'offline-symptom-watching',
        title: 'Watching for Symptoms',
        description: 'Paying attention to how your body feels each day can help you stay ahead of heart failure symptoms. Be aware symptoms such as: shortness of breath, swelling in your legs, feet, or belly, sudden weight gain, feeling unusually tired, or chest discomfort as this can be early warning signs that your heart is under stress. Recognizing these changes early and taking action can help prevent symptoms from becoming serious and may reduce the chance of an emergency.',
        content: '''Watch for:
• Shortness of breath
• Swelling in legs, feet, or belly
• Sudden weight gain
• Fatigue
• Chest discomfort

Catching symptoms early may prevent emergencies.''',
        category: EducationCategory.diseaseManagement,
        imagePath: 'lib/assets/education/Education-9.jpg',
        readTime: 2,
        tags: ['symptoms', 'monitoring', 'early detection', 'heart failure'],
        hasInfographic: false,
      ),

      // Article 10: Making Lifestyle Changes (One Step at a Time)
      EducationContent(
        id: 'offline-lifestyle-changes',
        title: 'Making Lifestyle Changes (One Step at a Time)',
        description: 'You don’t have to change everything today. Start small and stay consistent. Pick one goal and focus on it—every win counts. Build simple routines, use reminders, and lean on the people who support you. Heart Thrive has your back, helping you stay focused, track your progress, and turn your goals into real results. Keep showing up. Small steps taken every day can lead to powerful, lasting change.',
        content: '''Helpful tips:
• Pick one goal at a time
• Celebrate small wins
• Ask for help from family or friends
• Use reminders and routines

Small daily habits lead to big long-term improvements.''',
        category: EducationCategory.lifestyle,
        imagePath: 'lib/assets/education/Education-10.jpg',
        readTime: 2,
        tags: ['lifestyle', 'change', 'goals', 'habits', 'motivation'],
        hasInfographic: false,
      ),

    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _shouldExcludeArticle(String title) {
    final lowerTitle = title.toLowerCase();
    final excludedKeywords = [
      'folic acid',
      'calcium',
      'child stay at healthy weight',
      'child stay at a healthy weight',
      'help child stay',
      'child healthy weight',
      'calcium shopping list',
      'healthy snacks',
      'tips for parents',
      'anxiety',
    ];

    return excludedKeywords.any((keyword) => lowerTitle.contains(keyword));
  }



  void _filterContent() {
    setState(() {
      final query = _searchController.text.toLowerCase();

      _filteredContent = _allContent.where((content) {
        final matchesCategory = _selectedCategory == EducationCategory.all ||
            content.category == _selectedCategory;
        final matchesSearch = query.isEmpty || content.matchesSearch(query);
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }
  List<EducationContent> _getStaticContent() {

    final query = _searchController.text.toLowerCase();

    return _fallbackContent.where((content) {

      final matchesCategory = _selectedCategory == EducationCategory.all ||

          content.category == _selectedCategory;

      final matchesSearch = query.isEmpty || content.matchesSearch(query);

      return matchesCategory && matchesSearch;

    }).toList();

  }



  List<EducationContent> _getFetchedContent() {

    return _filteredContent.where((content) => !_isStaticContent(content)).toList();

  }
  Future<void> _fetchEducationContent({required EducationCategory category}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    bool shouldTryCdc = category == EducationCategory.all;

    if (shouldTryCdc) {
      try {
        final cdcContent = await _fetchCdcContent();
        setState(() {
          final staticArticles = _allContent.where((content) => _isStaticContent(content)).toList();

          _allContent = [

            ...staticArticles,

            ...cdcContent.where((content) =>

            !_shouldExcludeArticle(content.title)

            ).toList(),

          ];
        });
        _filterContent();
        return;
      } catch (cdcError, cdcStack) {
        debugPrint('CDC content fetch failed: $cdcError');
        debugPrintStack(stackTrace: cdcStack);
      }
    }

    try {
      final myHealthfinderContent =
      await _fetchMyHealthfinderContent(category: category);
      setState(() {
        final staticArticles = _allContent.where((content) => _isStaticContent(content)).toList();

        _allContent = [

          ...staticArticles,

          ...myHealthfinderContent.where((content) =>

          !_shouldExcludeArticle(content.title)

          ).toList(),

        ];
      });
      _filterContent();
    } catch (error, stackTrace) {
      debugPrint('Education content fetch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (category == EducationCategory.all) {
        _useFallbackContent(
          message:
          'Showing saved education tips while we reconnect. Pull to refresh anytime.',
        );
      } else {
        setState(() {
          _errorMessage =
          'Unable to load ${category.displayName} tips right now. Pull to refresh to try again.';
          _allContent = [];
          _filteredContent = [];
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<EducationContent>> _fetchCdcContent() async {
    final uri = Uri.parse(
        'https://tools.cdc.gov/api/v2/resources/media?topic=Heart%20Disease&format=json&max=25&sort=MostRecent&fullText=true');

    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'HeartThriveApp/1.0',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('CDC API failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    final rawResults = decoded['results'];

    // FIXED — Normalize to List
    List<dynamic> results;
    if (rawResults is List) {
      results = rawResults;
    } else if (rawResults is Map<String, dynamic>) {
      results = [rawResults];
    } else {
      results = [];
    }

    final fetchedContent = results
        .whereType<Map<String, dynamic>>()
        .map(_mapCdcResourceToContent)
        .whereType<EducationContent>()
        .toList();

    if (fetchedContent.isEmpty) {
      throw Exception('CDC API returned no usable content');
    }

    return fetchedContent;
  }


  Future<List<EducationContent>> _fetchMyHealthfinderContent({
    required EducationCategory category,
  }) async {
    final queryParams = _buildMyHealthfinderQuery(category);
    final uri = Uri.https(
      'health.gov',
      '/myhealthfinder/api/v4/topicsearch.json',
      queryParams,
    );
    final response = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'HeartThriveApp/1.0 (https://example.com)',
      },
    ).timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('MyHealthfinder API failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final result =
    (decoded['Result'] ?? decoded['result']) as Map<String, dynamic>?;
    final resourcesWrapper = (result?['Resources'] ?? result?['resources'])
    as Map<String, dynamic>?;
    final resources =
        resourcesWrapper?['Resource'] ?? resourcesWrapper?['resource'];

    if (resources == null) {
      throw Exception('No resources found');
    }

    final List<dynamic> resourceList =
    resources is List ? resources : [resources];

    final fetchedContent = resourceList
        .whereType<Map<String, dynamic>>()
        .map(_mapMyHealthfinderResourceToContent)
        .where((content) => content != null)
        .cast<EducationContent>()
        .toList();

    if (fetchedContent.isEmpty) {
      throw Exception('No education content returned');
    }

    return fetchedContent;
  }

  Map<String, String> _buildMyHealthfinderQuery(EducationCategory category) {
    final base = <String, String>{
      'returnType': 'json',
      'lang': 'en',
    };
    base.addAll(_myHealthfinderQueryByCategory(category));
    return base;
  }

  Map<String, String> _myHealthfinderQueryByCategory(
      EducationCategory category) {
    switch (category) {
      case EducationCategory.diet:
        return {'keyword': 'nutrition'};
      case EducationCategory.lifestyle:
        return {'keyword': 'physical activity'};
      case EducationCategory.medications:
        return {'keyword': 'medication'};
      case EducationCategory.diseaseManagement:
        return {'keyword': 'heart disease'};
      case EducationCategory.all:
        return {'categoryId': '21'};
    }
  }

  void _useFallbackContent({String? message}) {
    setState(() {
      _errorMessage = message;
      _allContent = List<EducationContent>.from(_fallbackContent);
      _filteredContent = List<EducationContent>.from(_fallbackContent);
    });
    _filterContent();
  }

  // Always include static content in filtered content when showing all categories

  void _ensureStaticContentIncluded() {

    if (_selectedCategory == EducationCategory.all && _allContent.isNotEmpty) {

      // Add static content if not already present

      final staticIds = _allContent.where((c) => _isStaticContent(c)).map((c) => c.id).toSet();

      for (var staticContent in _fallbackContent) {

        if (!staticIds.contains(staticContent.id)) {

          _allContent.add(staticContent);

        }

      }

      _filterContent();

    }

  }

  EducationContent? _mapMyHealthfinderResourceToContent(
      Map<String, dynamic> resource) {
    final title = resource['Title'] as String? ?? '';
    if (title.isEmpty) return null;

    final teaser = resource['Teaser'] as String? ?? '';
    final description = resource['MyHFDescription'] as String? ??
        resource['Description'] as String? ??
        teaser;

    final sections = resource['Sections'];
    final cleanedInlineContent = _cleanHtmlOrNull(resource['Content'] as String?);
    final content = _extractContentText(sections) ??
        cleanedInlineContent ??
        description;

    final category = _deriveCategory(resource);
    final tags = _buildTags(resource);

    return EducationContent(
      id: resource['Id']?.toString() ?? title.hashCode.toString(),
      title: title,
      description: teaser.isNotEmpty ? teaser : description,
      content: content,
      category: category,
      readTime: _estimateReadTime(content),
      tags: tags,
      hasInfographic: (resource['ImageUrl'] as String?)?.isNotEmpty ?? false,
      imagePath: resource['ImageUrl'] as String?,
      publishedDate: _parseDate(resource['DatePosted']),
      author: resource['Author'] as String?,
    );
  }

  EducationContent? _mapCdcResourceToContent(Map<String, dynamic> resource) {
    final title = resource['name'] as String? ?? resource['title'] as String? ?? '';
    if (title.isEmpty) return null;

    final description =
        resource['description'] as String? ?? resource['summary'] as String? ?? '';
    final content =
        resource['body'] as String? ?? resource['content'] as String? ?? description;

    final tagsWrapper = resource['tags'] as List<dynamic>? ?? [];
    final tags = tagsWrapper
        .map((tag) => tag is Map<String, dynamic> ? tag['name'] : tag)
        .map((tag) => tag?.toString() ?? '')
        .where((tag) => tag.isNotEmpty)
        .toList();

    final category = _deriveCdcCategory(tags);

    return EducationContent(
      id: resource['id']?.toString() ?? title.hashCode.toString(),
      title: title,
      description: description,
      content: content,
      category: category,
      imagePath: resource['thumbnailUrl'] as String?,
      readTime: _estimateReadTime(content),
      tags: tags,
      hasInfographic: (resource['mediaType'] as String?)
          ?.toLowerCase()
          .contains('graphic') ??
          false,
      publishedDate: _parseDate(resource['published']),
      author: resource['authors'] is List
          ? (resource['authors'] as List)
          .map((author) => author['name'] ?? '')
          .where((name) => name.toString().isNotEmpty)
          .join(', ')
          : resource['author'] as String?,
    );
  }

  EducationCategory _deriveCdcCategory(List<String> tags) {
    final lowerTags = tags.map((tag) => tag.toLowerCase()).toList();

    if (lowerTags.any((tag) => tag.contains('nutrition') || tag.contains('diet'))) {
      return EducationCategory.diet;
    }
    if (lowerTags.any((tag) => tag.contains('exercise') || tag.contains('activity'))) {
      return EducationCategory.lifestyle;
    }
    if (lowerTags.any((tag) => tag.contains('medication') || tag.contains('drug'))) {
      return EducationCategory.medications;
    }
    if (lowerTags.any((tag) => tag.contains('disease') || tag.contains('heart'))) {
      return EducationCategory.diseaseManagement;
    }

    return EducationCategory.all;
  }

  int _estimateReadTime(String content) {
    final wordCount = content.split(RegExp(r'\s+')).length;
    return (wordCount / 200).clamp(3, 10).round();
  }

  List<String> _buildTags(Map<String, dynamic> resource) {
    final categoriesRaw = resource['Categories'] ?? resource['categories'];
    final categories = categoriesRaw is Map<String, dynamic>
        ? categoriesRaw['Category'] ??
        categoriesRaw['category'] ??
        categoriesRaw['Categories']
        : categoriesRaw;
    final List<String> categoryNames = _normalizeDynamicStringList(categories);

    final keywordsRaw = resource['Keywords'] ?? resource['keywords'];
    final keywords = keywordsRaw is Map<String, dynamic>
        ? keywordsRaw['Keyword'] ??
        keywordsRaw['keyword'] ??
        keywordsRaw['Keywords']
        : keywordsRaw;
    final keywordList = _normalizeDynamicStringList(keywords);

    return {
      ...categoryNames,
      ...keywordList,
    }.where((tag) => tag.isNotEmpty).toList();
  }

  DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  String? _extractContentText(dynamic sections) {
    if (sections == null) return null;

    if (sections is String && sections.isNotEmpty) {
      return _cleanHtmlOrNull(sections);
    }

    if (sections is List) {
      final joined = sections
          .map<String?>((item) => _extractContentText(item))
          .whereType<String>()
          .join('\n\n');
      return _cleanHtmlOrNull(joined);
    }

    if (sections is Map<String, dynamic>) {
      final contentString = sections['content'] ??
          sections['Content'] ??
          sections['text'] ??
          sections['Text'];
      if (contentString is String && contentString.isNotEmpty) {
        return _cleanHtmlOrNull(contentString);
      }
      final nested = sections['section'] ??
          sections['Section'] ??
          sections['Sections'];
      if (nested != null) {
        return _extractContentText(nested);
      }
    }

    return null;
  }

  String _buildCardSummary(EducationContent content) {
    final trimmedDescription = content.description.trim();
    if (trimmedDescription.isNotEmpty) {
      return trimmedDescription;
    }
    final cleanedContent = _cleanHtmlOrNull(content.content);
    if (cleanedContent != null && cleanedContent.isNotEmpty) {
      return cleanedContent;
    }
    return 'Learn more about this topic in the full article.';
  }

  EducationCategory _deriveCategory(Map<String, dynamic> resource) {
    final categoriesRaw = resource['Categories'] ?? resource['categories'];
    final categories = categoriesRaw is Map<String, dynamic>
        ? categoriesRaw['Category'] ??
        categoriesRaw['category'] ??
        categoriesRaw['Categories']
        : categoriesRaw;
    final List<String> names =
    _normalizeDynamicStringList(categories).map((e) => e.toLowerCase()).toList();

    if (names.any((name) => name.contains('nutrition') || name.contains('diet'))) {
      return EducationCategory.diet;
    }
    if (names.any((name) => name.contains('healthy living') || name.contains('lifestyle'))) {
      return EducationCategory.lifestyle;
    }
    if (names.any((name) => name.contains('treatment') || name.contains('medication'))) {
      return EducationCategory.medications;
    }
    if (names.any((name) => name.contains('disease') || name.contains('heart attack'))) {
      return EducationCategory.diseaseManagement;
    }
    return EducationCategory.all;
  }

  List<String> _normalizeDynamicStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((item) => item is Map<String, dynamic>
          ? item['Title'] ?? item['term'] ?? item['text']
          : item)
          .map((item) => item?.toString() ?? '')
          .toList();
    }
    if (value is Map<String, dynamic>) {
      final candidate = value['Title'] ??
          value['title'] ??
          value['term'] ??
          value['text'] ??
          value.values.first;
      return [candidate?.toString() ?? ''];
    }
    return [value.toString()];
  }

  String _cleanHtml(String? htmlText) {
    if (htmlText == null || htmlText.isEmpty) return '';
    var text = htmlText
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
    text = text.replaceAll('&nbsp;', ' ');
    text = text.replaceAll('&amp;', '&');
    text = text.replaceAll('&quot;', '"');
    text = text.replaceAll('&#39;', "'");
    text = text.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    text = text.replaceAll(RegExp(r'\n[ \t]+'), '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.replaceAll(RegExp(r' {2,}'), ' ');
    return text.trim();
  }

  String? _cleanHtmlOrNull(String? htmlText) {
    final cleaned = _cleanHtml(htmlText);
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned;
  }

  Widget _buildContentImage(EducationContent content) {
    final path = content.imagePath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Stack(
        children: [
          _buildImageBySource(path, height: 180),
          if (content.hasInfographic)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Infographic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailImage(EducationContent content) {
    final path = content.imagePath;
    if (path == null || path.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          _buildImageBySource(path, height: deviceWidth(context) > 750 ? 500: 220),
          if (content.hasInfographic)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Infographic',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageBySource(String path, {double height = 180}) {
    if (_isRemoteImage(path)) {
      return Image.network(
        path,
        width: double.infinity,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildImagePlaceholder(isLoading: true);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }

    return Image.asset(
      path,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildImagePlaceholder();
      },
    );
  }

  bool _isRemoteImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Widget _buildImagePlaceholder({bool isLoading = false}) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Colors.grey[200],
      child: Center(
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _onCategorySelected(EducationCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchEducationContent(category: category);
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    final user = userDetailsAsync.asData?.value;
    const backgroundColor = Color(0xFFF5F6FA);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24), // 👈 Adjust the roundness
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            if (widget.navFromPage == NavPageType.home.name ||
                widget.navFromPage == NavPageType.addMedication.name) {
              AppRouter.replaceWithHome(context);
            } else {
              Navigator.pop(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("lib/assets/Frame.png"),
          ),
        ),
        title: const Center(
          child:  Text(
            'Education',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: NotificationBadgeIcon(),
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: _buildSearchField(),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.withValues(alpha: 0.1),
                        indent: 20,
                        endIndent: 20,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: AppTheme.primaryColor,
                          onRefresh: () =>
                              _fetchEducationContent(category: _selectedCategory),
                          child: _buildContentList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }

  Widget _buildCategoryChip(EducationCategory category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.icon,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              category.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Search educational content...',
        hintStyle: TextStyle(fontSize: deviceWidth(context) > 750 ? 20 : 16),
        prefixIcon: Icon(Icons.search, color: Colors.grey, size: deviceWidth(context) > 750 ? 35 : 24,),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
        )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildContentList() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: const [
          SizedBox(height: 80),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: 16),
          Center(
            child: Text('Loading the latest education content...'),
          ),
        ],
      );
    }

    if (_errorMessage != null && _filteredContent.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.red[200],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    _fetchEducationContent(category: _selectedCategory),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      );
    }

    if (_filteredContent.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No content found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search or category',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ..._filteredContent.map(_buildArticleCard).toList(),
      ],
    );
  }

  bool _isStaticContent(EducationContent content) {
    return content.id.startsWith('offline-');
  }

  Widget _buildArticleCard(EducationContent content) {
    final summary = _buildCardSummary(content);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showContentDetail(context, content),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio:   16 / 9,
                    child: content.imagePath != null && content.imagePath!.isNotEmpty
                        ? _buildImageBySource(
                      content.imagePath!,
                      height:double.infinity,
                    )
                        : _buildImagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  content.title,
                  style: TextStyle(
                    fontSize:  deviceWidth(context) > 750 ? 35:18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  style: TextStyle(
                    fontSize:  deviceWidth(context) > 750 ? 20:13.5,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 15,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${content.readTime} min read',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(EducationCategory category) {
    switch (category) {
      case EducationCategory.diet:
        return const Color(0xFF4CAF50); // Green
      case EducationCategory.lifestyle:
        return const Color(0xFF2196F3); // Blue
      case EducationCategory.medications:
        return const Color(0xFF9C27B0); // Purple
      case EducationCategory.diseaseManagement:
        return AppTheme.primaryColor; // Red
      case EducationCategory.all:
        return Colors.grey;
    }
  }

  void _showContentDetail(BuildContext context, EducationContent content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(content.category)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                content.category.icon,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                content.category.displayName,
                                style: TextStyle(
                                  color: _getCategoryColor(content.category),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Title
                        Text(
                          content.title,
                          style: TextStyle(
                            fontSize:  deviceWidth(context) > 750 ? 35 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Read Time
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size:  deviceWidth(context) > 750 ? 20:16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${content.readTime} min read',
                              style: TextStyle(
                                fontSize:  deviceWidth(context) > 750 ? 20:14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildDetailImage(content),

                        if (content.imagePath != null)
                          const SizedBox(height: 20),

                        // Description
                        Text(
                          content.description,
                          style: TextStyle(
                            fontSize:  deviceWidth(context) > 750 ? 25 :16,
                            color: Colors.grey[800],
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Full Content
                        Text(
                          content.content,
                          style: TextStyle(
                            fontSize:  deviceWidth(context) > 750 ? 20:15,
                            color: Colors.black87,
                            height: 1.7,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tags
                        if (content.tags.isNotEmpty) ...[
                          Text(
                            'Tags:',
                            style: TextStyle(
                              fontSize:  deviceWidth(context) > 750 ? 20:14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: content.tags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: deviceWidth(context) > 750 ? 20 : 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showQuickNavigationPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // First row - Breakfast, Lunch, Snacks, Dinner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickNavItemWithImage(
                      'Breakfast',
                      'lib/assets/32784048_7957093-removebg-preview (1).png',
                      const Color(0xFFFFD700), // Yellow
                          () {
                        Navigator.pop(context);
                        // AppRouter.navigateToAllMealIntakeWithTab(context, 1);
                      },
                    ),
                    _buildQuickNavItemWithImage(
                      'Lunch',
                      'lib/assets/24021906_6841374-removebg-preview (1).png',
                      const Color(0xFF4CAF50), // Green
                          () {
                        Navigator.pop(context);
                        //AppRouter.navigateToAllMealIntakeWithTab(context, 2);
                      },
                    ),
                    _buildQuickNavItemWithImage(
                      'Snacks',
                      'lib/assets/15593060_5616969-removebg-preview (1).png',
                      const Color(0xFF2196F3), // Light Blue
                          () {
                        Navigator.pop(context);
                        //AppRouter.navigateToAllMealIntakeWithTab(context, 3);
                      },
                    ),
                    _buildQuickNavItemWithImage(
                      'Dinner',
                      'lib/assets/24239396_6886800-removebg-preview (1).png',
                      const Color(0xFF2E7D32), // Dark Green
                          () {
                        Navigator.pop(context);
                        //AppRouter.navigateToAllMealIntakeWithTab(context, 4);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Second row - Medication, Body Mass Index, Add Symptoms
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickNavItemWithImage(
                      'Medication',
                      'lib/assets/Medication.png',
                      const Color(0xFF2196F3), // Light Blue
                          () {
                        Navigator.pop(context);
                        AppRouter.navigateToAllMedication(context);
                      },
                    ),
                    _buildQuickNavItemWithImage(
                      'Body Mass Index',
                      'lib/assets/Mody_mass_index.png',
                      const Color(0xFF2196F3), // Light Blue
                          () {
                        Navigator.pop(context);
                        AppRouter.navigateToAddBodyMassIndex(context);
                      },
                    ),
                    _buildQuickNavItemWithImage(
                      'Add Symptoms',
                      'lib/assets/add_symptom.png',
                      const Color(0xFFFF6B6B), // Light Red/Pink
                          () {
                        Navigator.pop(context);
                        AppRouter.navigateToAddSymptoms(context, true);
                      },
                    ),
                    const SizedBox(width: 60),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickNavItemWithImage(
      String title, String imagePath, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
