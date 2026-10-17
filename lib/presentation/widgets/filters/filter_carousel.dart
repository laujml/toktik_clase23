import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/domain/entities/camera_filter.dart';
import 'package:toktok/presentation/providers/face_filter_provider.dart';

class FilterCarousel extends StatelessWidget {
  const FilterCarousel({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<FaceFilterProvider>().selected;
    final height = MediaQuery.sizeOf(context).height;
    final chipHeight = height < 700 ? 40.0 : 48.0;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: CameraFilter.values.length,
      separatorBuilder: (context, index) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final filter = CameraFilter.values[index];
        final isSelected = filter == selected;
        return Align(
          alignment: Alignment.center,
          child: Semantics(
            button: true,
            selected: isSelected,
            enabled: enabled,
            label: 'Filtro ${filter.label}',
            child: ExcludeSemantics(
              child: ChoiceChip(
                label: Text(filter.label),
                selected: isSelected,
                visualDensity: VisualDensity.comfortable,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                labelPadding: EdgeInsets.symmetric(
                  horizontal: height < 700 ? 8 : 12,
                ),
                onSelected: enabled
                    ? (_) => context.read<FaceFilterProvider>().select(filter)
                    : null,
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFF48FB1)
                      : Colors.white24,
                ),
                selectedColor: const Color(0xFF5C3144),
                backgroundColor: const Color(0xCC1A1A1A),
                labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: chipHeight < 44 ? 14 : 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
