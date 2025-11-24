import '../../core/result.dart';
import '../entities/substance.dart';

class ConversionResult {
  final double inputValue;
  final String inputUnit;
  final double resultIU;
  final double resultMg;
  final double resultMcg;

  const ConversionResult({
    required this.inputValue,
    required this.inputUnit,
    required this.resultIU,
    required this.resultMg,
    required this.resultMcg,
  });
}

class ConvertAntibioticUnits {
  const ConvertAntibioticUnits();

  Result<ConversionResult> call({
    required Substance antibiotic,
    required double value,
    required String fromUnit, // 'IU', 'mg', 'mcg'
  }) {
    if (antibiotic.mgPerIu == null) {
      return const Result.failure('Conversion factor not available.');
    }
    if (value < 0) {
      return const Result.failure('Value must be non-negative.');
    }

    try {
      double mg;
      double iu;
      double mcg;

      switch (fromUnit) {
        case 'IU':
          iu = value;
          mg = iu * antibiotic.mgPerIu!;
          mcg = mg * 1000;
          break;
        case 'mg':
          mg = value;
          iu = mg / antibiotic.mgPerIu!;
          mcg = mg * 1000;
          break;
        case 'mcg':
          mcg = value;
          mg = mcg / 1000;
          iu = mg / antibiotic.mgPerIu!;
          break;
        default:
          return const Result.failure('Invalid unit.');
      }

      return Result.success(ConversionResult(
        inputValue: value,
        inputUnit: fromUnit,
        resultIU: iu,
        resultMg: mg,
        resultMcg: mcg,
      ));
    } catch (e) {
      return Result.failure('Conversion error: $e');
    }
  }
}
