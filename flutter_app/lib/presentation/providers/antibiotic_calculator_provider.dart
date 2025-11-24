import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../domain/entities/substance.dart';
import '../../domain/use_cases/calculate_antibiotic_stock.dart';
import '../../domain/use_cases/convert_antibiotic_units.dart';

class AntibioticCalculatorState {
  final Substance? selectedAntibiotic;
  // Stock Calc State
  final double targetConcentration; // IU/mL
  final double finalVolumeMl;
  final AntibioticStockResult? stockResult;
  
  // Converter State
  final double convertValue;
  final String convertUnit; // 'IU', 'mg', 'mcg'
  final ConversionResult? conversionResult;

  final String? errorMessage;
  final int selectedTab; // 0 = Stock, 1 = Converter

  AntibioticCalculatorState({
    this.selectedAntibiotic,
    this.targetConcentration = 1000.0,
    this.finalVolumeMl = 10.0,
    this.stockResult,
    this.convertValue = 1000.0,
    this.convertUnit = 'IU',
    this.conversionResult,
    this.errorMessage,
    this.selectedTab = 0,
  });

  AntibioticCalculatorState copyWith({
    Substance? selectedAntibiotic,
    double? targetConcentration,
    double? finalVolumeMl,
    AntibioticStockResult? stockResult,
    double? convertValue,
    String? convertUnit,
    ConversionResult? conversionResult,
    String? errorMessage,
    int? selectedTab,
  }) {
    return AntibioticCalculatorState(
      selectedAntibiotic: selectedAntibiotic ?? this.selectedAntibiotic,
      targetConcentration: targetConcentration ?? this.targetConcentration,
      finalVolumeMl: finalVolumeMl ?? this.finalVolumeMl,
      stockResult: stockResult ?? this.stockResult,
      convertValue: convertValue ?? this.convertValue,
      convertUnit: convertUnit ?? this.convertUnit,
      conversionResult: conversionResult ?? this.conversionResult,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class AntibioticCalculatorNotifier extends StateNotifier<AntibioticCalculatorState> {
  final CalculateAntibioticStock _stockCalculator;
  final ConvertAntibioticUnits _unitConverter;

  AntibioticCalculatorNotifier(this._stockCalculator, this._unitConverter) : super(AntibioticCalculatorState());

  void setTab(int index) {
    state = state.copyWith(selectedTab: index, errorMessage: null);
  }

  void setAntibiotic(Substance antibiotic) {
    state = state.copyWith(selectedAntibiotic: antibiotic);
  }

  void updateInputs({double? concentration, double? volume}) {
    state = state.copyWith(
      targetConcentration: concentration ?? state.targetConcentration,
      finalVolumeMl: volume ?? state.finalVolumeMl,
    );
  }

  void updateConverterInputs({double? value, String? unit}) {
    state = state.copyWith(
      convertValue: value ?? state.convertValue,
      convertUnit: unit ?? state.convertUnit,
    );
  }

  void calculate() {
    if (state.selectedAntibiotic == null) {
      state = state.copyWith(errorMessage: 'Please select an antibiotic.');
      return;
    }

    if (state.selectedTab == 0) {
      _calculateStock();
    } else {
      _calculateConversion();
    }
  }

  void _calculateStock() {
    final result = _stockCalculator(
      antibiotic: state.selectedAntibiotic!,
      targetConcentration: state.targetConcentration,
      finalVolumeMl: state.finalVolumeMl,
    );

    switch (result) {
      case Success(data: final data):
        state = state.copyWith(stockResult: data, errorMessage: null);
      case Failure(message: final msg):
        state = state.copyWith(errorMessage: msg, stockResult: null);
    }
  }

  void _calculateConversion() {
    final result = _unitConverter(
      antibiotic: state.selectedAntibiotic!,
      value: state.convertValue,
      fromUnit: state.convertUnit,
    );

    switch (result) {
      case Success(data: final data):
        state = state.copyWith(conversionResult: data, errorMessage: null);
      case Failure(message: final msg):
        state = state.copyWith(errorMessage: msg, conversionResult: null);
    }
  }
}

final antibioticCalculatorProvider = StateNotifierProvider<AntibioticCalculatorNotifier, AntibioticCalculatorState>((ref) {
  return AntibioticCalculatorNotifier(
    const CalculateAntibioticStock(),
    const ConvertAntibioticUnits(),
  );
});
