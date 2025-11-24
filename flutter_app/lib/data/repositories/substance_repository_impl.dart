import '../../core/result.dart';
import '../../core/exceptions.dart';
import '../../domain/entities/substance.dart';
import '../../domain/repositories/substance_repository.dart';
import '../datasources/local_substance_datasource.dart';

class SubstanceRepositoryImpl implements SubstanceRepository {
  final LocalSubstanceDataSource dataSource;

  SubstanceRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Substance>>> getSubstances() async {
    try {
      final substances = await dataSource.loadSubstances();
      return Result.success(substances);
    } on CacheException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }

  @override
  Future<Result<Substance>> getSubstanceById(String id) async {
    try {
      final substances = await dataSource.loadSubstances();
      final substance = substances.firstWhere(
        (s) => s.id == id,
        orElse: () => throw CacheException('Substance not found'),
      );
      return Result.success(substance);
    } on CacheException catch (e) {
      return Result.failure(e.message);
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }
}
