import '../../core/result.dart';
import '../entities/substance.dart';

abstract class SubstanceRepository {
  Future<Result<List<Substance>>> getSubstances();
  Future<Result<Substance>> getSubstanceById(String id);
}
