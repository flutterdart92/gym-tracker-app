import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item_model.dart';

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org';

  /// Search food database by query term
  Future<List<FoodItemModel>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/cgi/search.pl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1&page_size=20',
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'GymTrackerApp - Flutter - Version 1.0'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List products = data['products'] as List? ?? [];
        return products
            .map((item) => FoodItemModel.fromOpenFoodFactsJson(
                item as Map<String, dynamic>))
            .where((item) =>
                item.name != 'Unknown Food' && item.caloriesPer100g > 0)
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching Open Food Facts: $e');
    }
    return [];
  }

  /// Lookup food item by scanned barcode
  Future<FoodItemModel?> fetchByBarcode(String barcode) async {
    final uri = Uri.parse('$_baseUrl/api/v2/product/$barcode.json');

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'GymTrackerApp - Flutter - Version 1.0'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          return FoodItemModel.fromOpenFoodFactsJson(data['product']);
        }
      }
    } catch (e) {
      debugPrint('Error looking up barcode $barcode: $e');
    }
    return null;
  }
}
