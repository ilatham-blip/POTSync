import 'package:flutter/material.dart';
import 'package:heartbeat/pages/app_layout.dart';
import 'package:heartbeat/pages/user_login_page.dart';
import 'package:heartbeat/services/database_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Shared enums for morning page
enum SleepQuality { awful, bad, fair, good }
enum Severity { none, slight, moderate, severe }
class EveningEntry {
  EveningEntry({
    required this.dateTime,
    required this.heartRateBpm,
    required this.hrvMs,
    required this.dizziness,
    required this.palpitations,
    required this.dyspnoea,
    required this.chestPain,
    required this.headache,
    required this.concentration,
    required this.musclePain,
    required this.nausea,
    required this.giProblems,
    required this.abnormalTiredness,
    required this.insomnia,
    required this.notes,
  });

  final DateTime dateTime;
  final int heartRateBpm;
  final int hrvMs;
  // MAPS scores (0=None, 1=Slight, 2=Moderate, 3=Severe)
  final Severity dizziness;
  final Severity palpitations;
  final Severity dyspnoea;
  final Severity chestPain;
  final Severity headache;
  final Severity concentration;
  final Severity musclePain;
  final Severity nausea;
  final Severity giProblems;
  final Severity abnormalTiredness;
  final Severity insomnia;
  final String notes;
}

/// In-memory draft for a paused evening survey.
class EveningDraft {
  int currentPage;
  DateTime date;
  TimeOfDay time;
  int? heartRateBpm;
  int? hrvMs;
  Severity dizziness;
  Severity palpitations;
  Severity dyspnoea;
  Severity chestPain;
  Severity headache;
  Severity concentration;
  Severity musclePain;
  Severity nausea;
  Severity giProblems;
  Severity abnormalTiredness;
  Severity insomnia;
  String notes;

  EveningDraft({
    this.currentPage = 0,
    DateTime? date,
    TimeOfDay? time,
    this.heartRateBpm,
    this.hrvMs,
    this.dizziness = Severity.none,
    this.palpitations = Severity.none,
    this.dyspnoea = Severity.none,
    this.chestPain = Severity.none,
    this.headache = Severity.none,
    this.concentration = Severity.none,
    this.musclePain = Severity.none,
    this.nausea = Severity.none,
    this.giProblems = Severity.none,
    this.abnormalTiredness = Severity.none,
    this.insomnia = Severity.none,
    this.notes = '',
  })  : date = date ?? DateTime.now(),
        time = time ?? TimeOfDay.now();
}
class MorningEntry {
  MorningEntry({
    required this.dateTime,
    required this.insomnia,
    required this.abnormalTiredness,
    required this.dizziness,
    required this.palpitations,
    required this.dyspnoea,
    required this.chestPain,
    required this.headache,
    required this.concentration,
    required this.musclePain,
    required this.nausea,
    required this.giProblems,
    required this.notes,
  });

  final DateTime dateTime;
  // MAPS scores (0=None, 1=Slight, 2=Moderate, 3=Severe)
  final Severity insomnia;
  final Severity abnormalTiredness;
  final Severity dizziness;
  final Severity palpitations;
  final Severity dyspnoea;
  final Severity chestPain;
  final Severity headache;
  final Severity concentration;
  final Severity musclePain;
  final Severity nausea;
  final Severity giProblems;
  final String notes;
}

class EpisodeEntry {
  EpisodeEntry({
    required this.dateTime,
    required this.scores,
    required this.notes,
  });

  final DateTime dateTime;
  final Map<String, double> scores;
  final String notes;
}

class LifestyleEntry {
  LifestyleEntry({
    required this.date,
    required this.hotPlace,
    required this.refinedCarbs,
    required this.standingMins,
    required this.carbsGrams,
    required this.waterLitres,
    required this.alcoholUnits,
    required this.restTooMuch,
    required this.exMildMins,
    required this.exModerateMins,
    required this.exIntenseMins,
    required this.onPeriod,
    required this.stressLevel,
    required this.notes,
  });

  final DateTime date;
  final bool hotPlace;
  final bool refinedCarbs;
  final int standingMins;
  final int carbsGrams;
  final double waterLitres;
  final int alcoholUnits;
  final bool restTooMuch;
  final int exMildMins;
  final int exModerateMins;
  final int exIntenseMins;
  final bool onPeriod;
  final int stressLevel;
  final String notes;
}

/// In-memory draft for a paused morning survey.
class MorningDraft {
  int currentPage;
  DateTime date;
  TimeOfDay time;
  int? heartRateBpm;
  int? hrvMs;
  Severity insomnia;
  Severity abnormalTiredness;
  Severity dizziness;
  Severity palpitations;
  Severity dyspnoea;
  Severity chestPain;
  Severity headache;
  Severity concentration;
  Severity musclePain;
  Severity nausea;
  Severity giProblems;
  String notes;

  MorningDraft({
    this.currentPage = 0,
    DateTime? date,
    TimeOfDay? time,
    this.heartRateBpm,
    this.hrvMs,
    this.insomnia = Severity.none,
    this.abnormalTiredness = Severity.none,
    this.dizziness = Severity.none,
    this.palpitations = Severity.none,
    this.dyspnoea = Severity.none,
    this.chestPain = Severity.none,
    this.headache = Severity.none,
    this.concentration = Severity.none,
    this.musclePain = Severity.none,
    this.nausea = Severity.none,
    this.giProblems = Severity.none,
    this.notes = '',
  })  : date = date ?? DateTime.now(),
        time = time ?? TimeOfDay.now();
}

/// In-memory draft for a paused POTS episode survey.
class EpisodeDraft {
  int currentPage;
  DateTime date;
  TimeOfDay time;
  Map<String, double> symptomScores;
  String notes;

  EpisodeDraft({
    this.currentPage = 0,
    DateTime? date,
    TimeOfDay? time,
    Map<String, double>? symptomScores,
    this.notes = '',
  })  : date = date ?? DateTime.now(),
        time = time ?? TimeOfDay.now(),
        symptomScores = symptomScores ?? {};
}

/// In-memory draft for a paused Lifestyle survey.
class LifestyleDraft {
  int currentPage;
  DateTime date;
  bool hotPlace;
  bool refinedCarbs;
  double standingMins;
  double carbsGrams;
  double waterLitres;
  double alcoholUnits;
  bool restTooMuch;
  double exMild;
  double exModerate;
  double exIntense;
  bool onPeriod;
  double stressLevel;
  String notes;

  LifestyleDraft({
    this.currentPage = 0,
    DateTime? date,
    this.hotPlace = false,
    this.refinedCarbs = false,
    this.standingMins = 0,
    this.carbsGrams = 0,
    this.waterLitres = 0,
    this.alcoholUnits = 0,
    this.restTooMuch = false,
    this.exMild = 0,
    this.exModerate = 0,
    this.exIntense = 0,
    this.onPeriod = false,
    this.stressLevel = 0,
    this.notes = '',
  }) : date = date ?? DateTime.now();
}

class MyAppState extends ChangeNotifier{
  final DatabaseService _databaseService = DatabaseService();

  MyAppState() {
    // Listen to authentication state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        loadHistory(session.user.id);
      } else {
        clearHistory();
      }
    });
  }

  Severity _parseSeverity(dynamic val) {
    if (val == null) return Severity.none;
    int idx = 0;
    if (val is int) {
      idx = val;
    } else if (val is String) {
      idx = int.tryParse(val) ?? 0;
    }
    if (idx < 0 || idx >= Severity.values.length) return Severity.none;
    return Severity.values[idx];
  }

  DateTime _parseDateTime(dynamic dateVal, dynamic timeVal, dynamic createdAtVal, {bool preferCustomTime = false}) {
    if (preferCustomTime && dateVal != null && timeVal != null) {
      final dateStr = dateVal.toString().trim();
      final timeStr = timeVal.toString().trim();
      final dateParts = dateStr.split('-');
      if (dateParts.length >= 3) {
        final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
        final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
        final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;
        
        final timeParts = timeStr.split(':');
        final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 12) : 12;
        final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
        final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
        
        return DateTime(year, month, day, hour, minute, second);
      }
    }

    if (createdAtVal != null) {
      final parsed = DateTime.tryParse(createdAtVal.toString());
      if (parsed != null) return parsed.toLocal();
    }

    if (dateVal == null) return DateTime.now();
    final dateStr = dateVal.toString().trim();
    
    if (dateStr.contains('T')) {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) return parsed.toLocal();
    }
    
    final timeStr = timeVal?.toString().trim() ?? '12:00';
    final dateParts = dateStr.split('-');
    if (dateParts.length < 3) {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) return parsed.toLocal();
      return DateTime.now();
    }
    
    final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
    final month = int.tryParse(dateParts[1]) ?? DateTime.now().month;
    final day = int.tryParse(dateParts[2]) ?? DateTime.now().day;
    
    final timeParts = timeStr.split(':');
    final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 12) : 12;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    final second = timeParts.length > 2 ? (int.tryParse(timeParts[2]) ?? 0) : 0;
    
    return DateTime(year, month, day, hour, minute, second);
  }

  MorningEntry _parseMorningEntry(Map<String, dynamic> map) {
    return MorningEntry(
      dateTime: _parseDateTime(map['date'], map['time'], map['created_at']),
      insomnia: _parseSeverity(map['insomnia']),
      abnormalTiredness: _parseSeverity(map['abnormal_tiredness']),
      dizziness: _parseSeverity(map['dizziness']),
      palpitations: _parseSeverity(map['palpitations']),
      dyspnoea: _parseSeverity(map['dyspnoea']),
      chestPain: _parseSeverity(map['chest_pain']),
      headache: _parseSeverity(map['headache']),
      concentration: _parseSeverity(map['concentration']),
      musclePain: _parseSeverity(map['muscle_pain']),
      nausea: _parseSeverity(map['nausea']),
      giProblems: _parseSeverity(map['gi_problems']),
      notes: map['notes'] as String? ?? '',
    );
  }

  EveningEntry _parseEveningEntry(Map<String, dynamic> map) {
    return EveningEntry(
      dateTime: _parseDateTime(map['date'], map['time'], map['created_at']),
      heartRateBpm: map['heart_rate'] as int? ?? 0,
      hrvMs: map['hrv'] as int? ?? 0,
      dizziness: _parseSeverity(map['dizziness']),
      palpitations: _parseSeverity(map['palpitations']),
      dyspnoea: _parseSeverity(map['dyspnoea']),
      chestPain: _parseSeverity(map['chest_pain']),
      headache: _parseSeverity(map['headache']),
      concentration: _parseSeverity(map['concentration']),
      musclePain: _parseSeverity(map['muscle_pain']),
      nausea: _parseSeverity(map['nausea']),
      giProblems: _parseSeverity(map['gi_problems']),
      abnormalTiredness: _parseSeverity(map['abnormal_tiredness']),
      insomnia: _parseSeverity(map['insomnia']),
      notes: map['notes'] as String? ?? '',
    );
  }

  EpisodeEntry _parseEpisodeEntry(Map<String, dynamic> map) {
    Map<String, double> parsedScores = {};
    if (map['scores'] != null) {
      if (map['scores'] is Map) {
        (map['scores'] as Map).forEach((k, v) {
          if (v is num) {
            parsedScores[k.toString()] = v.toDouble();
          }
        });
      }
    }
    return EpisodeEntry(
      dateTime: _parseDateTime(map['date'], map['time'], map['created_at'], preferCustomTime: true),
      scores: parsedScores,
      notes: map['notes'] as String? ?? '',
    );
  }

  LifestyleEntry _parseLifestyleEntry(Map<String, dynamic> map) {
    return LifestyleEntry(
      date: _parseDateTime(map['date'], null, map['created_at']),
      hotPlace: map['hot_place'] as bool? ?? false,
      refinedCarbs: map['refined_carbs'] as bool? ?? false,
      standingMins: (map['standing_mins'] as num?)?.toInt() ?? 0,
      carbsGrams: (map['carbs_grams'] as num?)?.toInt() ?? 0,
      waterLitres: (map['water_litres'] as num?)?.toDouble() ?? 0.0,
      alcoholUnits: (map['alcohol_units'] as num?)?.toInt() ?? 0,
      restTooMuch: map['rest_too_much'] as bool? ?? false,
      exMildMins: (map['ex_mild'] as num?)?.toInt() ?? 0,
      exModerateMins: (map['ex_moderate'] as num?)?.toInt() ?? 0,
      exIntenseMins: (map['ex_intense'] as num?)?.toInt() ?? 0,
      onPeriod: map['on_period'] as bool? ?? false,
      stressLevel: (map['stress_level'] as num?)?.toInt() ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }

  Future<void> loadHistory(String userId) async {
    try {
      final morningData = await _databaseService.fetchMorningCheckIns(userId);
      _morningEntries.clear();
      dizziness.clear();
      nausea.clear();
      for (final map in morningData) {
        final entry = _parseMorningEntry(map);
        _morningEntries.add(entry);
      }
      _morningEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final eveningData = await _databaseService.fetchEveningCheckIns(userId);
      eveningEntries.clear();
      for (final map in eveningData) {
        final entry = _parseEveningEntry(map);
        eveningEntries.add(entry);
      }
      eveningEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final episodeData = await _databaseService.fetchEpisodes(userId);
      episodeEntries.clear();
      for (final map in episodeData) {
        final entry = _parseEpisodeEntry(map);
        episodeEntries.add(entry);
      }
      episodeEntries.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      final lifestyleData = await _databaseService.fetchLifestyleLogs(userId);
      _lifestyleEntries.clear();
      hydration.clear();
      for (final map in lifestyleData) {
        final entry = _parseLifestyleEntry(map);
        _lifestyleEntries.add(entry);
      }
      _lifestyleEntries.sort((a, b) => b.date.compareTo(a.date));

      // Now populate trend lists in chronological ascending order (oldest first)
      // Morning check-ins trend
      final morningAsc = List<MorningEntry>.from(_morningEntries).reversed;
      for (final entry in morningAsc) {
        final val = (entry.dizziness.index / 3.0) * 10.0;
        dizziness.add(val);
        final nauseaVal = (entry.nausea.index / 3.0) * 10.0;
        nausea.add(nauseaVal);
      }

      // Evening check-ins trend
      final eveningAsc = List<EveningEntry>.from(eveningEntries).reversed;
      for (final entry in eveningAsc) {
        final val = (entry.dizziness.index / 3.0) * 10.0;
        dizziness.add(val);
        final nauseaVal = (entry.nausea.index / 3.0) * 10.0;
        nausea.add(nauseaVal);
      }

      // Episode check-ins trend
      final episodeAsc = List<EpisodeEntry>.from(episodeEntries).reversed;
      for (final entry in episodeAsc) {
        final dizzinessVal = entry.scores['Dizziness when standing'] ??
            entry.scores['Dizziness in upright position or while standing up'] ??
            entry.scores['Dizziness, feeling that you are going to faint'];
        if (dizzinessVal != null) {
          dizziness.add(dizzinessVal);
        }
      }

      // Lifestyle check-ins trend
      final lifestyleAsc = List<LifestyleEntry>.from(_lifestyleEntries).reversed;
      for (final entry in lifestyleAsc) {
        final val = (entry.waterLitres / 5.0) * 10.0;
        hydration.add(val);
      }

      // Restore latest quiz scores maps for metric widgets and calculations
      if (_morningEntries.isNotEmpty) {
        final latest = _morningEntries.first;
        morningScores["Fatigue"] = (latest.abnormalTiredness.index / 3.0) * 10.0;
        morningScores["Dizziness when standing"] = (latest.dizziness.index / 3.0) * 10.0;
        morningScores["Heart racing and palpitations"] = (latest.palpitations.index / 3.0) * 10.0;
      }
      if (eveningEntries.isNotEmpty) {
        final latest = eveningEntries.first;
        eveningScores["Abnormal Fatigue after rest"] = (latest.abnormalTiredness.index / 3.0) * 10.0;
      }
      if (_lifestyleEntries.isNotEmpty) {
        final latest = _lifestyleEntries.first;
        lifestyleScores["standing_mins"] = latest.standingMins.toDouble();
        lifestyleScores["carbs_grams"] = latest.carbsGrams.toDouble();
        lifestyleScores["water_litres"] = latest.waterLitres;
        lifestyleScores["alcohol_units"] = latest.alcoholUnits.toDouble();
        lifestyleScores["exercise_mild"] = latest.exMildMins.toDouble();
        lifestyleScores["period_day"] = latest.onPeriod ? 1.0 : 0.0;
        lifestyleScores["stress_level"] = latest.stressLevel.toDouble();
      }
      if (episodeEntries.isNotEmpty) {
        final latest = episodeEntries.first;
        latest.scores.forEach((k, v) {
          episodeScores[k] = v;
        });
      }

      notifyListeners();
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  void clearHistory() {
    _morningEntries.clear();
    eveningEntries.clear();
    episodeEntries.clear();
    _lifestyleEntries.clear();
    dizziness.clear();
    nausea.clear();
    hydration.clear();
    notifyListeners();
  }

  String _dateOnly(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _timeWithSeconds(TimeOfDay time) {
    final second = DateTime.now().second.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:$second';
  }

  User _requireCurrentUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user session. Please sign in again.');
    }
    return user;
  }

  final dizziness = <double>[];
  final nausea = <double>[];
  final users = ["iris", "peter"];
  int pageindex = 0;


  Map<String, double> episodeScores = {
    "Dizziness when standing": 0,
    "Heart racing and palpitations": 0,
    "Chest pain": 0,
    "Headache": 0, 
    "Difficulty concentrating": 0,
    "Muscle pain": 0, 
    "Difficulty breathing": 0
    
  };
    // ---- helpers ----
  double _avg(List<double> xs) {
    if (xs.isEmpty) return 0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  // ---- averages for the tracker page ----
  double get dizzinessAvg => _avg(dizziness);

  // if you start filling the nausea list, this will work automatically
  double get nauseaAvg => _avg(nausea);

  // reuse some episodeScores as “summary” metrics
  double get fatigueAvg =>
      episodeScores["Difficulty concentrating"] ?? 0;

  double get hydrationAvg =>
      episodeScores["Difficulty breathing"] ?? 0;

  // More robust averages that consider morning/evening/lifestyle inputs
  double get combinedDizzinessAvg {
    final List<double> vals = [];
    final listAvg = _avg(dizziness);
    if (listAvg > 0) vals.add(listAvg);
    final morningVal = morningScores["Dizziness when standing"] ?? 0;
    if (morningVal > 0) vals.add(morningVal);
    final episodeVal = episodeScores["Dizziness when standing"] ?? 0;
    if (episodeVal > 0) vals.add(episodeVal);
    if (vals.isEmpty) return 0;
    return _avg(vals);
  }

  double get combinedFatigueAvg {
    final List<double> vals = [];
    final episodeVal = episodeScores["Difficulty concentrating"] ?? 0;
    if (episodeVal > 0) vals.add(episodeVal);
    final morningVal = morningScores["Fatigue"] ?? 0;
    if (morningVal > 0) vals.add(morningVal);
    final eveningVal = eveningScores["Abnormal Fatigue after rest"] ?? 0;
    if (eveningVal > 0) vals.add(eveningVal);
    if (vals.isEmpty) return 0;
    return _avg(vals);
  }

  double get combinedHydrationAvg {
    final List<double> vals = [];
    final episodeVal = episodeScores["Difficulty breathing"] ?? 0;
    if (episodeVal > 0) vals.add(episodeVal);
    final water = lifestyleScores["water_litres"] ?? 0;
    if (water > 0) {
      // scale 0..5 litres to 0..10
      vals.add((water / 5.0) * 10.0);
    }
    if (vals.isEmpty) return 0;
    return _avg(vals);
  }

  // ---- simple series for the multi‑symptom chart ----
  List<double> get fatigueSeries =>
      dizziness.isNotEmpty ? List<double>.filled(dizziness.length, combinedFatigueAvg) : [combinedFatigueAvg];

  List<double> get hydrationSeries =>
      hydration.isNotEmpty ? hydration : [(lifestyleScores["water_litres"] ?? 0) / 5.0 * 10.0];

  void updateEpisodeScore(String symptom, double newValue) {
    episodeScores[symptom] = newValue;
    notifyListeners(); 
  }

  void updateMorningScore(String symptom, double newValue) {
    morningScores[symptom] = newValue;
    // mirror into episode summary for tracker use
    if (symptom == 'Dizziness when standing') {
      updateEpisodeScore('Dizziness when standing', newValue);
      try {
        dizziness.add(newValue);
      } catch (_) {}
    }
    if (symptom == 'Fatigue') {
      updateEpisodeScore('Difficulty concentrating', newValue);
    }
    notifyListeners();
  }

  Future<void> saveEpisode({
    required DateTime date,
    required TimeOfDay time,
    required Map<String, double> scores,
    required String notes,
  }) async {
    // Update in-memory episode summary so tracker shows recent values.
    scores.forEach((k, v) {
      episodeScores[k] = v;
    });

    // If the episode included a dizziness value, add it to the trend list
    // so the charts update over time.
    final dizzinessKey = 'Dizziness when standing';
    if (scores.containsKey(dizzinessKey)) {
      try {
        final val = scores[dizzinessKey] ?? 0;
        dizziness.add(val);
      } catch (_) {}
    }

    episodeEntries.insert(0, EpisodeEntry(
      dateTime: DateTime(date.year, date.month, date.day, time.hour, time.minute),
      scores: scores,
      notes: notes,
    ));

    notifyListeners();

    final user = _requireCurrentUser();
    await _databaseService.saveEpisode({
      'user_id': user.id,
      'date': _dateOnly(date),
      'time': '${time.hour}:${time.minute}',
      'scores': scores,
      'notes': notes,
    });
  }

  EpisodeDraft? episodeDraft;

  void pauseEpisodeSurvey(EpisodeDraft draft) {
    episodeDraft = draft;
    notifyListeners();
  }

  void clearEpisodeDraft() {
    episodeDraft = null;
    notifyListeners();
  }

  Map<String, double> morningScores = {
    "Sleep Quality": 0,
    "Fatigue": 0,
    "Dizziness when standing": 0,
    "Heart racing and palpitations": 0, 
  };



  Map<String, double> eveningScores = {
    "Abnormal Fatigue after rest": 0

  };

  void updateEveningScore(String symptom, double newValue) {
    eveningScores[symptom] = newValue;
    if (symptom == 'Abnormal Fatigue after rest') {
      updateEpisodeScore('Difficulty concentrating', newValue);
    }
    notifyListeners(); 
  }

  Map<String, double> lifestyleScores= {
    "standing_mins": 0, // in minutes 0->240, int
    "carbs_grams": 50, // 0->400, int
    "water_litres": 0, // 0->5, double
    "alcohol_units": 0, // 0->15, int
    "exercise_mild": 0, // 0->180
    "period_day": 0, // 0->1
    "stress_level": 0, // This uses your 0-3 scale
  };

  void updateLifestyleScores(String key, double value) {
    lifestyleScores[key] = value;
    if (key == 'water_litres') {
      // update hydration episode metric scaled to 0..10
      final scaled = (value / 5.0) * 10.0;
      updateEpisodeScore('Difficulty breathing', scaled);
    }
    notifyListeners();
  }



  Widget home_page = UserLoginPage();

  int symptomTabIndex = 0;

  void changeIndex(int value, {int symptomTab = 0}){
    pageindex = value;
    symptomTabIndex = symptomTab;
    notifyListeners();
  }

  void add(var variable, var value){
    try{
      variable.add(value);
      //printToConsole(variable.toString());
    }
    catch(error){
      //print(error.toString());
    }
  }

  bool verify(String value){
    if(users.contains(value)){
      home_page = AppLayout();
      notifyListeners();
      return true;
    } else {return false;}
  }
  final List<EveningEntry> eveningEntries = [];
  EveningDraft? eveningDraft;

  Future<void> saveEveningReview({
    required DateTime date,
    required TimeOfDay time,
    required int heartRateBpm,
    required int hrvMs,
    required Severity dizziness,
    required Severity palpitations,
    required Severity dyspnoea,
    required Severity chestPain,
    required Severity headache,
    required Severity concentration,
    required Severity musclePain,
    required Severity nausea,
    required Severity giProblems,
    required Severity abnormalTiredness,
    required Severity insomnia,
    required String notes,
    required List<double> ppgData,
    required List<double> ecgData,
  }) async {
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    eveningEntries.insert(0, EveningEntry(
      dateTime: dt,
      heartRateBpm: heartRateBpm,
      hrvMs: hrvMs,
      dizziness: dizziness,
      palpitations: palpitations,
      dyspnoea: dyspnoea,
      chestPain: chestPain,
      headache: headache,
      concentration: concentration,
      musclePain: musclePain,
      nausea: nausea,
      giProblems: giProblems,
      abnormalTiredness: abnormalTiredness,
      insomnia: insomnia,
      notes: notes,
    ));
    eveningDraft = null;
    try {
      final scaledTiredness = (abnormalTiredness.index / 3.0) * 10.0;
      updateEpisodeScore('Difficulty concentrating', scaledTiredness);
      final scaledDizziness = (dizziness.index / 3.0) * 10.0;
      updateEpisodeScore('Dizziness when standing', scaledDizziness);
    } catch (_) {}

    notifyListeners();

    final user = _requireCurrentUser();
    await _databaseService.saveEveningCheckIn({
      'user_id': user.id,
      'date': DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
        DateTime.now().second,
      ).toIso8601String(),
      'time': _timeWithSeconds(time),
      'heart_rate': heartRateBpm,
      'hrv': hrvMs,
      'dizziness': dizziness.index,
      'palpitations': palpitations.index,
      'dyspnoea': dyspnoea.index,
      'chest_pain': chestPain.index,
      'headache': headache.index,
      'concentration': concentration.index,
      'muscle_pain': musclePain.index,
      'nausea': nausea.index,
      'gi_problems': giProblems.index,
      'abnormal_tiredness': abnormalTiredness.index,
      'insomnia': insomnia.index,
      'notes': notes,
      'ppg_data': ppgData,
      'ecg_data': ecgData,
    });
  }

  void pauseEveningReview(EveningDraft draft) {
    eveningDraft = draft;
    notifyListeners();
  }

  void clearEveningDraft() {
    eveningDraft = null;
    notifyListeners();
  }
  // Morning entries storage
  final List<MorningEntry> _morningEntries = [];
  List<MorningEntry> get morningEntries => List.unmodifiable(_morningEntries);
  MorningDraft? morningDraft;

  // Episode entries storage
  final List<EpisodeEntry> episodeEntries = [];

  // Lifestyle entries storage
  final List<LifestyleEntry> _lifestyleEntries = [];
  final List<double> hydration = [];
  List<LifestyleEntry> get lifestyleEntries => List.unmodifiable(_lifestyleEntries);
  LifestyleDraft? lifestyleDraft;

  int get episodesThisWeekCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return episodeEntries.where((e) {
      final entryDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      final diff = today.difference(entryDate).inDays;
      return diff >= 0 && diff < 7;
    }).length;
  }

  int get checkInAdherencePercentage {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int morningCount = _morningEntries.where((e) {
      final entryDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      final diff = today.difference(entryDate).inDays;
      return diff >= 0 && diff < 7;
    }).length;

    int eveningCount = eveningEntries.where((e) {
      final entryDate = DateTime(e.dateTime.year, e.dateTime.month, e.dateTime.day);
      final diff = today.difference(entryDate).inDays;
      return diff >= 0 && diff < 7;
    }).length;

    final totalLogged = morningCount + eveningCount;
    return ((totalLogged / 14.0) * 100).round().clamp(0, 100);
  }

  // Save method used by MorningQuiz
  Future<void> saveMorningCheckIn({
    required DateTime date,
    required TimeOfDay time,
    int? heartRateBpm,
    int? hrvMs,
    required Severity insomnia,
    required Severity abnormalTiredness,
    required Severity dizziness,
    required Severity palpitations,
    required Severity dyspnoea,
    required Severity chestPain,
    required Severity headache,
    required Severity concentration,
    required Severity musclePain,
    required Severity nausea,
    required Severity giProblems,
    required String notes,
    required List<double> ppgData,
    required List<double> ecgData,
  }) async {
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    _morningEntries.insert(
      0,
      MorningEntry(
        dateTime: dt,
        insomnia: insomnia,
        abnormalTiredness: abnormalTiredness,
        dizziness: dizziness,
        palpitations: palpitations,
        dyspnoea: dyspnoea,
        chestPain: chestPain,
        headache: headache,
        concentration: concentration,
        musclePain: musclePain,
        nausea: nausea,
        giProblems: giProblems,
        notes: notes,
      ),
    );
    morningDraft = null;
    try {
      final tirednessVal = (abnormalTiredness.index / 3.0) * 10.0;
      final dizzinessVal = (dizziness.index / 3.0) * 10.0;
      updateEpisodeScore('Difficulty concentrating', tirednessVal);
      updateEpisodeScore('Dizziness when standing', dizzinessVal);
      this.dizziness.add(dizzinessVal);
    } catch (_) {}

    notifyListeners();

    final user = _requireCurrentUser();
    await _databaseService.saveMorningCheckIn({
      'user_id': user.id,
      'date': _dateOnly(date),
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'heart_rate': heartRateBpm,
      'hrv': hrvMs,
      'insomnia': insomnia.index,
      'abnormal_tiredness': abnormalTiredness.index,
      'dizziness': dizziness.index,
      'palpitations': palpitations.index,
      'dyspnoea': dyspnoea.index,
      'chest_pain': chestPain.index,
      'headache': headache.index,
      'concentration': concentration.index,
      'muscle_pain': musclePain.index,
      'nausea': nausea.index,
      'gi_problems': giProblems.index,
      'notes': notes,
      'ppg_data': ppgData,
      'ecg_data': ecgData,
    });
  }

  void pauseMorningCheckIn(MorningDraft draft) {
    morningDraft = draft;
    notifyListeners();
  }

  void clearMorningDraft() {
    morningDraft = null;
    notifyListeners();
  }

    void pauseLifestyleSurvey(LifestyleDraft draft) {
      lifestyleDraft = draft;
      notifyListeners();
    }

    void clearLifestyleDraft() {
      lifestyleDraft = null;
      notifyListeners();
    }

    Future<void> saveLifestyleEntry({
      required DateTime date,
      required bool hotPlace,
      required bool refinedCarbs,
      required int standingMins,
      required int carbsGrams,
      required double waterLitres,
      required int alcoholUnits,
      required bool restTooMuch,
      required int exMildMins,
      required int exModerateMins,
      required int exIntenseMins,
      required bool onPeriod,
      required int stressLevel,
      required String notes,
    }) async {
      _lifestyleEntries.insert(
        0,
        LifestyleEntry(
          date: date,
          hotPlace: hotPlace,
          refinedCarbs: refinedCarbs,
          standingMins: standingMins,
          carbsGrams: carbsGrams,
          waterLitres: waterLitres,
          alcoholUnits: alcoholUnits,
          restTooMuch: restTooMuch,
          exMildMins: exMildMins,
          exModerateMins: exModerateMins,
          exIntenseMins: exIntenseMins,
          onPeriod: onPeriod,
          stressLevel: stressLevel,
          notes: notes,
        ),
      );
      lifestyleDraft = null;
      hydration.insert(0, (waterLitres / 5.0) * 10.0 );
      notifyListeners();

      final user = _requireCurrentUser();
      await _databaseService.saveLifestyleLog({
        'user_id': user.id,
        'date': _dateOnly(date),
        'hot_place': hotPlace,
        'refined_carbs': refinedCarbs,
        'standing_mins': standingMins,
        'carbs_grams': carbsGrams,
        'water_litres': waterLitres,
        'alcohol_units': alcoholUnits,
        'rest_too_much': restTooMuch,
        'ex_mild': exMildMins,
        'ex_moderate': exModerateMins,
        'ex_intense': exIntenseMins,
        'on_period': onPeriod,
        'stress_level': stressLevel,
        'notes': notes,
      });
    }
}
 