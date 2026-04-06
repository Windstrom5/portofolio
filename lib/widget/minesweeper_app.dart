import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class MinesweeperApp extends StatefulWidget {
  const MinesweeperApp({super.key});

  @override
  State<MinesweeperApp> createState() => _MinesweeperAppState();
}

enum CellState { hidden, revealed, flagged }

class Cell {
  final int x, y;
  bool isMine = false;
  CellState state = CellState.hidden;
  int surroundingMines = 0;

  Cell(this.x, this.y);
}

class _MinesweeperAppState extends State<MinesweeperApp> {
  static const int rows = 12;
  static const int cols = 10;
  static const int mineCount = 15;

  late List<List<Cell>> grid;
  bool gameOver = false;
  bool winner = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      gameOver = false;
      winner = false;
      grid = List.generate(rows, (r) => List.generate(cols, (c) => Cell(r, c)));

      // Plant mines
      int planted = 0;
      final rng = Random();
      while (planted < mineCount) {
        int r = rng.nextInt(rows);
        int c = rng.nextInt(cols);
        if (!grid[r][c].isMine) {
          grid[r][c].isMine = true;
          planted++;
        }
      }

      // Calculate numbers
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (!grid[r][c].isMine) {
            int count = 0;
            for (int dr = -1; dr <= 1; dr++) {
              for (int dc = -1; dc <= 1; dc++) {
                int nr = r + dr, nc = c + dc;
                if (nr >= 0 &&
                    nr < rows &&
                    nc >= 0 &&
                    nc < cols &&
                    grid[nr][nc].isMine) {
                  count++;
                }
              }
            }
            grid[r][c].surroundingMines = count;
          }
        }
      }
    });
  }

  void _reveal(int r, int c) {
    if (gameOver || winner || grid[r][c].state != CellState.hidden) return;

    setState(() {
      if (grid[r][c].isMine) {
        grid[r][c].state = CellState.revealed;
        gameOver = true;
        return;
      }

      _recursiveReveal(r, c);
      _checkWin();
    });
  }

  void _recursiveReveal(int r, int c) {
    if (r < 0 ||
        r >= rows ||
        c < 0 ||
        c >= cols ||
        grid[r][c].state != CellState.hidden) {
      return;
    }

    grid[r][c].state = CellState.revealed;
    if (grid[r][c].surroundingMines == 0) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          _recursiveReveal(r + dr, c + dc);
        }
      }
    }
  }

  void _flag(int r, int c) {
    if (gameOver || winner || grid[r][c].state == CellState.revealed) return;
    setState(() {
      grid[r][c].state = (grid[r][c].state == CellState.flagged)
          ? CellState.hidden
          : CellState.flagged;
    });
  }

  void _checkWin() {
    bool allNonMinesRevealed = true;
    for (var r in grid) {
      for (var cell in r) {
        if (!cell.isMine && cell.state != CellState.revealed) {
          allNonMinesRevealed = false;
          break;
        }
      }
    }
    if (allNonMinesRevealed) winner = true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade400,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Retro Header
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.grey.shade400,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _counter(mineCount),
                GestureDetector(
                  onTap: _resetGame,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black45)),
                    child: Text(winner ? "😎" : (gameOver ? "😵" : "😊"),
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                _counter(0), // Placeholder timer
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Grid
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final size = min(
                  constraints.maxWidth / cols, constraints.maxHeight / rows);
              return Center(
                child: SizedBox(
                  width: size * cols,
                  height: size * rows,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                    ),
                    itemCount: rows * cols,
                    itemBuilder: (context, index) {
                      int r = index ~/ cols;
                      int c = index % cols;
                      final cell = grid[r][c];

                      return GestureDetector(
                        onTap: () => _reveal(r, c),
                        onLongPress: () => _flag(r, c),
                        onSecondaryTap: () => _flag(r, c),
                        child: _buildCell(cell),
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _counter(int val) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(val.toString().padLeft(3, '0'),
          style: GoogleFonts.vt323(
              color: Colors.red, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCell(Cell cell) {
    if (cell.state == CellState.hidden) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          border: const Border(
            top: BorderSide(color: Colors.white, width: 3),
            left: BorderSide(color: Colors.white, width: 3),
            bottom: BorderSide(color: Color(0xFF9E9E9E), width: 3),
            right: BorderSide(color: Color(0xFF9E9E9E), width: 3),
          ),
        ),
      );
    }

    if (cell.state == CellState.flagged) {
      return Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          border: const Border(
            top: BorderSide(color: Colors.white, width: 3),
            left: BorderSide(color: Colors.white, width: 3),
            bottom: BorderSide(color: Color(0xFF9E9E9E), width: 3),
            right: BorderSide(color: Color(0xFF9E9E9E), width: 3),
          ),
        ),
        child: const Center(child: Text("🚩", style: TextStyle(fontSize: 12))),
      );
    }

    // Revealed
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        border: Border.all(color: Colors.grey.shade500, width: 1),
      ),
      child: Center(
        child: cell.isMine
            ? const Text("💣", style: TextStyle(fontSize: 12))
            : (cell.surroundingMines > 0
                ? Text("${cell.surroundingMines}",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getNumberColor(cell.surroundingMines)))
                : null),
      ),
    );
  }

  Color _getNumberColor(int n) {
    switch (n) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      default:
        return const Color(0xFF800000);
    }
  }
}
