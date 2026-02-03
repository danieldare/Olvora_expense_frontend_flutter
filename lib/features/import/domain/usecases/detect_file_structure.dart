import '../../data/detectors/structure_detector.dart';
import '../../data/parsers/models/raw_sheet_data.dart';
import '../../domain/entities/detected_structure.dart';

/// Use case: Detect file structure (transactional vs pivot)
class DetectFileStructure {
  final StructureDetector _detector;

  DetectFileStructure({
    StructureDetector? detector,
  }) : _detector = detector ?? StructureDetector();

  /// Detect structure from raw sheet data
  DetectedStructure execute(RawSheetData sheet) {
    return _detector.detect(sheet);
  }
}
