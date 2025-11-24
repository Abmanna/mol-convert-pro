class HplcColumn {
  final double lengthMm;
  final double diameterMm;
  final double particleSizeUm;

  const HplcColumn({
    required this.lengthMm,
    required this.diameterMm,
    required this.particleSizeUm,
  });

  // Calculate column volume (approximate, assuming porosity is similar)
  // V = pi * r^2 * L
  // We use this for gradient scaling ratios.
  double get volumeMm3 => 3.14159 * (diameterMm / 2) * (diameterMm / 2) * lengthMm;
  
  // Convert to mL (1 mL = 1000 mm3)
  double get volumeMl => volumeMm3 / 1000.0;
}
