import 'package:map_mvp_project/models/annotation.dart';
import 'package:map_mvp_project/repositories/local_annotations_repository.dart';
import 'package:map_mvp_project/services/error_handler.dart'; // for logger

/// A small utility class for timeline logic related to annotations.
class TimelineAnnotations {
  final LocalAnnotationsRepository localRepo;

  TimelineAnnotations(this.localRepo);

  /// Given a list of Hive IDs (annotation UUIDs), fetch those annotations
  /// from Hive and debug-log title, date, and icon for each.
  Future<void> debugLogAnnotations(List<String> hiveIds) async {
    // If needed, log the incoming IDs for clarity:
    logger.i('TimelineAnnotations: Received Hive IDs: $hiveIds');

    if (hiveIds.isEmpty) {
      logger.i('No annotation IDs passed in; nothing to fetch.');
      return;
    }

    // Grab all annotations from Hive (or you could write a specialized
    // repository method that fetches only the requested IDs).
    final allAnnotations = await localRepo.getAnnotations();

    // Filter the annotations so we only keep those matching the given IDs.
    final relevant = allAnnotations.where((a) => hiveIds.contains(a.id)).toList();

    // If none found, log a warning or message:
    if (relevant.isEmpty) {
      logger.w('No matching annotations found in Hive for these IDs.');
      return;
    }

    // Log out the fields you care about:
    for (final ann in relevant) {
      final title = ann.title ?? '(no title)';
      final date = ann.startDate ?? '(no startDate)';
      final icon = ann.iconName ?? '(no icon)';
      logger.i('TimelineAnnotation => Title: $title, Date: $date, Icon: $icon');
    }
  }
}