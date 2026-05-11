import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/repositories.dart';
import '../../../domain/entities/entities.dart';
import '../../blocs/blocs.dart';
import '../../widgets/common/common.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FavoritesRepository _repository = FavoritesRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    context.read<FavoritesBloc>().add(FavoritesLoadMeals());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        context.read<FavoritesBloc>().add(FavoritesLoadMeals());
        break;
      case 1:
        context.read<FavoritesBloc>().add(FavoritesLoadTemplates());
        break;
      case 2:
        context.read<FavoritesBloc>().add(FavoritesLoadFoods());
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FAVORITES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'MEALS'),
            Tab(text: 'TEMPLATES'),
            Tab(text: 'CUSTOM FOODS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFavoriteMeals(),
          _buildTemplates(),
          _buildCustomFoods(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add_rounded),
        label: Text(_getAddLabel()),
      ),
    );
  }

  String _getAddLabel() {
    switch (_tabController.index) {
      case 0:
        return 'ADD FAVORITE';
      case 1:
        return 'ADD TEMPLATE';
      case 2:
        return 'ADD FOOD';
      default:
        return 'ADD';
    }
  }

  void _showAddDialog() {
    switch (_tabController.index) {
      case 0:
        _showAddFavoriteDialog();
        break;
      case 1:
        _showAddTemplateDialog();
        break;
      case 2:
        _showAddFoodDialog();
        break;
    }
  }

  Widget _buildFavoriteMeals() {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const StateFeedback(
            icon: Icons.favorite_rounded,
            title: 'Loading favorites',
            description: 'Getting your quick-log meal shortcuts ready.',
          );
        }
        if (state is FavoritesError) {
          return _buildErrorState(state.message, () {
            context.read<FavoritesBloc>().add(FavoritesLoadMeals());
          });
        }
        if (state is FavoritesLoaded && state.meals.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.meals.length,
            itemBuilder: (context, index) {
              final item = state.meals[index];
              return _buildFavoriteCard(
                name: item.foodName,
                subtitle:
                    '${item.category} • ${item.estimatedSatiety} min satiety',
                onTap: () => _showMessage(
                  '${item.foodName}: ${item.fullnessVolume.toStringAsFixed(0)}% fullness',
                ),
                onLog: () => _logFavoriteMeal(item.id),
              );
            },
          );
        }
        return _buildEmptyState(
          icon: Icons.favorite_rounded,
          title: 'No favorite meals yet',
          subtitle: 'Add meals you eat often for quick logging',
        );
      },
    );
  }

  Widget _buildTemplates() {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const StateFeedback(
            icon: Icons.bookmark_rounded,
            title: 'Loading templates',
            description: 'Preparing your reusable meal templates.',
          );
        }
        if (state is FavoritesError) {
          return _buildErrorState(state.message, () {
            context.read<FavoritesBloc>().add(FavoritesLoadTemplates());
          });
        }
        if (state is FavoritesLoaded && state.templates.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.templates.length,
            itemBuilder: (context, index) {
              final MealTemplate item = state.templates[index];
              return _buildFavoriteCard(
                name: item.name,
                subtitle:
                    '${item.foodName} • ${item.estimatedSatiety} min satiety',
                onTap: () => _showMessage(
                  '${item.name}: ${item.description ?? 'No description'}',
                ),
                onLog: () => _logTemplate(item.id),
              );
            },
          );
        }
        return _buildEmptyState(
          icon: Icons.bookmark_rounded,
          title: 'No templates yet',
          subtitle: 'Create reusable meal templates',
        );
      },
    );
  }

  Widget _buildCustomFoods() {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const StateFeedback(
            icon: Icons.restaurant_menu_rounded,
            title: 'Loading custom foods',
            description: 'Preparing your custom nutrition entries.',
          );
        }
        if (state is FavoritesError) {
          return _buildErrorState(state.message, () {
            context.read<FavoritesBloc>().add(FavoritesLoadFoods());
          });
        }
        if (state is FavoritesLoaded && state.foods.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.foods.length,
            itemBuilder: (context, index) {
              final CustomFood item = state.foods[index];
              return _buildFavoriteCard(
                name: item.foodName,
                subtitle:
                    '${item.servingSize ?? 'Custom'} • ${item.estimatedSatiety} min satiety',
                onTap: () => _showMessage(
                  '${item.foodName}: GI ${item.absorptionRate.toStringAsFixed(0)}',
                ),
                onLog: () => _logCustomFood(item.id),
              );
            },
          );
        }
        return _buildEmptyState(
          icon: Icons.restaurant_menu_rounded,
          title: 'No custom foods yet',
          subtitle: 'Add your own foods with nutrition data',
        );
      },
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              'Failed to load favorites',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            BrutalButton(label: 'RETRY', onPressed: onRetry),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final startLabel = _getAddLabel().replaceFirst('ADD ', '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            BrutalButton(
              label: startLabel,
              onPressed: () => _showAddDialog(),
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard({
    required String name,
    required String subtitle,
    required VoidCallback onTap,
    required VoidCallback onLog,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0F000000),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant_rounded, color: Colors.white),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: BrutalIconButton(
          icon: Icons.add_rounded,
          onPressed: onLog,
          size: 40,
          isPrimary: true,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logFavoriteMeal(String id) async {
    try {
      await _repository.logFavoriteMeal(id);
      if (!mounted) return;
      _showMessage('Meal logged successfully');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to log favorite meal: $e');
    }
  }

  Future<void> _logTemplate(String id) async {
    try {
      await _repository.logTemplate(id);
      if (!mounted) return;
      _showMessage('Template logged successfully');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to log template: $e');
    }
  }

  Future<void> _logCustomFood(String id) async {
    try {
      await _repository.logCustomFood(id);
      if (!mounted) return;
      _showMessage('Custom food logged successfully');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to log custom food: $e');
    }
  }

  Future<void> _showAddFavoriteDialog() async {
    final foodNameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'other');
    final satietyCtrl = TextEditingController(text: '120');
    final fullnessCtrl = TextEditingController(text: '50');
    final giCtrl = TextEditingController(text: '50');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Favorite Meal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodNameCtrl,
                decoration: const InputDecoration(labelText: 'Food name'),
              ),
              TextField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: satietyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Satiety minutes'),
              ),
              TextField(
                controller: fullnessCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fullness volume'),
              ),
              TextField(
                controller: giCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Absorption rate (GI)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true) return;

    try {
      await _repository.createFavorite(
        FavoriteMeal(
          id: '',
          userId: '',
          foodName: foodNameCtrl.text.trim(),
          fullnessVolume: double.tryParse(fullnessCtrl.text.trim()) ?? 50,
          absorptionRate: double.tryParse(giCtrl.text.trim()) ?? 50,
          absorptionProfile: AbsorptionProfile.balanced,
          estimatedSatiety: int.tryParse(satietyCtrl.text.trim()) ?? 120,
          category: categoryCtrl.text.trim().isEmpty
              ? 'other'
              : categoryCtrl.text.trim(),
          usageCount: 0,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      context.read<FavoritesBloc>().add(FavoritesLoadMeals());
      _showMessage('Favorite meal added');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to add favorite: $e');
    }
  }

  Future<void> _showAddTemplateDialog() async {
    final nameCtrl = TextEditingController();
    final foodNameCtrl = TextEditingController();
    final satietyCtrl = TextEditingController(text: '120');
    final fullnessCtrl = TextEditingController(text: '50');
    final giCtrl = TextEditingController(text: '50');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Template name'),
              ),
              TextField(
                controller: foodNameCtrl,
                decoration: const InputDecoration(labelText: 'Food name'),
              ),
              TextField(
                controller: satietyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Satiety minutes'),
              ),
              TextField(
                controller: fullnessCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fullness volume'),
              ),
              TextField(
                controller: giCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Absorption rate (GI)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true) return;

    try {
      await _repository.createTemplate(
        MealTemplate(
          id: '',
          userId: '',
          name: nameCtrl.text.trim(),
          foodName: foodNameCtrl.text.trim(),
          fullnessVolume: double.tryParse(fullnessCtrl.text.trim()) ?? 50,
          absorptionRate: double.tryParse(giCtrl.text.trim()) ?? 50,
          absorptionProfile: AbsorptionProfile.balanced,
          estimatedSatiety: int.tryParse(satietyCtrl.text.trim()) ?? 120,
          category: 'other',
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      context.read<FavoritesBloc>().add(FavoritesLoadTemplates());
      _showMessage('Template added');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to add template: $e');
    }
  }

  Future<void> _showAddFoodDialog() async {
    final foodNameCtrl = TextEditingController();
    final servingCtrl = TextEditingController(text: '1 serving');
    final satietyCtrl = TextEditingController(text: '120');
    final fullnessCtrl = TextEditingController(text: '50');
    final giCtrl = TextEditingController(text: '50');

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Food'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: foodNameCtrl,
                decoration: const InputDecoration(labelText: 'Food name'),
              ),
              TextField(
                controller: servingCtrl,
                decoration: const InputDecoration(labelText: 'Serving size'),
              ),
              TextField(
                controller: satietyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Satiety minutes'),
              ),
              TextField(
                controller: fullnessCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fullness volume'),
              ),
              TextField(
                controller: giCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Absorption rate (GI)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true) return;

    try {
      await _repository.createCustomFood(
        CustomFood(
          id: '',
          userId: '',
          foodName: foodNameCtrl.text.trim(),
          fullnessVolume: double.tryParse(fullnessCtrl.text.trim()) ?? 50,
          absorptionRate: double.tryParse(giCtrl.text.trim()) ?? 50,
          absorptionProfile: AbsorptionProfile.balanced,
          estimatedSatiety: int.tryParse(satietyCtrl.text.trim()) ?? 120,
          servingSize: servingCtrl.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      context.read<FavoritesBloc>().add(FavoritesLoadFoods());
      _showMessage('Custom food added');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Failed to add custom food: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
