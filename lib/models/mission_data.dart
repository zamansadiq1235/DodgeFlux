/// What a daily mission asks the player to do.
enum MissionType { collectCoins, surviveTime, shiftTimes, reachScore, finishRuns }

/// Static mission definition (template).
class MissionData {
  const MissionData({
    required this.id,
    required this.title,
    required this.type,
    required this.targetValue,
    required this.rewardCoins,
  });

  final String id;
  final String title;
  final MissionType type;
  final int targetValue;
  final int rewardCoins;

  /// The rotating daily mission pool.
  static const List<MissionData> dailyPool = [
    MissionData(
      id: 'daily_coins_30',
      title: 'Collect 30 coins',
      type: MissionType.collectCoins,
      targetValue: 30,
      rewardCoins: 60,
    ),
    MissionData(
      id: 'daily_survive_60',
      title: 'Survive 60 seconds in one run',
      type: MissionType.surviveTime,
      targetValue: 60,
      rewardCoins: 80,
    ),
    MissionData(
      id: 'daily_shift_25',
      title: 'Use Neon Shift 25 times',
      type: MissionType.shiftTimes,
      targetValue: 25,
      rewardCoins: 50,
    ),
    MissionData(
      id: 'daily_score_800',
      title: 'Score 800 in one run',
      type: MissionType.reachScore,
      targetValue: 800,
      rewardCoins: 90,
    ),
    MissionData(
      id: 'daily_runs_3',
      title: 'Finish 3 runs',
      type: MissionType.finishRuns,
      targetValue: 3,
      rewardCoins: 40,
    ),
  ];
}

/// Live per-player progress against a [MissionData].
class MissionProgress {
  const MissionProgress({
    required this.missionId,
    this.progressValue = 0,
    this.isCompleted = false,
    this.isClaimed = false,
  });

  final String missionId;
  final int progressValue;
  final bool isCompleted;
  final bool isClaimed;

  MissionProgress copyWith({
    int? progressValue,
    bool? isCompleted,
    bool? isClaimed,
  }) {
    return MissionProgress(
      missionId: missionId,
      progressValue: progressValue ?? this.progressValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }

  Map<String, dynamic> toJson() => {
        'missionId': missionId,
        'progressValue': progressValue,
        'isCompleted': isCompleted,
        'isClaimed': isClaimed,
      };

  factory MissionProgress.fromJson(Map<String, dynamic> json) {
    return MissionProgress(
      missionId: json['missionId'] as String,
      progressValue: (json['progressValue'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
    );
  }
}

/// Wrapper persisted to disk: today's missions + the date they belong to.
class DailyMissionState {
  const DailyMissionState({
    required this.dateKey,
    required this.missions,
    required this.progress,
  });

  /// `yyyy-mm-dd` — missions regenerate when the day changes.
  final String dateKey;
  final List<MissionData> missions;
  final List<MissionProgress> progress;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'missionIds': missions.map((m) => m.id).toList(),
        'progress': progress.map((p) => p.toJson()).toList(),
      };

  factory DailyMissionState.fromJson(Map<String, dynamic> json) {
    final ids =
        (json['missionIds'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    final missions = ids
        .map((id) => MissionData.dailyPool
            .where((m) => m.id == id)
            .cast<MissionData?>()
            .firstWhere((m) => m != null, orElse: () => null))
        .whereType<MissionData>()
        .toList();
    return DailyMissionState(
      dateKey: json['dateKey'] as String? ?? '',
      missions: missions,
      progress: (json['progress'] as List?)
              ?.map((e) =>
                  MissionProgress.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
