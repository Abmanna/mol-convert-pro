import 'dart:math';
import '../../core/result.dart';
import '../entities/hplc_column.dart';

class GradientStep {
  final double time;
  final double percentB;
  const GradientStep({required this.time, required this.percentB});
}

class HplcScalingResult {
  final double newFlowRate;
  final List<GradientStep> newGradientTable;
  final double flowRateScaleFactor;
  final double gradientTimeScaleFactor;
  final double originalLdpRatio;
  final double newLdpRatio;
  final double ldpChangePercent;
  final bool isLdpCompliant;
  
  // New Critical Calculations
  final double? estimatedNewPressure;
  final double? dwellVolumeAdjustmentTime; // Positive = Add Hold, Negative = Add Delay
  final String? pressureWarning;

  const HplcScalingResult({
    required this.newFlowRate,
    required this.newGradientTable,
    required this.flowRateScaleFactor,
    required this.gradientTimeScaleFactor,
    required this.originalLdpRatio,
    required this.newLdpRatio,
    required this.ldpChangePercent,
    required this.isLdpCompliant,
    this.estimatedNewPressure,
    this.dwellVolumeAdjustmentTime,
    this.pressureWarning,
  });
}

class HplcCalculations {
  const HplcCalculations();

  Result<HplcScalingResult> calculateScaling({
    required HplcColumn originalColumn,
    required HplcColumn newColumn,
    required double originalFlowRate,
    required List<GradientStep> originalGradient,
    double? originalPressure, // bar or psi
    double? originalDwellVolume, // mL
    double? newDwellVolume, // mL
  }) {
    if (originalColumn.diameterMm <= 0 || newColumn.diameterMm <= 0 || 
        originalColumn.particleSizeUm <= 0 || newColumn.particleSizeUm <= 0) {
      return const Result.failure('Invalid column dimensions.');
    }

    try {
      // 1. Flow Rate Scaling (USP <621>)
      // F2 = F1 * (dc2/dc1)^2 * (dp1/dp2)  <-- Note: USP allows adjusting flow for particle size to maintain reduced velocity, 
      // but strictly F2 = F1 * (dc2/dc1)^2 is for constant linear velocity if dp is unchanged.
      // If dp changes, maintaining efficiency often requires F2 = F1 * (dc2/dc1)^2 * (dp1/dp2).
      // Let's stick to the standard geometric scaling for now which includes particle size effect on optimum velocity.
      
      final diameterRatioSq = pow(newColumn.diameterMm / originalColumn.diameterMm, 2);
      final particleRatio = originalColumn.particleSizeUm / newColumn.particleSizeUm;
      
      final newFlowRate = originalFlowRate * diameterRatioSq * particleRatio;

      // 2. Gradient Time Scaling
      // t2 = t1 * (F1/F2) * (Vm2/Vm1)
      // Vm ratio approx (L2*dc2^2) / (L1*dc1^2)
      final volumeRatio = (newColumn.lengthMm * pow(newColumn.diameterMm, 2)) / 
                          (originalColumn.lengthMm * pow(originalColumn.diameterMm, 2));
      
      final flowRatio = originalFlowRate / newFlowRate;
      final timeScaleFactor = flowRatio * volumeRatio; // This simplifies to (L2/L1) * (dc2/dc1)^2 * (F1/F2)
      
      // If F2 is scaled by dp1/dp2, then timeScaleFactor simplifies further.
      
      final newGradientTable = originalGradient.map((step) => GradientStep(
        time: step.time * timeScaleFactor,
        percentB: step.percentB,
      )).toList();

      // 3. L/dp Ratio Check
      final originalLdp = (originalColumn.lengthMm * 1000) / originalColumn.particleSizeUm; // L in mm * 1000 / um = dimensionless? No, L/dp is usually length(mm)/dp(um) or length(cm)/dp(um). 
      // USP <621> uses L(mm)/dp(um) for the ratio calculation range -25% to +50%.
      // Actually USP says "L/dp" where L is length and dp is particle size. 
      // Let's use the raw values L(mm)/dp(um) as is standard in these calculators.
      final calcOriginalLdp = originalColumn.lengthMm / originalColumn.particleSizeUm;
      final calcNewLdp = newColumn.lengthMm / newColumn.particleSizeUm;
      final ldpChange = ((calcNewLdp - calcOriginalLdp) / calcOriginalLdp) * 100;
      final isCompliant = ldpChange >= -25 && ldpChange <= 50;

      // 4. Backpressure Estimation
      // P2 = P1 * (L2/L1) * (dc1/dc2)^2 * (dp1/dp2)^2 * (F2/F1) ?
      // Simpler: P is proportional to Flow * Length / (Diameter^2 * Particle^2) ?
      // Actually P ~ (Flow * Length * Viscosity) / (Diameter^2 * Particle^2)
      // So Ratio P2/P1 = (F2/F1) * (L2/L1) * (dc1/dc2)^2 * (dp1/dp2)^2
      double? estimatedPressure;
      String? pressWarn;
      
      if (originalPressure != null) {
        final pressureFactor = (newFlowRate / originalFlowRate) *
                               (newColumn.lengthMm / originalColumn.lengthMm) *
                               pow(originalColumn.diameterMm / newColumn.diameterMm, 2) *
                               pow(originalColumn.particleSizeUm / newColumn.particleSizeUm, 2);
        estimatedPressure = originalPressure * pressureFactor;

        if (estimatedPressure > 400 && estimatedPressure <= 600) {
          pressWarn = 'Warning: Pressure > 400 bar. Ensure UHPLC system.';
        } else if (estimatedPressure > 600) {
          pressWarn = 'Critical: Pressure > 600 bar. Requires high-end UHPLC.';
        }
      }

      // 5. Dwell Volume Adjustment
      // Time shift = (Vm_new - Vm_old_scaled) / F_new ? 
      // USP Formula: "If the dwell volume... is different... an isocratic hold... may be needed."
      // We want the gradient to arrive at the column inlet at the same relative time.
      // Delay1 = Vd1 / F1. Delay2 = Vd2 / F2.
      // We want (Time_at_column)_2 = (Time_at_column)_1 * ScaleFactor
      // (t_programmed_2 - Delay2) = (t_programmed_1 - Delay1) * ScaleFactor
      // t_programmed_2 = (t_programmed_1 - Delay1) * ScaleFactor + Delay2
      // But we applied ScaleFactor to t_programmed_1 already (let's call that t_scaled).
      // So t_programmed_2 = t_scaled - (Delay1 * ScaleFactor) + Delay2
      // Adjustment = Delay2 - (Delay1 * ScaleFactor)
      
      double? dwellAdj;
      if (originalDwellVolume != null && newDwellVolume != null) {
        final delay1 = originalDwellVolume / originalFlowRate;
        final delay2 = newDwellVolume / newFlowRate;
        
        // The timeScaleFactor applies to the chromatography (retention), not the system delay.
        // But we scaled the *programmed* time.
        // If we simply scaled the table, we scaled the delay implicitly? No.
        // We need to correct the start time.
        
        // Adjustment to ADD to the start of the gradient (Isocratic Hold):
        // We need the gradient to reach the column at t_ideal_start.
        // t_ideal_start (at column) = 0 (usually).
        // If we have a difference in delay volumes relative to flow, we adjust.
        
        // Let's use the formula: Adjustment = (Vd2 - Vd1 * (F2/F1) * (L2/L1)?? No.)
        // Let's use the time difference approach:
        // We want the gradient to hit the column at the same relative point.
        // Relative Delay 1 = Vd1 / F1 / t0_1 (in column volumes? no).
        
        // Standard approach:
        // Adjustment (min) = (Vd2 - Vd1 * ScaleFactor_Volume?) No.
        
        // Correct logic:
        // We scaled the gradient table assuming "Time 0" is injection.
        // The gradient actually starts hitting the column at t = Vd/F.
        // We want (Vd2/F2) to be equivalent to (Vd1/F1) * TimeScaleFactor.
        // If (Vd2/F2) < (Vd1/F1) * TimeScaleFactor, we need to DELAY the gradient start (add Hold).
        // If (Vd2/F2) > (Vd1/F1) * TimeScaleFactor, we ideally start gradient "earlier" (Injection Delay).
        
        final targetDelay2 = delay1 * timeScaleFactor;
        dwellAdj = targetDelay2 - delay2; 
        // If positive: New system is "faster" than scaled target. We need to wait. Add Isocratic Hold.
        // If negative: New system is "slower". We need to inject "later" or start gradient "sooner". (Pre-gradient start).
      }

      return Result.success(HplcScalingResult(
        newFlowRate: newFlowRate,
        newGradientTable: newGradientTable,
        flowRateScaleFactor: newFlowRate / originalFlowRate,
        gradientTimeScaleFactor: timeScaleFactor,
        originalLdpRatio: calcOriginalLdp,
        newLdpRatio: calcNewLdp,
        ldpChangePercent: ldpChange,
        isLdpCompliant: isCompliant,
        estimatedNewPressure: estimatedPressure,
        pressureWarning: pressWarn,
        dwellVolumeAdjustmentTime: dwellAdj,
      ));
    } catch (e) {
      return Result.failure('Calculation error: $e');
    }
  }
}
