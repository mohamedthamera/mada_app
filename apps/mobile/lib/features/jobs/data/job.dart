class Job {
  const Job({
    required this.id,
    required this.titleAr,
    required this.companyName,
    required this.location,
    required this.jobType,
    required this.descriptionAr,
    this.salary,
    this.workMode,
    this.workDays,
    this.requirements,
    this.applyUrl,
    this.createdAt,
  });

  final String id;
  final String titleAr;
  final String companyName;
  final String location;
  final String jobType; // full_time, part_time, internship
  final String descriptionAr;
  final String? salary;
  final String? workMode; // onsite, remote, hybrid
  final String? workDays;
  final String? requirements;
  final String? applyUrl;
  final DateTime? createdAt;

  String get jobTypeLabel {
    switch (jobType) {
      case 'full_time':
        return 'دوام كامل';
      case 'part_time':
        return 'دوام جزئي';
      case 'internship':
        return 'تدريب';
      default:
        return jobType;
    }
  }

  /// ترجمة طبيعة الدوام للعرض (حضوري / عن بعد / هجين)
  String? get workModeLabel {
    if (workMode == null || workMode!.isEmpty) return null;
    switch (workMode!) {
      case 'onsite':
        return 'حضوري';
      case 'remote':
        return 'عن بُعد';
      case 'hybrid':
        return 'هجين';
      default:
        return workMode;
    }
  }
}
