import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  static const String boxName = 'cowBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(boxName);
  }

  static Future<void> insertCow(Map<String, dynamic> cow) async {
    final box = Hive.box<Map>(boxName);
    await box.add(cow);
  }

  static List<Map<String, dynamic>> getAllCows() {
    final box = Hive.box<Map>(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> updateCow(int index, Map<String, dynamic> cow) async {
    final box = Hive.box<Map>(boxName);
    await box.putAt(index, cow);
  }

  static Future<void> deleteCow(int index) async {
    final box = Hive.box<Map>(boxName);
    await box.deleteAt(index);
  }
}
