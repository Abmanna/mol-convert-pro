import '../../core/result.dart';
import '../entities/substance.dart';

class AntibioticStockResult {
  final double massNeededMg;
  final double totalUnits;
  final String instructions;

  const AntibioticStockResult({
    required this.massNeededMg,
    required this.totalUnits,
    required this.instructions,
  });
}

class CalculateAntibioticStock {
  const CalculateAntibioticStock();

  Result<AntibioticStockResult> call({
    required Substance antibiotic,
    required double targetConcentration, // IU/mL
    required double finalVolumeMl,
  }) {
    if (antibiotic.mgPerIu == null) {
      return const Result.failure('Conversion factor (mg/IU) not available for this substance.');
    }
    if (targetConcentration <= 0 || finalVolumeMl <= 0) {
      return const Result.failure('Concentration and volume must be positive.');
    }

    try {
      // Total Units needed = Conc (IU/mL) * Vol (mL)
      final totalUnits = targetConcentration * finalVolumeMl;
      
      // Mass needed (mg) = Total Units * (mg/IU)
      final massNeededMg = totalUnits * antibiotic.mgPerIu!;

      return Result.success(AntibioticStockResult(
        massNeededMg: massNeededMg,
        totalUnits: totalUnits,
        instructions: _generateInstructions(massNeededMg, finalVolumeMl, antibiotic.name),
      ));
    } catch (e) {
      return Result.failure('Calculation error: $e');
    }
  }

  String _generateInstructions(double massMg, double vol, String name) {
    final massFormatted = massMg >= 1000 
        ? '${(massMg / 1000).toStringAsFixed(3)} g' 
        : '${massMg.toStringAsFixed(1)} mg';
        
    return 'Weigh $massFormatted of $name. Dissolve in sufficient solvent to make ${vol.toStringAsFixed(1)} mL.';
  }
}
