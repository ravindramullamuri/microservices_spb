import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_thrive/constants/ui_constants.dart';
import 'package:heart_thrive/utils/secure_storage_utils.dart';

import '../../components/connection_unavailable.dart';
import '../../components/editable_bottomsheet_card.dart';
import '../../components/profile_avatar.dart';
import '../../constants/heart_thrive_strings_constants.dart';
import '../../main.dart';
import '../../providers/bmi/bmi_provider.dart';
import '../../providers/internet_provider.dart';
import '../../providers/token_provider.dart';
import '../../providers/user/user_details_provider.dart';
import '../../routes/app_router.dart';
import '../../services/home/risk_meter_service.dart';
import '../../theme/app_theme.dart';
import '../notification_badgeicon_widget.dart';



class RecipePage extends ConsumerStatefulWidget {
  final String? navFromPage;
  const RecipePage({Key? key,this.navFromPage}) : super(key: key);

  @override
  ConsumerState<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends ConsumerState<RecipePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Recipe> _filteredRecipes = [];
  int _selectedIndex = 3;

  static final List<Recipe> _staticRecipes = [
    Recipe(
      id: '1',
      title: 'Herb Chicken and Veggie Bowl',
      imagePath: 'lib/assets/recipes_list/Herb Chicken and Veggie Bowl.jpg',
      prepTime: 20,
      sodium: 90,
      serves: 2,
      calories: 120,
      proteins: 27,
      fats: 91,
      description: 'A protein-packed meal featuring grilled chicken, fresh vegetables, and aromatic herbs.',
      ingredients: [
        '1 boneless skinless chicken breast (about 6 oz)',
        '1 cup cooked brown rice',
        '1 tbsp olive oil',
        '1 garlic clove, minced',
        '1 tsp dried Italian herbs (or oregano + basil)',
        '1 cup chopped broccoli',
        '1 red bell pepper, sliced',
        'Juice of ½ lemon',
      ],
      directions: [
        'Cook rice and set aside.',
        'Heat oil in a pan, add garlic and herbs.',
        'Add sliced chicken and cook for 7-10 minutes.',
        'Add veggies and cook until tender (5 minutes).',
        'Squeeze lemon juice over top and serve with rice.',
      ],
      heartHealthyNote: 'Uses fresh ingredients and herbs instead of salt.',
    ),
    Recipe(
      id: '2',
      title: 'Zesty Lentil Soup',
      imagePath: 'lib/assets/recipes_list/Zesty Lentil Soup.jpg',
      prepTime: 35,
      sodium: 120,
      serves: 4,
      calories: 120,
      proteins: 8,
      fats: 2,
      description: 'A warm and comforting soup packed with protein and fiber.',
      ingredients: [
        '1½ cups dry lentils (rinsed)',
        '1 medium onion, chopped',
        '2 carrots, chopped',
        '2 celery stalks, chopped',
        '2 tbsp no-salt-added tomato paste',
        '1 tsp ground cumin',
        '½ tsp smoked paprika',
        '5 cups water',
      ],
      directions: [
        'In a pot, sauté onion, carrots, and celery in 1 tsp olive oil for 5 minutes.',
        'Stir in tomato paste, cumin, and paprika.',
        'Add lentils and water. Bring to a boil, then simmer for 30–35 minutes.',
        'Serve warm.',
      ],
      heartHealthyNote: 'High fiber, no added salt, filling and warming.',
    ),
    Recipe(
      id: '3',
      title: 'Avocado Toast with No-Salt Everything Spice',
      imagePath: 'lib/assets/recipes_list/Avocado Toast with No-Salt Everything Spice.jpg',
      prepTime: 5,
      sodium: 75,
      serves: 1,
      calories: 80,
      proteins: 4,
      fats: 6,
      description: 'A simple and nutritious breakfast option with healthy fats.',
      ingredients: [
        '1 slice whole grain bread',
        '½ avocado',
        '¼ tsp garlic powder',
        '¼ tsp onion powder',
        '¼ tsp sesame seeds',
        '1 pinch black pepper or red chili flakes (optional)',
      ],
      directions: [
        'Toast the bread.',
        'Mash avocado and spread on toast.',
        'Sprinkle garlic, onion powder, sesame seeds, and pepper on top.',
      ],
      heartHealthyNote: 'Heart-healthy fats and potassium help support blood pressure.',
    ),
    Recipe(
      id: '4',
      title: 'Fruit-Infused Water',
      imagePath: 'lib/assets/recipes_list/Fruit-Infused Water.jpg',
      prepTime: 5,
      sodium: 0,
      serves: 4,
      calories: 5,
      proteins: 0,
      fats: 0,
      description: 'A refreshing and hydrating drink with natural fruit flavors.',
      ingredients: [
        '1 small lemon, sliced',
        '¼ cucumber, sliced',
        '4 strawberries, sliced',
        '4 fresh basil leaves',
        '4 cups cold water',
      ],
      directions: [
        'Add all fruits and herbs to a pitcher.',
        'Fill with water and chill in fridge for 2+ hours.',
        'Serve cold, refill as needed.',
      ],
      heartHealthyNote: 'Keeps you hydrated, flavorful, and helps reduce soda cravings.',
    ),
    Recipe(
      id: '5',
      title: 'Garlic & Herb Chicken with Rice',
      imagePath: 'lib/assets/recipes_list/Garlic & Herb Chicken with Rice.jpg',
      prepTime: 25,
      sodium: 125,
      serves: 2,
      calories: 350,
      proteins: 35,
      fats: 12,
      description: 'A simple and flavorful chicken dish with aromatic herbs and rice.',
      ingredients: [
        '2 small boneless skinless chicken breasts (8 oz total)',
        '1 tbsp olive oil',
        '1 tsp garlic powder',
        '1 tsp dried parsley',
        '½ tsp black pepper',
        '1 cup cooked white or brown rice (unsalted)',
        '½ cup steamed green beans (no salt)',
      ],
      directions: [
        'Heat olive oil in a pan on medium heat.',
        'Sprinkle garlic, parsley, and pepper on chicken.',
        'Cook chicken 5–6 minutes on each side until done.',
        'Serve with rice and green beans.',
      ],
      heartHealthyNote: 'Low sodium, high protein, and uses herbs for flavor instead of salt.',
    ),
    Recipe(
      id: '6',
      title: 'Veggie Egg Scramble',
      imagePath: 'lib/assets/recipes_list/Veggie Egg Scramble.jpg',
      prepTime: 10,
      sodium: 110,
      serves: 1,
      calories: 200,
      proteins: 14,
      fats: 15,
      description: 'A quick and nutritious breakfast scramble with fresh vegetables.',
      ingredients: [
        '2 eggs',
        '¼ cup chopped bell peppers',
        '¼ cup chopped onions',
        '1 tsp olive oil',
        '½ tsp black pepper',
        '1 tsp garlic powder',
      ],
      directions: [
        'Beat eggs in a bowl.',
        'Heat oil in pan. Cook peppers and onions for 2–3 minutes.',
        'Pour eggs in. Stir until cooked.',
      ],
      heartHealthyNote: 'High protein breakfast with minimal sodium and healthy fats.',
    ),
    Recipe(
      id: '7',
      title: 'Chickpea & Cucumber Salad',
      imagePath: 'lib/assets/recipes_list/Chickpea & Cucumber Salad.jpg',
      prepTime: 10,
      sodium: 120,
      serves: 2,
      calories: 180,
      proteins: 8,
      fats: 7,
      description: 'A refreshing and protein-rich salad perfect for a light meal.',
      ingredients: [
        '1 cup no-salt-added chickpeas (drained & rinsed)',
        '½ cucumber, diced',
        '1 tbsp olive oil',
        '1 tbsp lemon juice',
        '½ tsp black pepper',
        '1 tbsp fresh parsley',
      ],
      directions: [
        'Add everything to bowl.',
        'Mix together.',
        'Chill or eat right away.',
      ],
      heartHealthyNote: 'High fiber, plant-based protein, and heart-healthy fats.',
    ),
    Recipe(
      id: '8',
      title: 'Lemon Baked Tilapia',
      imagePath: 'lib/assets/recipes_list/Lemon Baked Tilapia.jpg',
      prepTime: 20,
      sodium: 90,
      serves: 2,
      calories: 200,
      proteins: 30,
      fats: 8,
      description: 'A light and flaky fish dish with zesty lemon flavor.',
      ingredients: [
        '2 tilapia fillets (5 oz total)',
        '1 tbsp lemon juice',
        '1 tsp garlic powder',
        '1 tsp paprika',
        '1 tbsp olive oil',
      ],
      directions: [
        'Preheat oven to 375°F.',
        'Place fish on baking sheet.',
        'Add lemon juice, oil, and seasonings.',
        'Bake for 15 minutes.',
      ],
      heartHealthyNote: 'Lean protein source with omega-3s and minimal sodium.',
    ),
    Recipe(
      id: '9',
      title: 'Sweet Potato & Spinach Bowl',
      imagePath: 'lib/assets/recipes_list/Sweet Potato & Spinach Bowl.jpg',
      prepTime: 30,
      sodium: 80,
      serves: 2,
      calories: 250,
      proteins: 5,
      fats: 7,
      description: 'A nutrient-dense bowl with sweet potatoes and fresh spinach.',
      ingredients: [
        '1 large sweet potato (cubed)',
        '1 cup fresh spinach',
        '1 tbsp olive oil',
        '½ tsp cinnamon',
        '½ tsp pepper',
      ],
      directions: [
        'Bake sweet potato at 375°F for 25 minutes.',
        'Add spinach to pan for last 5 minutes.',
        'Add oil and seasoning.',
      ],
      heartHealthyNote: 'Rich in fiber, vitamins, and antioxidants with no added salt.',
    ),
    Recipe(
      id: '10',
      title: 'Tuna & Avocado Wrap',
      imagePath: 'lib/assets/recipes_list/Tuna & Avocado Wrap.jpg',
      prepTime: 10,
      sodium: 130,
      serves: 1,
      calories: 320,
      proteins: 25,
      fats: 15,
      description: 'A protein-packed wrap with healthy fats from avocado.',
      ingredients: [
        '1 whole wheat tortilla (low sodium)',
        '½ cup no-salt-added tuna',
        '¼ avocado',
        '1 tbsp plain Greek yogurt',
        'Pepper & lemon juice',
      ],
      directions: [
        'Mash avocado.',
        'Mix tuna with yogurt and lemon.',
        'Spread on tortilla. Roll and eat.',
      ],
      heartHealthyNote: 'High protein, omega-3s from tuna, and heart-healthy monounsaturated fats.',
    ),
    Recipe(
      id: '11',
      title: 'Low-Sodium Lentil Soup',
      imagePath: 'lib/assets/recipes_list/Low-Sodium Lentil Soup.jpg',
      prepTime: 35,
      sodium: 90,
      serves: 3,
      calories: 150,
      proteins: 10,
      fats: 2,
      description: 'A hearty and warming soup made without added salt.',
      ingredients: [
        '1 cup dried lentils',
        '3 cups water (no broth)',
        '½ cup diced onions',
        '½ cup diced carrots',
        '1 tsp garlic powder',
        '½ tsp cumin',
      ],
      directions: [
        'Add all to pot.',
        'Boil for 30 minutes.',
        'Stir and serve.',
      ],
      heartHealthyNote: 'High fiber, plant-based protein, and naturally low in sodium.',
    ),
    Recipe(
      id: '12',
      title: 'Turkey Lettuce Wraps',
      imagePath: 'lib/assets/recipes_list/Turkey Lettuce Wraps.jpg',
      prepTime: 15,
      sodium: 120,
      serves: 2,
      calories: 200,
      proteins: 28,
      fats: 8,
      description: 'Light and fresh wraps using lettuce instead of bread.',
      ingredients: [
        '6 oz low-sodium ground turkey',
        '1 tsp olive oil',
        '½ cup chopped onion',
        'Romaine or butter lettuce leaves',
        'Pepper and garlic powder',
      ],
      directions: [
        'Cook turkey and onion in oil.',
        'Spoon into lettuce leaves.',
      ],
      heartHealthyNote: 'Low carb, high protein, and uses lettuce for a lighter option.',
    ),
    Recipe(
      id: '13',
      title: 'Simple Garlic Pasta',
      imagePath: 'lib/assets/recipes_list/Simple Garlic Pasta.jpg',
      prepTime: 15,
      sodium: 90,
      serves: 2,
      calories: 280,
      proteins: 10,
      fats: 8,
      description: 'A simple pasta dish with aromatic garlic and fresh herbs.',
      ingredients: [
        '1 cup cooked whole wheat pasta (no salt)',
        '1 tbsp olive oil',
        '1 tsp minced garlic',
        '1 tbsp parsley',
        'Black pepper',
      ],
      directions: [
        'Cook garlic in oil for 1 minute.',
        'Add pasta and parsley.',
        'Stir and serve.',
      ],
      heartHealthyNote: 'Whole grains provide fiber, and herbs add flavor without salt.',
    ),
    Recipe(
      id: '14',
      title: 'Herbed Roasted Potatoes',
      imagePath: 'lib/assets/recipes_list/Herbed Roasted Potatoes.jpg',
      prepTime: 35,
      sodium: 60,
      serves: 2,
      calories: 180,
      proteins: 4,
      fats: 7,
      description: 'Crispy roasted potatoes seasoned with aromatic herbs.',
      ingredients: [
        '2 small potatoes (cubed)',
        '1 tbsp olive oil',
        '1 tsp rosemary',
        '1 tsp garlic powder',
        'Pepper',
      ],
      directions: [
        'Toss all together.',
        'Bake at 400°F for 30 minutes.',
      ],
      heartHealthyNote: 'Very low sodium, uses herbs for flavor, and provides potassium.',
    ),
    Recipe(
      id: '15',
      title: 'Berry Oatmeal',
      imagePath: 'lib/assets/recipes_list/Berry Oatmeal.jpg',
      prepTime: 10,
      sodium: 15,
      serves: 1,
      calories: 220,
      proteins: 6,
      fats: 4,
      description: 'A wholesome breakfast with fiber-rich oats and fresh berries.',
      ingredients: [
        '½ cup oats',
        '1 cup water',
        '½ cup fresh berries',
        '1 tsp honey',
        'Cinnamon',
      ],
      directions: [
        'Cook oats in water.',
        'Add berries, cinnamon, honey.',
      ],
      heartHealthyNote: 'Extremely low sodium, high fiber, and natural sweetness from berries.',
    ),
    Recipe(
      id: '16',
      title: 'Carrot & Hummus Snack Plate',
      imagePath: 'lib/assets/recipes_list/Carrot & Hummus Snack Plate.jpg',
      prepTime: 5,
      sodium: 120,
      serves: 1,
      calories: 150,
      proteins: 5,
      fats: 8,
      description: 'A quick and healthy snack with fresh vegetables and hummus.',
      ingredients: [
        '1 cup carrot sticks',
        '2 tbsp low-sodium hummus',
      ],
      directions: [
        'Dip carrots into hummus.',
      ],
      heartHealthyNote: 'High fiber snack with plant-based protein and beta-carotene.',
    ),
    Recipe(
      id: '17',
      title: 'Baked Paprika Chicken Thighs',
      imagePath: 'lib/assets/recipes_list/Baked Paprika Chicken Thighs.jpg',
      prepTime: 40,
      sodium: 110,
      serves: 2,
      calories: 320,
      proteins: 32,
      fats: 18,
      description: 'Juicy chicken thighs with a smoky paprika seasoning.',
      ingredients: [
        '2 skinless chicken thighs',
        '1 tbsp olive oil',
        '1 tsp paprika',
        '1 tsp garlic powder',
        'Black pepper',
      ],
      directions: [
        'Rub chicken with oil + spices.',
        'Bake at 375°F for 35 minutes.',
      ],
      heartHealthyNote: 'High protein, uses spices for flavor, and moderate in healthy fats.',
    ),
    Recipe(
      id: '18',
      title: 'Yogurt Cucumber Dip (Tzatziki-style)',
      imagePath: 'lib/assets/recipes_list/Yogurt Cucumber Dip (Tzatziki-style).jpg',
      prepTime: 10,
      sodium: 25,
      serves: 4,
      calories: 40,
      proteins: 4,
      fats: 2,
      description: 'A refreshing Greek-style dip perfect for vegetables or as a side.',
      ingredients: [
        '1 cup plain Greek yogurt',
        '½ cucumber (shredded)',
        '1 tsp lemon juice',
        '1 tsp garlic powder',
        'Dill (optional)',
      ],
      directions: [
        'Mix all in bowl.',
        'Chill before eating.',
      ],
      heartHealthyNote: 'Very low sodium, probiotic benefits, and high protein.',
    ),
    Recipe(
      id: '19',
      title: 'Veggie Fried Rice (No Salt)',
      imagePath: 'lib/assets/recipes_list/Veggie Fried Rice (No Salt).jpg',
      prepTime: 15,
      sodium: 100,
      serves: 2,
      calories: 250,
      proteins: 8,
      fats: 7,
      description: 'A flavorful fried rice made with vegetables and no added salt.',
      ingredients: [
        '1½ cups cooked rice',
        '1 egg',
        '½ cup mixed veggies',
        '1 tbsp olive oil',
        'Garlic powder & pepper',
      ],
      directions: [
        'Cook egg in oil.',
        'Add rice and veggies.',
        'Stir and heat.',
      ],
      heartHealthyNote: 'Uses herbs and spices for flavor, includes protein and vegetables.',
    ),
    Recipe(
      id: '20',
      title: 'Grilled Chicken & Avocado Salad',
      imagePath: 'lib/assets/recipes_list/Grilled Chicken & Avocado Salad (Diabetic Conscious).jpg',
      prepTime: 20,
      sodium: 115,
      serves: 1,
      calories: 380,
      proteins: 35,
      fats: 22,
      description: 'A diabetic-conscious salad with lean protein and healthy fats.',
      ingredients: [
        '4 oz grilled chicken breast (no salt added)',
        '2 cups mixed greens',
        '¼ avocado (sliced)',
        '1 tbsp olive oil',
        '1 tbsp lemon juice',
        'Black pepper',
      ],
      directions: [
        'Put greens in a bowl.',
        'Add chicken and avocado.',
        'Pour oil and lemon on top.',
        'Add black pepper and mix.',
      ],
      heartHealthyNote: 'Low carb, high protein, and heart-healthy monounsaturated fats. Good for diabetes and heart health.',
    ),
    Recipe(
      id: '21',
      title: 'Turkey & Veggie Lettuce Boats',
      imagePath: 'lib/assets/recipes_list/Turkey Lettuce Wraps.jpg',
      prepTime: 20,
      sodium: 120,
      serves: 2,
      calories: 180,
      proteins: 26,
      fats: 6,
      description: 'Low-carb lettuce boats filled with seasoned turkey and vegetables.',
      ingredients: [
        '6 oz low-sodium ground turkey',
        '½ cup chopped bell pepper',
        '½ cup chopped zucchini',
        '1 tsp olive oil',
        '6 large romaine leaves',
        '½ tsp garlic powder',
        'Pepper',
      ],
      directions: [
        'Cook turkey in oil until brown.',
        'Add veggies and cook 5 minutes.',
        'Scoop into lettuce leaves.',
        'Eat like a taco.',
      ],
      heartHealthyNote: 'Low carb, high protein, and diabetic-friendly. Great for blood sugar control.',
    ),
    Recipe(
      id: '22',
      title: 'Mushroom & Spinach Egg Scramble',
      imagePath: 'lib/assets/recipes_list/Mushroom & Spinach Egg Scramble (Diabetic Conscious).jpg',
      prepTime: 12,
      sodium: 110,
      serves: 1,
      calories: 220,
      proteins: 16,
      fats: 14,
      description: 'A nutritious breakfast scramble with mushrooms and spinach.',
      ingredients: [
        '2 eggs',
        '½ cup sliced mushrooms',
        '1 cup fresh spinach',
        '1 tsp olive oil',
        '½ tsp black pepper',
        '½ tsp garlic powder',
      ],
      directions: [
        'Heat oil in pan.',
        'Cook mushrooms for 3 minutes.',
        'Add spinach to wilt.',
        'Add beaten eggs. Scramble until done.',
      ],
      heartHealthyNote: 'High protein breakfast with vegetables. Good for glucose control and heart health.',
    ),
    Recipe(
      id: '23',
      title: 'Chia Seed Pudding',
      imagePath: 'lib/assets/recipes_list/Chia Seed Pudding (Diabetic Conscious).jpg',
      prepTime: 5,
      sodium: 20,
      serves: 1,
      calories: 150,
      proteins: 5,
      fats: 8,
      description: 'A high-fiber pudding that helps with slow sugar release.',
      ingredients: [
        '2 tbsp chia seeds',
        '½ cup unsweetened almond milk',
        '½ tsp cinnamon',
        '¼ tsp vanilla extract',
        'Optional: a few blueberries',
      ],
      directions: [
        'Mix everything in a jar.',
        'Put in fridge overnight.',
        'Eat cold in morning.',
      ],
      heartHealthyNote: 'High fiber, slow sugar release, and extremely low sodium. Excellent for diabetes management.',
    ),
    Recipe(
      id: '24',
      title: 'Baked Salmon & Asparagus',
      imagePath: 'lib/assets/recipes_list/Baked Salmon & Asparagus (Diabetic Conscious).jpg',
      prepTime: 25,
      sodium: 95,
      serves: 2,
      calories: 320,
      proteins: 35,
      fats: 16,
      description: 'A heart-healthy dish with omega-3 rich salmon and fresh asparagus.',
      ingredients: [
        '6 oz fresh salmon',
        '1 cup asparagus',
        '1 tbsp olive oil',
        '1 tbsp lemon juice',
        '1 tsp garlic powder',
        'Black pepper',
      ],
      directions: [
        'Turn oven to 375°F.',
        'Place salmon + asparagus on pan.',
        'Add oil, lemon, and spices.',
        'Bake for 20 minutes.',
      ],
      heartHealthyNote: 'Rich in omega-3s, supports blood sugar control, and excellent for heart health.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredRecipes = _staticRecipes;
    _searchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterRecipes() {
    setState(() {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        _filteredRecipes = _staticRecipes;
      } else {
        _filteredRecipes = _staticRecipes
            .where((recipe) => recipe.title.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //final user = ref.watch(userDetailsDataProvider).whenData((user) => user).value;
    final userDetailsAsync = ref.watch(userDetailsDataProvider);
    return userDetailsAsync.when(
        data: (user){
          debugPrint("Device Width ${deviceWidth(context)}");
          return Scaffold(
            backgroundColor: AppTheme.appBackgroundColor,
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
              title:  Center(
                child: Text(
                  'Recipe',
                  style: AppTheme.title18.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: NotificationBadgeIcon(),
                ),
              ],
            ),
            body:Container(
              color: AppTheme.appBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  height: double.infinity,   // auto height adjust for any device
                  width: double.infinity,
                  child: Card(
                    //elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        children: [
                          // Search Bar
                          Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search Recipe',
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          // Recipe Grid
                          Expanded(
                            child: _filteredRecipes.isEmpty
                                ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No recipes found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try a different search term',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : Padding(
                              padding: const EdgeInsets.all(6),
                              child: GridView.builder(
                                gridDelegate:
                                 SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: deviceWidth(context)> 830? 0.95:0.8,
                                ),
                                itemCount: _filteredRecipes.length,
                                itemBuilder: (context, index) {
                                  return _buildRecipeCard(_filteredRecipes[index]);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // bottomNavigationBar: _buildBottomNav(context),
          );
        },
        error: (e,st){
          final isOnline = ref.watch(isOnlineProvider);
          return !isOnline?ConnectionUnavailable(
            title: HeartThriveStrings.offlineTitle,
            description:HeartThriveStrings.offlineMessage,
            buttonText: "Retry",
            onRetry: () async{
              final token = await SecureStorageUtils().read(StorageKeys.accessToken);
              Navigator.push(context, MaterialPageRoute(
                  builder: (context)=>MyApp(initialToken: token)));
            },
          ):ConnectionUnavailable(
            title: HeartThriveStrings.userServerIssueTitle,
            description:HeartThriveStrings.userServerIssueDescription,
            buttonText: "Retry",
            onRetry: () async{
              final token = await SecureStorageUtils().read(StorageKeys.accessToken);
              Navigator.push(context, MaterialPageRoute(
                  builder: (context)=>MyApp(initialToken: token)));
            },
          );
        },
        loading: (){
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24), // 👈 Adjust the roundness
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.only(left: 15,top: 8,bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'lib/assets/default_profile_img.png',
                    gaplessPlayback: true,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title:  Center(
                child: Text(
                  'Recipe',
                  style: AppTheme.title18.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: NotificationBadgeIcon(),
                ),
              ],
            ),
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            ),
            // bottomNavigationBar: _buildBottomNav(context),
          );
        });
  }
  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            height: 85,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, -2),
                )
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedFontSize: 12,     // ⬅ same font size when selected
              unselectedFontSize: 12,   // ⬅ same font size when unselected

              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500, // optional → keep text normal
                color: AppTheme.primaryColor,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
              elevation: 0,
              onTap: (index) async {

                setState(() => _selectedIndex = index);

                switch (index) {
                  case 0:
                    AppRouter.navigateToHome(context);
                    break;
                  case 1:
                    AppRouter.navigateToEducation(context);
                    break;
                  case 2:
                    showQuickNavigationBottomSheet(context,"recipe");
                    break;
                  case 3:
                  // AppRouter.navigateToRecipe(context);
                    break;
                  case 4:
                    final result =
                    await AppRouter.navigateToProfile(context);
                    if (result != null) {
                      ref.invalidate(riskMetricsFutureProvider);
                      ref.invalidate(heroDashboardProvider);

                    }
                    break;
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 0
                        ? 'lib/assets/home_active.png'
                        : 'lib/assets/home_not_active.png',
                    width: 28,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 1
                        ? 'lib/assets/nb_1.png'
                        : 'lib/assets/nb_2.png',
                    width: 28,
                  ),
                  label: 'Education',
                ),
                const BottomNavigationBarItem(
                    icon: SizedBox.shrink(), label: ''),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 3
                        ? 'lib/assets/nb_7.png'
                        : 'lib/assets/nb_8.png',
                    width: 28,
                  ),
                  label: 'Recipe',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    _selectedIndex == 4
                        ? 'lib/assets/nb_5.png'
                        : 'lib/assets/nb_6.png',
                    width: 28,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),

          // ADD BUTTON
          Positioned(
            top: 6,
            child: GestureDetector(
              onTap: ()  {
                showQuickNavigationBottomSheet(context,"education");
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Center(
                    child: Icon(
                      Icons.add,
                      size: 35,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    final double screenWidth = deviceWidth(context);
    final bool isSmallScreen = screenWidth < 360;
    final bool isMediumScreen = screenWidth < 410;
    final bool isLargeScreen = screenWidth < 800;

    final double iconSize = isSmallScreen ? 12 : isMediumScreen ? 14 : isLargeScreen?25:35;
    final double textFontSize = isSmallScreen ? 10: isMediumScreen ? 12 : isLargeScreen?14:18;
    final double titleFontSize = isSmallScreen ? 12 : isMediumScreen ? 12 : isLargeScreen?16:20;

    return GestureDetector(
      onTap: () => _showRecipeDetail(context, recipe),
      child: Card(
        elevation: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              /// ------- FIXED IMAGE HEIGHT --------
              AspectRatio(
                aspectRatio: 16 / 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    recipe.imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),


              /// ------- CONTENT AREA FIX --------
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: titleFontSize * 2.4, // enough for 2 lines
                        child: Text(
                          recipe.title,
                          style: AppTheme.title20.copyWith(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Image.asset('lib/assets/recipe-sodium.png',
                              width: iconSize, height: iconSize),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.sodium} mg',
                            style: TextStyle(fontSize: textFontSize - 1),
                          ),
                          const Spacer(),
                          Image.asset('lib/assets/Tableware.png',
                              width: iconSize, height: iconSize),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.serves} ${recipe.serves == 1 ? 'Serving' : 'Serves'}',
                            style: TextStyle(fontSize: textFontSize ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Image.asset('lib/assets/recipe-cal.png',
                              width: iconSize, height: iconSize),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.calories} Kcal',
                            style: TextStyle(fontSize: textFontSize - 1),
                          ),
                          const Spacer(),
                          Icon(Icons.access_time,
                              size: iconSize, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.prepTime} min',
                            style: TextStyle(fontSize: textFontSize - 1),
                          ),
                        ],
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



  void _showRecipeDetail(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecipeDetailSheet(recipe: recipe),
    );
  }




}

class RecipeDetailSheet extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailSheet({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<RecipeDetailSheet> {
  bool _showIngredients = true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.6,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isNarrow = constraints.maxWidth < 360;

              return Column(
                children: [
                  // Close button + drag handle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.close, size: 20, color: AppTheme.primaryColor),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40), // balance close button
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: isNarrow ? 12 : 20,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipe Image - responsive height
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                widget.recipe.imagePath,
                                width: double.infinity,
                                height: isNarrow ? 180 : 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title + Time
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.recipe.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.recipe.prepTime} Min',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            widget.recipe.description,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Nutrition Info - Now wraps properly on narrow screens
                          Column(
                            children: [
                              _nutritionRow(
                                _buildNutritionChip('lib/assets/recipe-sodium.png', '${widget.recipe.sodium} mg', 'Sodium'),
                                _buildNutritionChip('lib/assets/recipe-protein.png', '${widget.recipe.proteins}g', 'Proteins'),
                              ),
                              const SizedBox(height: 12),
                              _nutritionRow(
                                _buildNutritionChip('lib/assets/recipe-cal.png', '${widget.recipe.calories} Kcal', 'Calories'),
                                _buildNutritionChip('lib/assets/recipe-fats.png', '${widget.recipe.fats}g', 'Fats'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Tabs
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _tabButton('Ingredients', true),
                              ),
                              SizedBox(width: 10,),
                              Expanded(
                                child: _tabButton('Directions', false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Ingredients or Directions
                          if (_showIngredients) ...[
                            _buildSectionTitle('Ingredients (Serves ${widget.recipe.serves})', widget.recipe.ingredients.length),
                            const SizedBox(height: 12),
                            ...widget.recipe.ingredients.map((ing) => _buildBulletText(ing)),
                          ] else ...[
                            const Text('Directions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ...widget.recipe.directions.map((dir) => _buildBulletText(dir)),
                          ],

                          const SizedBox(height: 28),

                          // Heart Healthy Note
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border(left: BorderSide(color: AppTheme.primaryColor, width: 4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Why it's heart healthy:",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.recipe.heartHealthyNote,
                                  style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey[800]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }


  Widget _tabButton(String text, bool isIngredients) {
    final active = _showIngredients == isIngredients;

    return GestureDetector(
      onTap: () => setState(() => _showIngredients = isIngredients),
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryColor : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
  Widget _nutritionRow(Widget left, Widget right) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildNutritionChip(String imagePath, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, width: 30, height: 30),
          const SizedBox(width: 8),
          Text(
            '$value ${label.isNotEmpty?label:''}',
            style: AppTheme.body12,
          ),

        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text('$count Item${count > 1 ? 's' : ''}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 16, color: Colors.grey[700], fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class Recipe {
  final String id;
  final String title;
  final String imagePath;
  final int prepTime;
  final int sodium;
  final int serves;
  final int calories;
  final int proteins;
  final int fats;
  final String description;
  final List<String> ingredients;
  final List<String> directions;
  final String heartHealthyNote;

  Recipe({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.prepTime,
    required this.sodium,
    required this.serves,
    required this.calories,
    required this.proteins,
    required this.fats,
    required this.description,
    required this.ingredients,
    required this.directions,
    required this.heartHealthyNote,
  });
}
