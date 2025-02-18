import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_migrations.dart';

class DatabaseHelper {
  static const int _version = 1;
  static const String _dbName = "myHealth.db";

  static Future<Database> getDb() async {
    return openDatabase(join(await getDatabasesPath(), _dbName),
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  
  static void _onCreate(Database db, int version) async {
    debugPrint('Database Version onCreate: $version');
    int maxVersion = migrationScripts.length;
    for (int i = 0; i < maxVersion; i++) {
      debugPrint('Executing migration script number $i');
      await db.execute(migrationScripts[i]!);
    }
  }

  static void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database Version onUpgrade: OLD: $oldVersion NEW: $newVersion');
    for (int version = oldVersion; version < newVersion; version++) {
      debugPrint('Executing migration script number $version');
      await db.execute(migrationScripts[version]!);
    }
  }
}