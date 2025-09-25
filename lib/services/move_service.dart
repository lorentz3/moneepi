import 'package:chessjourney/database/database_helper.dart';
import 'package:flutter/foundation.dart';

class MoveService {

  static const String _tableName = 'Moves';

  static Future<List<Map<String, dynamic>>> getRootMoves() async {
    final db = await DatabaseHelper.getDb();
    final result = await db.query(
      _tableName,
      where: 'parentMove IS NULL',
    );
    debugPrint('getRootMoves: $result');
    return result;
  }
}


