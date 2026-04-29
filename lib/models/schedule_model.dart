class Schedule {
  String id;
  String name;
  String icon;
  String startTime;
  String endTime;
  List<String> days;
  String mode; // 'Silent', 'Vibrate', 'DND'
  bool isEnabled;

  Schedule({
    required this.id,
    required this.name,
    required this.icon,
    required this.startTime,
    required this.endTime,
    required this.days,
    required this.mode,
    this.isEnabled = true,
  });

  // ── Convert to JSON (for local storage + API) ──
  Map<String, dynamic> toJson() => {
    'id':        id,
    'name':      name,
    'icon':      icon,
    'startTime': startTime,
    'endTime':   endTime,
    'days':      days,
    'mode':      mode,
    'isEnabled': isEnabled,
  };

  // ── Create from local storage JSON ──
  factory Schedule.fromJson(Map<String, dynamic> json) => Schedule(
    id:        json['id']?.toString() ?? '',
    name:      json['name']      ?? 'Schedule',
    icon:      json['icon']      ?? '🔕',
    startTime: json['startTime'] ?? '09:00',
    endTime:   json['endTime']   ?? '17:00',
    days:      List<String>.from(json['days'] ?? []),
    mode:      json['mode']      ?? 'Silent',
    isEnabled: json['isEnabled'] ?? true,
  );

  // ── Create from MongoDB API response ──
  // MongoDB uses _id not id
  factory Schedule.fromApi(Map<String, dynamic> json) => Schedule(
    id:        json['_id']?.toString() ?? json['id']?.toString() ?? '',
    name:      json['name']      ?? 'Schedule',
    icon:      json['icon']      ?? '🔕',
    startTime: json['startTime'] ?? '09:00',
    endTime:   json['endTime']   ?? '17:00',
    days:      List<String>.from(json['days'] ?? []),
    mode:      json['mode']      ?? 'Silent',
    isEnabled: json['isEnabled'] ?? true,
  );
}