import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/core/api_endpoints.dart';
import 'package:heart_thrive/pages/meal-sodium/user_meal_menu_picker_page.dart';
import 'package:heart_thrive/utils/error_response.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';
import 'package:http/http.dart' as http;

import '../../components/action_menu.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../constants/ui_constants.dart';
import '../../models/home/meal_type_nutrient_model.dart';
import '../../models/meal/edit_meal_model.dart';
import '../../providers/internet_provider.dart';
import '../../routes/app_router.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class FoodItem {
  final int id;
  final String uuid;
  final int fdcId;
  final String description;
  final String? brandName;
  final String? ingredients;
  final double servingSize;
  final String servingUnit;
  final List<Nutrient> nutrients;

  FoodItem({
    required this.id,
    required this.uuid,
    required this.fdcId,
    required this.description,
    this.brandName,
    this.ingredients,
    required this.servingSize,
    required this.servingUnit,
    required this.nutrients,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] ?? 0,
      uuid: json['uuid'] ?? '',
      fdcId: (json['fdcId'] as num?)?.toInt() ?? 0,
      description: json['description'] ?? '',
      brandName: json['brandName'],
      ingredients: json['ingredients'],
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 0.0,
      servingUnit: json['servingUnit'] ?? '',
      nutrients: (json['nutrients'] as List<dynamic>? ?? [])
          .map((e) => Nutrient.fromJson(e))
          .toList(),
    );
  }
}

class FoodListResponse {
  final List<FoodItem> content;
  final bool last;

  FoodListResponse({required this.content, required this.last});

  factory FoodListResponse.fromJson(Map<String, dynamic> json) {
    return FoodListResponse(
      content: (json['content'] as List)
          .map((e) => FoodItem.fromJson(e))
          .toList(),
      last: json['last'] ?? true,
    );
  }
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class FoodService {
  static final _baseUrl = ApiEndpoints.foodItemsWithNutrients;

  Future<FoodListResponse> fetchFoods({
    required int page,
    required int size,
    String? search,
    required String token,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'page': '$page',
      'size': '$size',
      if (search != null && search.isNotEmpty) 'foodItemName': search,
    });
    debugPrint("${DateTime.now()} Food Browse uri @@ $uri");
    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
    }).timeout(Duration(seconds: 30));

    if (response.statusCode != 200) {
      debugPrint(response.statusCode.toString());
      throw Exception('Failed to load foods');
    }
    debugPrint("data fetched ${response.body}");
    return FoodListResponse.fromJson(jsonDecode(response.body));
  }
}

// ---------------------------------------------------------------------------
// PROVIDERS
// ---------------------------------------------------------------------------

final foodServiceProvider = Provider((_) => FoodService());

final foodProvider =
StateNotifierProvider<FoodNotifier, AsyncValue<List<FoodItem>>>(
      (ref) => FoodNotifier(ref),
);

class FoodNotifier extends StateNotifier<AsyncValue<List<FoodItem>>> {
  FoodNotifier(this.ref) : super(const AsyncLoading()) {
    loadInitial();
  }

  final Ref ref;

  int _page = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  String _search = '';

  int _requestId = 0; // ⭐ KEY FIX

  static const int _pageSize = 10;

  bool get hasMore => _hasMore;

  // ---------------- INITIAL LOAD / SEARCH ----------------
  Future<void> loadInitial({String search = ''}) async {
    _page = 0;
    _hasMore = true;
    _search = search.trim();

    final int currentRequest = ++_requestId;

    state = const AsyncLoading();

    try {
      final data = await _fetch();

      if (currentRequest != _requestId) return;

      state = AsyncData(data);
    } catch (e, st) {
      if (currentRequest != _requestId) return;
      state = AsyncError(e, st);
    }
  }

  // ---------------- PAGINATION ----------------
  Future<void> loadMore() async {
    if (!_hasMore || _loadingMore || state.isLoading) return;

    _loadingMore = true;
    final int currentRequest = _requestId;

    final currentItems = state.value ?? [];

    try {
      final data = await _fetch();

      if (currentRequest != _requestId) return;

      _hasMore = data.length == _pageSize;
      state = AsyncData([...currentItems, ...data]);
    } finally {
      _loadingMore = false;
    }
  }

  // ---------------- API FETCH ----------------
  Future<List<FoodItem>> _fetch() async {
    final service = ref.read(foodServiceProvider);
    final token = await SecureStorageUtils().read(StorageKeys.accessToken);


    if (token == null) {
      throw Exception('No token');
    }

    final response = await service.fetchFoods(
      page: _page,
      size: _pageSize,
      search: _search.isEmpty ? null : _search,
      token: token,
    );

    _page++;
    return response.content;
  }
}

// ---------------------------------------------------------------------------
// EXTENSIONS
// ---------------------------------------------------------------------------

extension NutrientUtils on List<Nutrient> {
  String valueOf(String name) {
    final n = firstWhere(
          (e) => (e.name ?? '').toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrient(
          amount: 0, unitName: '', name: '', minValue: 0, maxValue: 0),
    );
    return '${(n.amount ?? 0).toStringAsFixed(1)}${n.unitName ?? ''}';
  }

  double qty(String name) {
    final n = firstWhere(
          (e) => (e.name ?? '').toLowerCase() == name.toLowerCase(),
      orElse: () => Nutrient(
          amount: 0, unitName: '', name: '', minValue: 0, maxValue: 0),
    );
    return n.amount ?? 0;
  }
}

// ---------------------------------------------------------------------------
// UI PAGE
// ---------------------------------------------------------------------------

class MealMenuPage extends ConsumerStatefulWidget {
  const MealMenuPage({super.key});

  @override
  ConsumerState<MealMenuPage> createState() => _MealMenuPageState();
}

class _MealMenuPageState extends ConsumerState<MealMenuPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool isBrowse = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);

    // Initial browse load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(foodProvider.notifier).loadInitial(search: "a");
    });
  }

  void _onSearchOld() {
    if (!isBrowse) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {

      if(ref.watch(foodProvider).isLoading){
        return;
      }
      ref
          .read(foodProvider.notifier)
          .loadInitial(search: _searchCtrl.text.isEmpty?"a":_searchCtrl.text);
    });
  }
  String _resolveSearchKeyword(String input) {
    final value = input.trim();

    if (value.isEmpty) return "a";     // empty → default
    if (value.length < 2) return "";   // 1 char → ignore
    return value;                      // 2+ chars → search
  }


  void _onSearch() {
    if (!isBrowse) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final notifier = ref.read(foodProvider.notifier);
      final state = ref.read(foodProvider);

      if (state.isLoading && _searchCtrl.text.trim().isEmpty) return;

      final keyword = _resolveSearchKeyword(_searchCtrl.text);

      // 🔴 Ignore 1-character search
      if (keyword.isEmpty) return;

      notifier.loadInitial(search: keyword);
    });
  }



  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool browse) {
    _debounce?.cancel();
    setState(() => isBrowse = browse);

    if (browse) {
      final search = _resolveSearchKeyword(_searchCtrl.text);
      ref.read(foodProvider.notifier).loadInitial(search: search);
    }
  }


  @override
  Widget build(BuildContext context) {
    final foodAsync = ref.watch(foodProvider);
    final notifier = ref.read(foodProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: Center(child: Text(isBrowse?"Browse food":'Meal Menu')),
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context,true);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("lib/assets/Frame.png"),
          ),
        ),
        actions: [
          actionMenuItem(context)
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _tab('Browse Food', isBrowse, () => _switchTab(true)),
                  const SizedBox(width: 8),
                  _tab('Meal Menu', !isBrowse, () => _switchTab(false)),
                ],
              ),
            ),
            if (isBrowse)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search Food or Meal',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintStyle: AppTheme.title14.copyWith(fontWeight: FontWeight.normal),
                      prefixIcon: const Icon(Icons.search, size: 26, color: Colors.black54),
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final editData = MealEditData(
                                  id: 0,
                                  name: "",
                                  quantity: '',
                                  servingUnit: '',
                                  calories: 0,
                                  sodium: 0,
                                  carbs: 0,
                                  protein: 0,
                                  fats: 0,
                                  mealTypeId: null,
                                  isCustom: true
                              );

                              debugPrint("➡️ Passing to AddMealPage:");
                              debugPrint(editData.name); // 👈 This debugPrints clean JSON-like output

                              await AppRouter.navigateToAddMeal(
                                context,
                                editData: editData,
                              );
                            },
                            child: Container(
                              height: 25,
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              margin: const EdgeInsets.only(right: 8.0),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Center(
                                child: Text(
                                  'Custom +',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(40.0)),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: isBrowse
                  ? foodAsync.when(
                loading: () =>
                const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    Text("Loading Food ...",style: AppTheme.body14,)
                  ],
                )),
                error: (e, _) => noDataUI(mapException(e).message),
                data: (items) => NotificationListener<ScrollNotification>(
                  onNotification: (s) {
                    if (s.metrics.pixels >
                        s.metrics.maxScrollExtent - 200) {
                      notifier.loadMore();
                    }
                    return false;
                  },
                  child: items.isEmpty? _buildCustomItemUI(context):ListView.builder(
                    itemCount: items.length + 1,
                    padding: const EdgeInsets.all(12),
                    itemBuilder: (c, i) {
                      if (i == items.length) {
                        return notifier.hasMore
                            ?  Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ))
                            : const SizedBox();
                      }
                      return _FoodTile(item: items[i]);
                    },
                  ),
                ),
              ) : MealListScreen(),
            )
          ],
        ),
      ),
    );
  }
  // Issue
  Widget noDataUI(String ? message){
    final isOnline = ref.watch(isOnlineProvider);
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  !isOnline?HeartThriveStrings.noInternet :message??HeartThriveStrings.noSodiumDashBoardTitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.title16.copyWith(
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  !isOnline?HeartThriveStrings.noInternetDescription :HeartThriveStrings.noSodiumDashBoardDescription,
                  textAlign: TextAlign.center,
                  style: AppTheme.body14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // No Food Item
  Widget _buildCustomItemUI(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'No food items found.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your own custom food item.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final editData = MealEditData(
                    id: 0,
                    name: "",
                    quantity: "",
                    servingUnit: "",
                    calories: 0,
                    sodium: 0,
                    carbs: 0,
                    protein: 0,
                    fats: 0,
                    mealTypeId: null,
                    isCustom: true
                );

                debugPrint("➡️ Passing to AddMealPage:");
                debugPrint(editData.name); // 👈 This debugPrints clean JSON-like output

                await AppRouter.navigateToAddMeal(
                  context,
                  editData: editData,
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Custom Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF95020A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Image.asset(
              'lib/assets/ss-removebg-preview 1.png',
              width:deviceWidth(context) > 390?230: deviceWidth(context) > 360?165:150,
              // height: 180,
            ),
          ],
        ),
      ),
    );
  }
  Widget _tab(String text, bool active, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          active ? AppTheme.primaryColor : Colors.grey.shade200,
          foregroundColor: active ? Colors.white : Colors.black,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTheme.responsiveButtonFontSize(context)
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FOOD TILE
// ---------------------------------------------------------------------------

class _FoodTileOld extends StatelessWidget {
  final FoodItem item;
  const _FoodTileOld({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await AppRouter.navigateToAddMeal(
          context,
          editData: MealEditData(
            id: item.id,
            name: item.description,
            quantity: item.servingSize.toString(),
            servingUnit: item.servingUnit,
            calories: item.nutrients.qty("Calories"),
            sodium: item.nutrients.qty("Sodium"),
            carbs:  item.nutrients.qty("Carbohydrates"),
            protein: item.nutrients.qty("Protein"),
            fats: item.nutrients.qty("Fat"),
            mealTypeId: null,
          ),
        );

        if (result == true) {

        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          title: Text('${item.description} (${item.servingSize} ${item.servingUnit})',
            style:  AppTheme.title20.copyWith(
              fontSize: AppTheme.responsiveTitleFontSize(context),
            ),maxLines: 2,overflow: TextOverflow.ellipsis,),
          subtitle: Text(
            '${item.nutrients.qty("Calories").toStringAsFixed(0)} kcal \n'
                'Contains ${item.nutrients.valueOf("Sodium")} Sodium',
            style: AppTheme.body14.copyWith(
                fontSize: AppTheme.responsiveParaFontSize(context)
            ),
          ),
          trailing: IconButton(
              onPressed:() async {
                final result = await AppRouter.navigateToAddMeal(
                  context,
                  editData: MealEditData(
                    id: item.id,
                    name: item.description,
                    quantity: item.servingSize.toString(),
                    servingUnit: item.servingUnit,
                    calories: item.nutrients.qty("Calories"),
                    sodium: item.nutrients.qty("Sodium"),
                    carbs:  item.nutrients.qty("Carbohydrates"),
                    protein: item.nutrients.qty("Protein"),
                    fats: item.nutrients.qty("Fat"),
                    mealTypeId: null,
                  ),
                );

                if (result == true) {

                }
              },
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor)),
        ),
      ),
    );
  }
}
class _FoodTile extends StatefulWidget {
  final FoodItem item;
  const _FoodTile({required this.item});

  @override
  State<_FoodTile> createState() => _FoodTileState();
}

class _FoodTileState extends State<_FoodTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final showBrand = item.brandName != null &&
        !item.brandName!.contains('NOT A BRANDED ITEM') &&
        !item.brandName!.contains('Custom');
    return InkWell(
      onTap: () async {
        final result = await AppRouter.navigateToAddMeal(
          context,
          editData: MealEditData(
            id: item.id,
            name: item.description,
            quantity: item.servingSize.toString(),
            servingUnit: item.servingUnit,
            calories: item.nutrients.qty("Calories"),
            sodium: item.nutrients.qty("Sodium"),
            carbs:  item.nutrients.qty("Carbohydrates"),
            protein: item.nutrients.qty("Protein"),
            fats: item.nutrients.qty("Fat"),
            mealTypeId: null,
          ),
        );

        if (result == true) {

        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                '${item.description} (${item.servingSize} ${item.servingUnit})',
                style: AppTheme.title20.copyWith(
                  fontSize: AppTheme.responsiveTitleFontSize(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${showBrand ? 'Brand : ${item.brandName}\n' : ''}'
                    'Contains ${item.nutrients.valueOf("Sodium")} Sodium',
                style: AppTheme.body14.copyWith(
                  fontSize: AppTheme.responsiveParaFontSize(context),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () async {
                  final result = await AppRouter.navigateToAddMeal(
                    context,
                    editData: MealEditData(
                      id: item.id,
                      name: item.description,
                      quantity: item.servingSize.toString(),
                      servingUnit: item.servingUnit,
                      calories: item.nutrients.qty("Calories"),
                      sodium: item.nutrients.qty("Sodium"),
                      carbs: item.nutrients.qty("Carbohydrates"),
                      protein: item.nutrients.qty("Protein"),
                      fats: item.nutrients.qty("Fat"),
                      mealTypeId: null,
                    ),
                  );

                  if (result == true) {}
                },
              ),
            ),

            /// SHOW / HIDE INGREDIENTS BUTTON
            item.ingredients != null? Padding(
              padding:  EdgeInsets.only(top: 3,left: 16,bottom: 10),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF95020A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _expanded ? 'Hide ingredients' : 'View ingredients',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF95020A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ):SizedBox(),

            /// INGREDIENTS CONTENT
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                padding: const EdgeInsets.only(left: 16,bottom: 10,right: 10),
                child: Container(
                  padding:const EdgeInsets.all(8),
                  width: deviceWidth(context),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                      ),
                    ],
                  ),
                  child: Text(
                    item.ingredients ?? 'No ingredients',
                    style: AppTheme.body14.copyWith(
                      fontSize:
                      AppTheme.responsiveParaFontSize(context),
                    ),
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}



class FoodCard extends StatefulWidget {
  final FoodItem item;
  const FoodCard({super.key, required this.item});

  @override
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${item.description} (${item.servingSize} ${item.servingUnit})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${item.nutrients.qty("Calories").toStringAsFixed(0)} kcal\n'
                  'Contains ${item.nutrients.valueOf("Sodium")} Sodium',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      isExpanded = !isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: AppTheme.primaryColor),
                  onPressed: () async {
                    await AppRouter.navigateToAddMeal(context);
                  },
                ),
              ],
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(item.description ?? ''),
            )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

