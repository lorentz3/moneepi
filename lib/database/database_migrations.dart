import 'package:chessjourney/database/database_defaults.dart';

Map<int, List<String>> migrationScripts = {
    0: [
      """
        CREATE TABLE Moves (
          id INTEGER PRIMARY KEY,
          piece TEXT NOT NULL,
          startingCol TEXT,
          startingRow INTEGER,
          destCol TEXT NOT NULL,
          destRow INTEGER NOT NULL,
          parentMove INTEGER,
          longCastling BOOLEAN NOT NULL DEFAULT FALSE,
          shortCastling BOOLEAN NOT NULL DEFAULT FALSE,
          promotion TEXT,
          capturePiece BOOLEAN NOT NULL DEFAULT FALSE,
          title TEXT,
          description TEXT,
          FOREIGN KEY(parentMove) REFERENCES Moves(id));
      """,
      insertDefaultMovesQuery,
    ],
  };