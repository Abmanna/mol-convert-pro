import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/result.dart';
import '../../domain/entities/hplc_column.dart';
        state = state.copyWith(errorMessage: msg, result: null);
    }
  }
}

final hplcCalculatorProvider = StateNotifierProvider<HplcCalculatorNotifier, HplcCalculatorState>((ref) {
  return HplcCalculatorNotifier(const HplcCalculations());
});
