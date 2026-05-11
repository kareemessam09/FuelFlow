import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/entities.dart';
import '../../widgets/common/common.dart';
import '../../blocs/blocs.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load today's meals initially
    context.read<MealsBloc>().add(MealsLoadToday());
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 0) {
        context.read<MealsBloc>().add(MealsLoadToday());
      } else {
        context.read<MealsBloc>().add(MealsLoadHistory());
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MEAL HISTORY'),
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
            Tab(text: 'TODAY'),
            Tab(text: 'ALL TIME'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTodayMeals(), _buildAllMeals()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/meal-capture'),
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('ADD MEAL'),
      ),
    );
  }

  Widget _buildTodayMeals() {
    return BlocBuilder<MealsBloc, MealsState>(
      builder: (context, state) {
        if (state is MealsLoading) {
          return const SkeletonList(itemCount: 4);
        } else if (state is MealsLoaded && state.isTodayOnly) {
          return _buildMealList(state.meals, isToday: true);
        } else if (state is MealsError) {
          return _buildError(state.message, true);
        }
        return _buildMealList([], isToday: true);
      },
    );
  }

  Widget _buildAllMeals() {
    return BlocBuilder<MealsBloc, MealsState>(
      builder: (context, state) {
        if (state is MealsLoading) {
          return const SkeletonList(itemCount: 6);
        } else if (state is MealsLoaded && !state.isTodayOnly) {
          return _buildMealList(state.meals, isToday: false);
        } else if (state is MealsError) {
          return _buildError(state.message, false);
        }
        return _buildMealList([], isToday: false);
      },
    );
  }

  Widget _buildError(String message, bool isToday) {
    return StateFeedback(
      icon: Icons.error_outline_rounded,
      title: 'Couldn\'t load meals',
      description: message,
      actionLabel: 'RETRY',
      onAction: () {
        if (isToday) {
          context.read<MealsBloc>().add(MealsLoadToday());
        } else {
          context.read<MealsBloc>().add(MealsLoadHistory());
        }
      },
    );
  }

  Widget _buildMealList(List<MealLog> meals, {bool isToday = false}) {
    if (meals.isEmpty) {
      return StateFeedback(
        icon: isToday ? Icons.wb_sunny_rounded : Icons.restaurant_rounded,
        title: isToday ? 'No meals today' : 'No meals logged yet',
        description: isToday
            ? 'Snap a photo of your next meal to start tracking.'
            : 'Your complete meal history will appear here.',
        actionLabel: 'ADD MEAL',
        onAction: () => context.push('/meal-capture'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        return _buildMealCard(meals[index]);
      },
    );
  }

  Widget _buildMealCard(MealLog meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Food image or placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: meal.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(meal.imageUrl!, fit: BoxFit.cover),
                  )
                : const Icon(Icons.restaurant, color: Colors.white),
          ),
          const SizedBox(width: 16),

          // Meal info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fullness: ${meal.fullnessVolume.toInt()}% • GI: ${meal.absorptionRate.toInt()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(meal.createdAt),
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
