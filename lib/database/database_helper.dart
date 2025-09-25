import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_migrations.dart';

class DatabaseHelper {
  static final int _version = migrationScripts.length;
  static const String _dbName = "myChessJourney.db";

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
      debugPrint('Executing migration script for version $i');
      for (String script in migrationScripts[i]!) {
        await db.execute(script);
      }
    }
  }

  static void _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Database Version onUpgrade: OLD: $oldVersion NEW: $newVersion');
    for (int version = oldVersion; version < newVersion; version++) {
      debugPrint('Executing migration script for version $version');
      for (String script in migrationScripts[version]!) {
        await db.execute(script);
      }
    }
  }
}