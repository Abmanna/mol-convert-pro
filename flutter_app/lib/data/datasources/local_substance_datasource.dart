import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/exceptions.dart';
import '../../domain/entities/substance.dart';

abstract class LocalSubstanceDataSource {
  Future<List<Substance>> loadSubstances();
}

class AssetSubstanceDataSource implements LocalSubstanceDataSource {
  final String assetPath;

  AssetSubstanceDataSource({this.assetPath = 'assets/substances.json'});

  @override
  Future<List<Substance>> loadSubstances() async {
    try {
      // In a real app, we might check a local DB (Hive/Drift) first.
      // Here we simulate loading from the bundled JSON asset.
      // Note: In a real Flutter app, rootBundle is used.
      // We assume the asset is available in the bundle.
      final jsonString = await rootBundle.loadString('../$assetPath');
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Substance.fromJson(json)).toList();
    } catch (e) {
      throw CacheException('Failed to load substances: $e');
    }
  }
}
