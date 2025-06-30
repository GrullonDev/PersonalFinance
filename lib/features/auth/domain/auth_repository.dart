import 'package:personal_finance/features/auth/domain/auth_datasource.dart';

abstract class AuthRepository {
  Future<void> signInWithGoogle();
  Future<void> signInWithFacebook();
  Future<void> signInWithApple();
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  Future<void> signInWithGoogle() => dataSource.signInWithGoogle();

  @override
  Future<void> signInWithFacebook() => dataSource.signInWithFacebook();

  @override
  Future<void> signInWithApple() => dataSource.signInWithApple();

  @override
  Future<void> logout() => dataSource.logout();
}
