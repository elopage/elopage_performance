import 'package:get_it/get_it.dart';

import 'jira/jira.dart';

final serviceLocator = ServiceLocatorImpl(GetIt.instance);

abstract class ServiceLocator {
  Future<void> reset();
  void initializeDependencies();
  T call<T extends Object>();
  Future<T> getAsync<T extends Object>();
  void disposeLazySingleton<T extends Object>(void Function(T) disposingFunction);
  T getWithParams<T extends Object>({String? instanceName, dynamic param1, dynamic param2});
  Future<T> getAsyncWithParams<T extends Object>({String? instanceName, dynamic param1, dynamic param2});
}

class ServiceLocatorImpl implements ServiceLocator {
  const ServiceLocatorImpl(this.getIt);

  final GetIt getIt;
  @override
  void initializeDependencies() {
    getIt.registerSingleton<Jira>(Jira());
  }

  @override
  Future<void> reset() async {}

  @override
  T call<T extends Object>() => getIt<T>();

  @override
  Future<T> getAsync<T extends Object>() => getIt.getAsync<T>();

  @override
  void disposeLazySingleton<T extends Object>(void Function(T) disposingFunction) {
    getIt.resetLazySingleton<T>(disposingFunction: disposingFunction);
  }

  @override
  T getWithParams<T extends Object>({String? instanceName, dynamic param1, dynamic param2}) => getIt<T>(
        instanceName: instanceName,
        param2: param2,
        param1: param1,
      );

  @override
  Future<T> getAsyncWithParams<T extends Object>({String? instanceName, dynamic param1, dynamic param2}) =>
      getIt.getAsync<T>(
        instanceName: instanceName,
        param2: param2,
        param1: param1,
      );
}
