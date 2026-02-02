import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/filter/filter_bloc.dart';
import '../models/photo.dart';
import '../theme/colors.dart';

class FilterSelectionScreen extends StatelessWidget {
  const FilterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ObscuraColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sélection de Filtres',
          style: TextStyle(
            color: ObscuraColors.textSecondary,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: ObscuraColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<FilterBloc, FilterState>(
          builder: (context, state) {
            final selectedFilter = (state as FilterSelected).selectedFilter;

            return GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildFilterOption(
                  context,
                  FilterType.none,
                  'Aucun',
                  Icons.clear,
                  ObscuraColors.filterNone,
                  selectedFilter == FilterType.none,
                ),
                _buildFilterOption(
                  context,
                  FilterType.monochrome,
                  'Monochrome',
                  Icons.filter_b_and_w,
                  ObscuraColors.filterMonochrome,
                  selectedFilter == FilterType.monochrome,
                ),
                _buildFilterOption(
                  context,
                  FilterType.sepia,
                  'Sépia',
                  Icons.gradient,
                  ObscuraColors.filterSepia,
                  selectedFilter == FilterType.sepia,
                ),
                _buildFilterOption(
                  context,
                  FilterType.glassPlate,
                  'Plaque de Verre',
                  Icons.lens,
                  ObscuraColors.filterGlassPlate,
                  selectedFilter == FilterType.glassPlate,
                ),
                _buildFilterOption(
                  context,
                  FilterType.cyanotype,
                  'Cyanotype',
                  Icons.water_drop,
                  ObscuraColors.filterCyanotype,
                  selectedFilter == FilterType.cyanotype,
                ),
                _buildFilterOption(
                  context,
                  FilterType.daguerreotype,
                  'Daguerréotype',
                  Icons.brightness_high,
                  ObscuraColors.filterDaguerreotype,
                  selectedFilter == FilterType.daguerreotype,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    FilterType filter,
    String name,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<FilterBloc>().add(SelectFilter(filter));
        HapticFeedback.selectionClick();
        context.pop();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : ObscuraColors.overlayMedium,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? color : ObscuraColors.textSubtle,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? color : ObscuraColors.textHint,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? ObscuraColors.textPrimary : ObscuraColors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    color: ObscuraColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
