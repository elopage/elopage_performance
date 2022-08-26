import 'package:elopage_performance/src/models/statistics_configuration.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ConfigurationsPageController extends ChangeNotifier {
  Box<Map>? _box;

  bool get isInitialized => _box?.isOpen ?? false;
  List<StatisticsConfiguration> _configurations = [];

  List<StatisticsConfiguration> get configurations => _configurations;

  @override
  void notifyListeners() {
    _buildConfigurations();
    super.notifyListeners();
  }

  Future<void> initialize() async {
    _box = await Hive.openBox('configurations');
    notifyListeners();
  }

  Future<void> save(final StatisticsConfiguration configuration) async {
    assert(isInitialized, 'Call initialize() before use');
    await _box?.add(configuration.toJson());
    notifyListeners();
  }

  Future<void> edit(final int index, final StatisticsConfiguration value) async {
    assert(isInitialized, 'Call initialize() before use');
    await _box?.putAt(index, value.toJson());
    notifyListeners();
  }

  Future<void> delete(final int index) async {
    assert(isInitialized, 'Call initialize() before use');
    await _box?.deleteAt(index);
    notifyListeners();
  }

  Future<void> move(int oldIndex, int newIndex) async {
    assert(isInitialized, 'Call initialize() before use');
    if (newIndex > oldIndex) newIndex -= 1;

    final statistics = _configurations.removeAt(oldIndex);
    _configurations.insert(newIndex, statistics);

    await _box?.clear();
    await _box?.addAll(_configurations.map((c) => c.toJson()));
  }

  void _buildConfigurations() {
    _configurations = _box?.values.map(Map<String, dynamic>.from).map(StatisticsConfiguration.fromJson).toList() ?? [];
  }

  @override
  void dispose() {
    super.dispose();
    _box?.close();
  }
}
