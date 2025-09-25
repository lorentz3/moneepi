import 'package:chessjourney/dto/move_dto.dart';
import 'package:chessjourney/services/move_service.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:chessjourney/widgets/square_button.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';

void main() {
  if (!f.kIsWeb && (f.defaultTargetPlatform == TargetPlatform.windows || f.defaultTargetPlatform == TargetPlatform.linux || f.defaultTargetPlatform == TargetPlatform.macOS)) {
    ffi.sqfliteFfiInit();
    sqflite.databaseFactory = ffi.databaseFactoryFfi;
  }
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChessJourneyApp());
}

class ChessJourneyApp extends StatelessWidget {
  const ChessJourneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChessJourney',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<MoveDto>>? _rootMovesFuture;
  bool _isWhiteToPlay = true; // Track which player should play
  late ChessBoardController _chessController;

  @override
  void initState() {
    super.initState();
    _chessController = ChessBoardController();
    _rootMovesFuture = _loadRootMoves();
  }

  Future<List<MoveDto>> _loadRootMoves() async {
    final rows = await MoveService.getRootMoves();
    return rows.map((e) => MoveDto.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChessJourney'),
      ),
      body: Column(
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '1.  ${_isWhiteToPlay ? 'White' : 'Black'} to move',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add move',
                  onPressed: _openAddMoveDialog,
                ),
              ],
            ),
          ),
          // Scrollable moves list
          Expanded(
            child: FutureBuilder<List<MoveDto>>(
              future: _rootMovesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final moves = snapshot.data ?? [];
                if (moves.isEmpty) {
                  return const Center(child: Text('No moves yet.'));
                }
                return ListView.builder(
                  itemCount: moves.length,
                  itemBuilder: (context, index) {
                    final m = moves[index];
                    final label = '${m.destCol}${m.destRow}';
                    return ListTile(
                      leading: SquareButton(
                        label: label,
                        imagePath: _getImagePathForPiece(m.piece),
                        size: 64,
                        onPressed: () => _onMoveClicked(m),
                      ),
                      title: Text(m.title ?? ''),
                      subtitle: m.description != null && m.description!.isNotEmpty ? Text(m.description!) : null,
                    );
                  },
                );
              },
            ),
          ),
          // Fixed chessboard at bottom
          Container(
            height: 300, // Fixed height for chessboard
            child: ChessBoard(
              controller: _chessController,
              boardColor: BoardColor.brown,
              boardOrientation: PlayerColor.white,
              enableUserMoves: false, // Disable user moves, only show moves from list
            ),
          ),
        ],
      ),
    );
  }

  String? _getImagePathForPiece(String piece) {
    final pieceType = piece.toUpperCase();
    final color = _isWhiteToPlay ? 'white' : 'black';
    
    switch (pieceType) {
      case 'P':
        return 'assets/chesspieces/pawn-$color.png';
      case 'N':
        // For now, return null since we only have pawn images
        return null;
      case 'B':
        // For now, return null since we only have pawn images
        return null;
      case 'R':
        // For now, return null since we only have pawn images
        return null;
      case 'Q':
        // For now, return null since we only have pawn images
        return null;
      case 'K':
        // For now, return null since we only have pawn images
        return null;
      default:
        return null;
    }
  }

  void _onMoveClicked(MoveDto move) {
    // Convert our move to chess notation and update the board
    final moveData = _convertToChessMove(move);
    if (moveData != null) {
      _chessController.makeMove(
        from: moveData['from']!,
        to: moveData['to']!,
      );
    }
  }

  Map<String, String>? _convertToChessMove(MoveDto move) {
    // Convert our move data to chess board coordinates
    // For now, we'll create a simple move from a starting position to destination
    // This is a simplified implementation - in a real chess app, you'd need proper move logic
    
    final piece = move.piece.toUpperCase();
    final dest = '${move.destCol}${move.destRow}';
    
    // For demonstration, we'll assume pieces start from common positions
    // In a real implementation, you'd track the actual piece positions
    String from;
    
    switch (piece) {
      case 'P':
        // Pawns start from row 2 (white) or 7 (black)
        final startRow = _isWhiteToPlay ? '2' : '7';
        from = '${move.destCol}$startRow';
        break;
      case 'N':
        // Knights typically start from b1/g1 (white) or b8/g8 (black)
        from = _isWhiteToPlay ? 'b1' : 'b8';
        break;
      case 'B':
        // Bishops start from c1/f1 (white) or c8/f8 (black)
        from = _isWhiteToPlay ? 'c1' : 'c8';
        break;
      case 'R':
        // Rooks start from a1/h1 (white) or a8/h8 (black)
        from = _isWhiteToPlay ? 'a1' : 'a8';
        break;
      case 'Q':
        // Queen starts from d1 (white) or d8 (black)
        from = _isWhiteToPlay ? 'd1' : 'd8';
        break;
      case 'K':
        // King starts from e1 (white) or e8 (black)
        from = _isWhiteToPlay ? 'e1' : 'e8';
        break;
      default:
        return null;
    }
    
    return {
      'from': from,
      'to': dest,
    };
  }

  void _openAddMoveDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedPiece;
        String? selectedCol;
        int? selectedRow;
        int step = 0; // 0: piece, 1: col, 2: row

        return StatefulBuilder(
          builder: (context, setState) {
            Widget _buildSelectionSummary() {
              final parts = <String>[];
              if (selectedPiece != null) parts.add(selectedPiece!);
              if (selectedCol != null) parts.add(selectedCol!);
              if (selectedRow != null) parts.add(selectedRow!.toString());
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  parts.isEmpty ? 'Select a piece' : parts.join('  '),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }

            Widget _buildGrid(List<String> items, void Function(String) onTap) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final value = items[index];
                  return ElevatedButton(
                    onPressed: () => onTap(value),
                    child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  );
                },
              );
            }

            Widget _buildContent() {
              if (step == 0) {
                final pieces = ['P', 'N', 'B', 'R', 'Q', 'K'];
                return _buildGrid(pieces, (p) {
                  setState(() {
                    selectedPiece = p;
                    step = 1;
                  });
                });
              }
              if (step == 1) {
                final cols = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
                return _buildGrid(cols, (c) {
                  setState(() {
                    selectedCol = c;
                    step = 2;
                  });
                });
              }
              final rows = List<String>.generate(8, (i) => '${i + 1}');
              return _buildGrid(rows, (r) {
                setState(() {
                  selectedRow = int.tryParse(r);
                });
                Navigator.of(context).pop({
                  'piece': selectedPiece,
                  'destCol': selectedCol,
                  'destRow': selectedRow,
                });
              });
            }

            return AlertDialog(
              title: const Text('Add move'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSelectionSummary(),
                    _buildContent(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                if (step > 0)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // go back a step
                        if (step == 2) {
                          selectedRow = null;
                          step = 1;
                        } else if (step == 1) {
                          selectedCol = null;
                          step = 0;
                        }
                      });
                    },
                    child: const Text('Back'),
                  ),
              ],
            );
          },
        );
      },
    ).then((result) {
      // result is a map with piece, destCol, destRow. Integrate save later.
      if (result is Map) {
        // Toggle player turn after adding a move
        setState(() {
          _isWhiteToPlay = !_isWhiteToPlay;
        });
        // For now, simply refresh list or log; keeping it no-op.
      }
    });
  }

}
