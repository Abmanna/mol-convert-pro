import 'package:flutter_test/flutter_test.dart';
import 'package:mol_convert_pro/core/result.dart';
import 'package:mol_convert_pro/domain/entities/hplc_column.dart';
import 'package:mol_convert_pro/domain/use_cases/hplc_calculations.dart';

void main() {
  const calculator = HplcCalculations();

  test('scales flow rate correctly for smaller column', () {
    // Standard 4.6mm to 2.1mm scaling
    final original = HplcColumn(lengthMm: 150, diameterMm: 4.6, particleSizeUm: 5);
    final target = HplcColumn(lengthMm: 100, diameterMm: 2.1, particleSizeUm: 1.7);
    
    final result = calculator.calculateScaling(
      originalColumn: original,
      newColumn: target,
      originalFlowRate: 1.0,
      originalGradientTime: 20.0,
    );

    expect(result, isA<Success<HplcScalingResult>>());
    final data = (result as Success<HplcScalingResult>).data;
    
    // Flow scaling: (2.1/4.6)^2 * (5/1.7) = 0.208 * 2.94 = ~0.61 mL/min
    expect(data.newFlowRate, closeTo(0.61, 0.05));
  });

  test('scales gradient time correctly', () {
    // Same column dimensions, just flow rate check
    final col = HplcColumn(lengthMm: 150, diameterMm: 4.6, particleSizeUm: 5);
    
    final result = calculator.calculateScaling(
      originalColumn: col,
      newColumn: col,
      originalFlowRate: 1.0,
      originalGradientTime: 20.0,
    );
    
    final data = (result as Success<HplcScalingResult>).data;
    expect(data.newFlowRate, 1.0);
    expect(data.newGradientTime, 20.0);
  });
}
