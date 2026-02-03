import 'package:dio/dio.dart';
import '../../../../core/services/api_service_v2.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/auth_error_handler.dart';

/// Category model
class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Repository for category operations
abstract class CategoryRepository {
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> getCategoryById(String id);
  Future<CategoryModel> createCategory({
    required String name,
    required String icon,
    required String color,
  });
  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
  });
  Future<void> deleteCategory(String id);
}

class CategoryRepositoryImpl implements CategoryRepository {
  final ApiServiceV2 _apiService;

  CategoryRepositoryImpl(this._apiService);

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await _apiService.dio.get('/categories');

      // Check response status
      if (response.statusCode != null && response.statusCode! >= 400) {
        throw Exception(
          'Failed to fetch categories: HTTP ${response.statusCode}',
        );
      }

      if (response.data == null) {
        return [];
      }

      // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
      dynamic actualData = response.data;
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data') && responseMap['data'] != null) {
          actualData = responseMap['data'];
        }
      }

      if (actualData == null) {
        return [];
      }

      List<dynamic> categoriesList;
      if (actualData is List) {
        categoriesList = actualData;
      } else {
        AppLogger.e(
          'Invalid response format: expected List, got ${actualData.runtimeType}',
          tag: 'CategoryRepository',
        );
        throw Exception(
          'Invalid response format: expected List, got ${actualData.runtimeType}',
        );
      }

      final categories = categoriesList;
      final parsedCategories = categories
          .map((json) => CategoryModel.fromJson(json))
          .toList();
      return parsedCategories;
    } on DioException catch (e) {
      AppLogger.e(
        'Failed to fetch categories',
        tag: 'CategoryRepository',
        error: e,
      );
      // Enhanced error handling for Dio exceptions
      final statusCode = e.response?.statusCode;
      final errorMessage =
          e.response?.data?['message'] ?? e.message ?? 'Unknown error';

      if (AuthErrorHandler.isAuthError(e)) {
        throw Exception(AuthErrorHandler.getAuthErrorMessage());
      } else if (statusCode == 403) {
        throw Exception('Access denied. Please check your permissions.');
      } else if (statusCode != null) {
        throw Exception(
          'Failed to fetch categories: HTTP $statusCode - $errorMessage',
        );
      } else {
        throw Exception('Failed to fetch categories: $errorMessage');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<CategoryModel> getCategoryById(String id) async {
    try {
      final response = await _apiService.dio.get('/categories/$id');

      // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
      dynamic actualData = response.data;
      if (response.data is Map && response.data['data'] != null) {
        actualData = response.data['data'];
      }

      return CategoryModel.fromJson(actualData);
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to fetch category: $message');
      }
      rethrow;
    }
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/categories',
        data: {'name': name, 'icon': icon, 'color': color},
      );

      // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
      dynamic actualData = response.data;
      if (response.data is Map && response.data['data'] != null) {
        actualData = response.data['data'];
      }

      return CategoryModel.fromJson(actualData);
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to create category: $message');
      }
      rethrow;
    }
  }

  @override
  Future<CategoryModel> updateCategory({
    required String id,
    required String name,
    required String icon,
    required String color,
  }) async {
    try {
      final response = await _apiService.dio.patch(
        '/categories/$id',
        data: {'name': name, 'icon': icon, 'color': color},
      );

      // Backend uses TransformInterceptor which wraps response in { data: ..., statusCode: ... }
      dynamic actualData = response.data;
      if (response.data is Map && response.data['data'] != null) {
        actualData = response.data['data'];
      }

      return CategoryModel.fromJson(actualData);
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to update category: $message');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _apiService.dio.delete('/categories/$id');
    } catch (e) {
      if (e is DioException) {
        final message =
            e.response?.data?['message'] ?? e.message ?? 'Unknown error';
        throw Exception('Failed to delete category: $message');
      }
      rethrow;
    }
  }
}
