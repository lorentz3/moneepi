import 'package:chessjourney/model/move.dart';

class MoveDto {
  final int? id;
  final String piece;
  final String? startingCol;
  final int? startingRow;
  final String destCol;
  final int destRow;
  final int? parentMove;
  final bool longCastling;
  final bool shortCastling;
  final String? promotion;
  final bool capturePiece;
  final String? title;
  final String? description;

  MoveDto({
    this.id,
    required this.piece,
    this.startingCol,
    this.startingRow,
    required this.destCol,
    required this.destRow,
    this.parentMove,
    this.longCastling = false,
    this.shortCastling = false,
    this.promotion,
    this.capturePiece = false,
    this.title,
    this.description,
  });

  factory MoveDto.fromJson(Map<String, dynamic> json) => MoveDto(
    id: json['id'],
    piece: json['piece'],
    startingCol: json['startingCol'],
    startingRow: json['startingRow'],
    destCol: json['destCol'],
    destRow: json['destRow'],
    parentMove: json['parentMove'],
    longCastling: _toBool(json['longCastling']),
    shortCastling: _toBool(json['shortCastling']),
    promotion: json['promotion'],
    capturePiece: _toBool(json['capturePiece']),
    title: json['title'],
    description: json['description'],
  );

  factory MoveDto.fromMove(Move move) => MoveDto(
    id: move.id,
    piece: move.piece,
    startingCol: move.startingCol,
    startingRow: move.startingRow,
    destCol: move.destCol,
    destRow: move.destRow,
    parentMove: move.parentMove,
    longCastling: move.longCastling,
    shortCastling: move.shortCastling,
    promotion: move.promotion,
    capturePiece: move.capturePiece,
    title: move.title,
    description: move.description,
  );
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value == '1' || value.toLowerCase() == 'true';
  return false;
}


