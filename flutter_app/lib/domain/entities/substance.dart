class Substance {
  final String id;
  final String name;
  final String? formula;
  final String category;
  final double? molecularWeight;
  final int? basicity;
  final double? typicalPercent;
  final double? densityGPerMl;
  final List<String>? ghsPictograms;
  final bool verifiedByExpert;

  const Substance({
    required this.id,
    required this.name,
    this.formula,
    required this.category,
    this.molecularWeight,
    this.basicity,
    this.typicalPercent,
    this.densityGPerMl,
    this.ghsPictograms,
    this.verifiedByExpert = false,
    this.mgPerIu,
    this.source,
  });

  final double? mgPerIu;
  final String? source;

  factory Substance.fromJson(Map<String, dynamic> json) {
    return Substance(
      id: json['id'] as String,
      name: json['name'] as String,
      formula: json['formula'] as String?,
      category: json['category'] as String,
      molecularWeight: (json['molecularWeight'] as num?)?.toDouble(),
      basicity: json['basicity'] as int?,
      typicalPercent: (json['typicalPercent'] as num?)?.toDouble(),
      densityGPerMl: (json['densityGPerMl'] as num?)?.toDouble(),
      ghsPictograms: (json['ghsPictograms'] as List<dynamic>?)?.map((e) => e as String).toList(),
      verifiedByExpert: json['verifiedByExpert'] as bool? ?? false,
      mgPerIu: (json['mgPerIu'] as num?)?.toDouble(),
      source: json['source'] as String?,
    );
  }
}

class AcidPrepResult {
  final double stockMolarity;
  final double volumeNeededMl;
  final String instructions;

  const AcidPrepResult({
    required this.stockMolarity,
    required this.volumeNeededMl,
    required this.instructions,
  });
}
