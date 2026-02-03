/// Raw data extracted from a file (before structure detection)
class RawSheetData {
  final String sheetName;
  final List<List<dynamic>> rows;  // 2D grid of cell values
  final int rowCount;
  final int columnCount;

  const RawSheetData({
    required this.sheetName,
    required this.rows,
    required this.rowCount,
    required this.columnCount,
  });

  /// Get cell value at position (row, col), 0-indexed
  dynamic getCell(int row, int col) {
    if (row < 0 || row >= rowCount) return null;
    if (col < 0 || col >= rows[row].length) return null;
    return rows[row][col];
  }

  /// Get row as list
  List<dynamic> getRow(int row) {
    if (row < 0 || row >= rowCount) return [];
    return rows[row];
  }

  /// Get column as list
  List<dynamic> getColumn(int col) {
    return rows.map((row) => col < row.length ? row[col] : null).toList();
  }

  /// Check if row is empty (all null or empty strings)
  bool isRowEmpty(int row) {
    if (row < 0 || row >= rowCount) return true;
    return rows[row].every((cell) => 
      cell == null || 
      (cell is String && cell.trim().isEmpty)
    );
  }

  /// Get non-empty rows
  List<int> get nonEmptyRowIndices {
    return List.generate(rowCount, (i) => i)
      .where((i) => !isRowEmpty(i))
      .toList();
  }

  /// Convert cell values to strings for easier processing
  List<List<String>> get stringRows {
    return rows.map((row) => row.map((cell) {
      if (cell == null) return '';
      if (cell is DateTime) return cell.toIso8601String();
      return cell.toString();
    }).toList()).toList();
  }
}
