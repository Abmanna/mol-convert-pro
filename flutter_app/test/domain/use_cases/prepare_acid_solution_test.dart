import 'package:flutter_test/flutter_test.dart';
import 'package:mol_convert_pro/core/result.dart';
import 'package:mol_convert_pro/domain/entities/substance.dart';
import 'package:mol_convert_pro/domain/use_cases/prepare_acid_solution.dart';

void main() {
  const useCase = PrepareAcidSolution();

  test('returns volume for valid HCl dilution', () {
    final acid = Substance(
      id: 'hcl',
      name: 'HCl',
      molecularWeight: 36.46,
      basicity: 1,
      category: 'acid',
    );

    final result = useCase(
      stockPercent: 37,
      stockDensity: 1.18,
      acid: acid,
      targetConcentration: 1,
      isMolarity: true,
      finalVolumeMl: 500,
    );

    expect(result, isA<Success<AcidPrepResult>>());
    final success = result as Success<AcidPrepResult>;
    // Stock M = (37 * 1.18 * 10) / 36.46 = 11.97 M
    // Vol = (1 * 500) / 11.97 = 41.77 mL
    expect(success.data.volumeNeededMl, closeTo(41.7, 0.2));
  });

  test('fails when target > stock', () {
    final acid = Substance(
      id: 'hcl',
      name: 'HCl',
      molecularWeight: 36.46,
      basicity: 1,
      category: 'acid',
    );

    final result = useCase(
      stockPercent: 1, // Very dilute stock
      stockDensity: 1.0,
      acid: acid,
      targetConcentration: 10, // High target
      isMolarity: true,
      finalVolumeMl: 500,
    );

    expect(result, isA<Failure>());
  });
}
