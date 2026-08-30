import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/project_member.dart';
import 'projects_repository.dart';

/// One request/invite whose status changed to Accepted/Rejected since the
/// last time this device checked.
class MembershipStatusChange {
  final String projectName;
  final MemberStatus status;
  MembershipStatusChange({required this.projectName, required this.status});
}

class MembershipAlertService {
  MembershipAlertService({ProjectsRepository? repository})
    : _repo = repository ?? ProjectsRepository();

  final ProjectsRepository _repo;
  static String _key(int userId, int projectId) =>
      'membership_status_${userId}_$projectId';

  /// Fetches the user's current membership statuses, compares them against
  /// what was last seen on this device, and returns only the ones that
  /// newly resolved to Accepted/Rejected. Always updates the cache, so
  /// each change is only reported once.
  Future<List<MembershipStatusChange>> checkForChanges(int userId) async {
    List<MembershipStatusEntry> current;
    try {
      current = await _repo.getMyMemberships(userId);
    } catch (_) {
      return [];
    }

    final prefs = await SharedPreferences.getInstance();
    final changes = <MembershipStatusChange>[];

    for (final entry in current) {
      final key = _key(userId, entry.projectId);
      final lastSeen = prefs.getString(key);
      final newStatus = entry.status.name;

      final isResolved =
          entry.status == MemberStatus.accepted ||
          entry.status == MemberStatus.rejected;
      if (lastSeen != null && lastSeen != newStatus && isResolved) {
        changes.add(
          MembershipStatusChange(
            projectName: entry.projectName,
            status: entry.status,
          ),
        );
      }
      await prefs.setString(key, newStatus);
    }

    return changes;
  }
}
