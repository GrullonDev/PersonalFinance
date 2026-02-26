import 'package:dartz/dartz.dart';

import 'package:personal_finance/core/error/exceptions.dart';
import 'package:personal_finance/core/error/failures.dart';
import 'package:personal_finance/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:personal_finance/features/categories/data/models/category_model.dart';
import 'package:personal_finance/features/categories/domain/entities/category.dart';
import 'package:personal_finance/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._remote);

  final CategoryRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final List<CategoryModel> list = await _remote.getCategories();
      return Right(list.map((CategoryModel e) => e.toEntity()).toList());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      final CategoryModel created = await _remote.createCategory(
        CategoryModel.fromEntity(category),
      );
      return Right(created.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      final CategoryModel updated = await _remote.updateCategory(
        category.id,
        CategoryModel.fromEntity(category),
      );
      return Right(updated.toEntity());
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCategory(String categoryId) async {
    try {
      await _remote.deleteCategory(categoryId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
