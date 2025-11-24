import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../domain/entities/substance.dart';
import '../../domain/use_cases/prepare_acid_solution.dart';
import '../../domain/repositories/substance_repository.dart';
import '../../data/repositories/substance_repository_impl.dart';
import '../../data/datasources/local_substance_datasource.dart';

// Dependency Injection
final localDataSourceProvider = Provider<LocalSubstanceDataSource>((ref) {
  return AssetSubstanceDataSource();
});

final substanceRepositoryProvider = Provider<SubstanceRepository>((ref) {
  return SubstanceRepositoryImpl(ref.watch(localDataSourceProvider));
});

final substancesListProvider = FutureProvider<List<Substance>>((ref) async {
  final repository = ref.watch(substanceRepositoryProvider);
  final result = await repository.getSubstances();
  return switch (result) {
    Success(data: final data) => data,
    Failure(message: final msg) => throw Exception(msg),
  };
});

// State
enum AcidConverterStatus { initial, loading, success, failure }

class AcidConverterState {
  final AcidConverterStatus status;
  final AcidPrepResult? result;
  final String? errorMessage;
  final Substance? selectedAcid;
  final double stockPercent;
  final double stockDensity;
  final double targetConcentration;
  final bool isMolarity;
  final double finalVolumeMl;

  AcidConverterState({
    this.status = AcidConverterStatus.initial,
    this.result,
    this.errorMessage,
    this.selectedAcid,
    this.stockPercent = 37.0,
    this.stockDensity = 1.18,
    this.targetConcentration = 1.0,
    this.isMolarity = true,
    this.finalVolumeMl = 1000.0,
  });

  AcidConverterState copyWith({
    AcidConverterStatus? status,
    AcidPrepResult? result,
    String? errorMessage,
    Substance? selectedAcid,
    double? stockPercent,
    double? stockDensity,
    double? targetConcentration,
    bool? isMolarity,
    double? finalVolumeMl,
  }) {
    return AcidConverterState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedAcid: selectedAcid ?? this.selectedAcid,
      stockPercent: stockPercent ?? this.stockPercent,
      stockDensity: stockDensity ?? this.stockDensity,
      targetConcentration: targetConcentration ?? this.targetConcentration,
      isMolarity: isMolarity ?? this.isMolarity,
      finalVolumeMl: finalVolumeMl ?? this.finalVolumeMl,
    );
  }
}

class AcidConverterNotifier extends StateNotifier<AcidConverterState> {
  final PrepareAcidSolution _prepareAcidSolution;

  AcidConverterNotifier(this._prepareAcidSolution) : super(AcidConverterState());

  void setAcid(Substance acid) {
    state = state.copyWith(
      selectedAcid: acid,
      stockPercent: acid.typicalPercent ?? state.stockPercent,
      stockDensity: acid.densityGPerMl ?? state.stockDensity,
    );
  }

  void updateInputs({
    double? stockPercent,
    double? stockDensity,
    double? targetConcentration,
    bool? isMolarity,
    double? finalVolumeMl,
  }) {
    state = state.copyWith(
      stockPercent: stockPercent,
      stockDensity: stockDensity,
      targetConcentration: targetConcentration,
      isMolarity: isMolarity,
      finalVolumeMl: finalVolumeMl,
    );
  }

  void prepare() {
    if (state.selectedAcid == null) {
      state = state.copyWith(
        status: AcidConverterStatus.failure,
        errorMessage: 'Please select an acid first.',
      );
      return;
    }

    state = state.copyWith(status: AcidConverterStatus.loading);

    final result = _prepareAcidSolution(
      stockPercent: state.stockPercent,
      stockDensity: state.stockDensity,
      acid: state.selectedAcid!,
      targetConcentration: state.targetConcentration,
      isMolarity: state.isMolarity,
      finalVolumeMl: state.finalVolumeMl,
    );

    switch (result) {
      case Success(data: final data):
        state = state.copyWith(
          status: AcidConverterStatus.success,
          result: data,
          errorMessage: null,
        );
      case Failure(message: final msg):
        state = state.copyWith(
          status: AcidConverterStatus.failure,
          errorMessage: msg,
        );
    }
  }
}

final acidConverterProvider = StateNotifierProvider<AcidConverterNotifier, AcidConverterState>((ref) {
  return AcidConverterNotifier(const PrepareAcidSolution());
});
