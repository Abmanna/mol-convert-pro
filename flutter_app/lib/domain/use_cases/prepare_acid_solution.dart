import '../../core/result.dart';
import '../entities/substance.dart';

class PrepareAcidSolution {
  const PrepareAcidSolution();

  Result<AcidPrepResult> call({
    required double stockPercent,
    required double stockDensity,
    required Substance acid,
    required double targetConcentration,
    required bool isMolarity,
    required double finalVolumeMl,
  }) {
    // Validation
    if (stockPercent <= 0 || stockPercent > 100) {
      return const Result.failure('Invalid stock concentration.');
    }
    if (finalVolumeMl <= 0) {
      return const Result.failure('Volume must be positive.');
    }
    if (acid.molecularWeight == null || acid.molecularWeight == 0) {
      return const Result.failure('Molecular weight missing for this substance.');
    }
    if (!isMolarity && (acid.basicity == null || acid.basicity == 0)) {
      return const Result.failure('Basicity missing for Normality calculation.');
    }

    try {
      final stockMolarity = (stockPercent * stockDensity * 10) / acid.molecularWeight!;
      final targetMolarity = isMolarity
          ? targetConcentration
          : targetConcentration / acid.basicity!.toDouble();

      if (targetMolarity > stockMolarity) {
        return const Result.failure('Target concentration exceeds stock.');
      }

      final volumeNeededMl = (targetMolarity * finalVolumeMl) / stockMolarity;

      return Result.success(
        AcidPrepResult(
          stockMolarity: stockMolarity,
          volumeNeededMl: volumeNeededMl,
          instructions: _generateInstructions(volumeNeededMl, finalVolumeMl, acid.name),
        ),
      );
    } catch (e) {
      return Result.failure('Calculation error: ${e.toString()}');
    }
  }

  String _generateInstructions(double vol, double finalVol, String acidName) =>
      'Measure ${vol.toStringAsFixed(1)} mL of $acidName. Add slowly to ~${(finalVol * 0.6).toInt()} mL water. Dilute to ${finalVol.toInt()} mL.';
}
