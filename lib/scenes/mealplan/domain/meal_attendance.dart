enum AttendanceStatus { attending, notAttending, unknown }

AttendanceStatus attendanceStatus(String? value) => switch (value) {
      'ATTENDING' => AttendanceStatus.attending,
      'NOT_ATTENDING' => AttendanceStatus.notAttending,
      _ => AttendanceStatus.unknown,
    };

class AttendanceMember {
  const AttendanceMember(this.userId, this.fullName, this.status);
  final String userId;
  final String? fullName;
  final AttendanceStatus status;
}

class MealAttendance {
  const MealAttendance(
      {required this.slotId,
      required this.members,
      required this.attendingCount,
      required this.notAttendingCount,
      required this.unknownCount,
      required this.myStatus,
      required this.editable});
  final String slotId;
  final List<AttendanceMember> members;
  final int attendingCount, notAttendingCount, unknownCount;
  final AttendanceStatus myStatus;
  final bool editable;
  factory MealAttendance.fromJson(Map<String, dynamic> j) => MealAttendance(
      slotId: j['slotId'] as String,
      members: (j['members'] as List<dynamic>).map((v) {
        final m = v as Map<String, dynamic>;
        return AttendanceMember(m['userId'] as String, m['fullName'] as String?,
            attendanceStatus(m['status'] as String?));
      }).toList(),
      attendingCount: (j['attendingCount'] as num).toInt(),
      notAttendingCount: (j['notAttendingCount'] as num).toInt(),
      unknownCount: (j['unknownCount'] as num).toInt(),
      myStatus: attendanceStatus(j['myStatus'] as String?),
      editable: j['editable'] as bool);
}
