import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/hplc_column.dart';
import '../../domain/use_cases/hplc_calculations.dart'; // Reusing GradientStep

class UspComparisonState {
  final HplcColumn originalColumn;
  final double originalFlowRate;
  final List<GradientStep> gradientSegments;
  final List<ComparisonResult> comparisons;

  UspComparisonState({
    required this.originalColumn,
    required this.originalFlowRate,
    required this.gradientSegments,
    required this.comparisons,
  });

  UspComparisonState copyWith({
    HplcColumn? originalColumn,
    double? originalFlowRate,
    List<GradientStep>? gradientSegments,
    List<ComparisonResult>? comparisons,
  }) {
    return UspComparisonState(
      originalColumn: originalColumn ?? this.originalColumn,
      originalFlowRate: originalFlowRate ?? this.originalFlowRate,
      gradientSegments: gradientSegments ?? this.gradientSegments,
      comparisons: comparisons ?? this.comparisons,
    );
  }
}

class ComparisonResult {
  final String name;
  final HplcColumn column;
  final double newFlowRate;
  final List<GradientStep> adjustedSegments;
  final double scalingFactor;
  final double originalLdp;
  final double newLdp;
  final double ldpChange;
  final bool isCompliant;
  final double totalOriginalTime;
  final double totalAdjustedTime;

  ComparisonResult({
    required this.name,
    required this.column,
    required this.newFlowRate,
    required this.adjustedSegments,
    required this.scalingFactor,
    required this.originalLdp,
    required this.newLdp,
    required this.ldpChange,
    required this.isCompliant,
    required this.totalOriginalTime,
    required this.totalAdjustedTime,
  });
}

class UspGradientNotifier extends StateNotifier<UspComparisonState> {
  UspGradientNotifier()
      : super(UspComparisonState(
          originalColumn: const HplcColumn(lengthMm: 150, diameterMm: 4.6, particleSizeUm: 5),
          originalFlowRate: 1.0,
          gradientSegments: [
            const GradientStep(time: 2, percentB: 5), // Initial Hold (using percentB as start)
            const GradientStep(time: 20, percentB: 95), // Gradient
            const GradientStep(time: 5, percentB: 95), // Wash
            const GradientStep(time: 5, percentB: 5), // Re-equilibration
          ],
          comparisons: [],
        )) {
    calculateComparisons();
  }

  // Predefined comparison columns from the user's React example
  final List<Map<String, dynamic>> _presets = [
    {'name': 'UHPLC Short Narrow', 'l': 100.0, 'd': 2.1, 'p': 3.5},
    {'name': 'Short Standard', 'l': 100.0, 'd': 4.6, 'p': 5.0},
    {'name': 'Standard Narrow', 'l': 150.0, 'd': 2.1, 'p': 5.0},
    {'name': 'Long Standard', 'l': 200.0, 'd': 4.6, 'p': 5.0},
    {'name': 'UHPLC Ultra-Short', 'l': 50.0, 'd': 2.1, 'p': 1.7},
    {'name': 'UHPLC Medium', 'l': 100.0, 'd': 3.0, 'p': 2.7},
  ];

  void updateOriginalColumn({double? length, double? diameter, double? particleSize, double? flowRate}) {
    state = state.copyWith(
      originalColumn: HplcColumn(
        lengthMm: length ?? state.originalColumn.lengthMm,
        diameterMm: diameter ?? state.originalColumn.diameterMm,
        particleSizeUm: particleSize ?? state.originalColumn.particleSizeUm,
      ),
      originalFlowRate: flowRate ?? state.originalFlowRate,
    );
    calculateComparisons();
  }

  void updateGradientSegment(int index, double time, double percentB) {
    final newSegments = List<GradientStep>.from(state.gradientSegments);
    if (index >= 0 && index < newSegments.length) {
      newSegments[index] = GradientStep(time: time, percentB: percentB);
      state = state.copyWith(gradientSegments: newSegments);
      calculateComparisons();
    }
  }

  void calculateComparisons() {
    final original = state.originalColumn;
    final flow = state.originalFlowRate;
    final segments = state.gradientSegments;

    final totalOriginalTime = segments.fold(0.0, (sum, s) => sum + s.time);
    final originalLdp = original.lengthMm / original.particleSizeUm; // Note: User example uses simple ratio L/dp (mm/um? No, usually L is mm, dp is um. 150/5 = 30. Correct.)

    final results = _presets.map((preset) {
      final col = HplcColumn(
        lengthMm: preset['l'] as double,
        diameterMm: preset['d'] as double,
        particleSizeUm: preset['p'] as double,
      );

      // Logic from React code:
      // scalingFactor = (dc2/dc1)^2 * (L2/L1)
      final scalingFactor = pow(col.diameterMm / original.diameterMm, 2) * (col.lengthMm / original.lengthMm);
      
      final newFlowRate = flow * scalingFactor;
      
      final adjustedSegments = segments.map((s) => GradientStep(
        time: s.time * scalingFactor,
        percentB: s.percentB,
      )).toList();

      final totalAdjustedTime = totalOriginalTime * scalingFactor;

      final newLdp = col.lengthMm / col.particleSizeUm;
      final ldpChange = ((newLdp - originalLdp) / originalLdp) * 100;
      final isCompliant = ldpChange >= -25 && ldpChange <= 50;

      return ComparisonResult(
        name: preset['name'] as String,
        column: col,
        newFlowRate: newFlowRate,
        adjustedSegments: adjustedSegments,
        scalingFactor: scalingFactor,
        originalLdp: originalLdp,
        newLdp: newLdp,
        ldpChange: ldpChange,
        isCompliant: isCompliant,
        totalOriginalTime: totalOriginalTime,
        totalAdjustedTime: totalAdjustedTime,
      );
    }).toList();

    state = state.copyWith(comparisons: results);
  }
}

final uspGradientProvider = StateNotifierProvider<UspGradientNotifier, UspComparisonState>((ref) {
  return UspGradientNotifier();
});
