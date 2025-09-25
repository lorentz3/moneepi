class Move {
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

  Move({
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
}


