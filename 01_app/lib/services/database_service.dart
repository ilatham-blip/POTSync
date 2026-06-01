import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> _insertWithSchemaFallback(
    String table,
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data);

    // Retry insert if a payload column is not present in the table schema.
    // Supabase can throw this after schema changes until code is aligned.
    for (var attempt = 0; attempt < 6; attempt++) {
      try {
        await _client.from(table).insert(payload);
        return;
      } on PostgrestException catch (e) {
        if (_isMissingUserProfileForeignKey(e)) {
          throw StateError(
            'Your account profile is missing. Please complete profile setup before saving logs.',
          );
        }

        if (_isDuplicateKeyError(e) && table == 'morning_checkins') {
          final resolved = await _updateExistingWaveformRow(table, payload);
          if (resolved) {
            return;
          }
        }

        final missingColumn = _extractMissingColumn(e.message);
        if (missingColumn == null || !payload.containsKey(missingColumn)) {
          final handledDouble = _handleInvalidDoublePrecision(e.message, payload);
          if (!handledDouble) {
            rethrow;
          }
          if (payload.isEmpty) {
            rethrow;
          }
          continue;
        }
        payload.remove(missingColumn);
        if (payload.isEmpty) {
          rethrow;
        }
      }
    }

    throw StateError('Insert failed for $table after schema fallback retries.');
  }

  String? _extractMissingColumn(String message) {
    final relationMatch = RegExp(
      r'column\s+"([^"]+)"\s+of\s+relation\s+"[^"]+"\s+does\s+not\s+exist',
      caseSensitive: false,
    ).firstMatch(message);
    if (relationMatch != null) return relationMatch.group(1);

    final cacheMatch = RegExp(
      r"Could not find the\s+'([^']+)'\s+column",
      caseSensitive: false,
    ).firstMatch(message);
    if (cacheMatch != null) return cacheMatch.group(1);

    return null;
  }

  bool _handleInvalidDoublePrecision(
    String message,
    Map<String, dynamic> payload,
  ) {
    final match = RegExp(
      r'invalid input syntax for type\s+double precision:\s+"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(message);
    if (match == null) {
      if (!message.toLowerCase().contains('double precision')) {
        return false;
      }

      // If Postgres reports a double precision mismatch but does not include
      // a parseable token, remove list-like fields first (most common cause:
      // sending waveform arrays into scalar numeric columns).
      for (final entry in payload.entries.toList()) {
        final value = entry.value;
        if (value is List) {
          payload.remove(entry.key);
          return true;
        }
      }
      return false;
    }

    final badToken = match.group(1);
    if (badToken == null) return false;

    for (final entry in payload.entries.toList()) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) continue;

      if (value is String && value == badToken) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          payload[key] = parsed;
        } else {
          payload.remove(key);
        }
        return true;
      }

      if (value is List && value.toString() == badToken) {
        payload.remove(key);
        return true;
      }

      if (value.toString() == badToken) {
        final parsed = double.tryParse(badToken.trim());
        if (parsed != null) {
          payload[key] = parsed;
        } else {
          payload.remove(key);
        }
        return true;
      }
    }

    // Token extraction worked, but no exact match found; as a final fallback
    // remove list fields, since they commonly trigger scalar double errors.
    for (final entry in payload.entries.toList()) {
      if (entry.value is List) {
        payload.remove(entry.key);
        return true;
      }
    }

    return false;
  }

  bool _isMissingUserProfileForeignKey(PostgrestException e) {
    final code = e.code ?? '';
    final combinedMessage = '${e.message} ${e.details}'.toLowerCase();
    return code == '23503' &&
        combinedMessage.contains('foreign key') &&
        combinedMessage.contains('user_profiles');
  }

  bool _isDuplicateKeyError(PostgrestException e) {
    return (e.code ?? '') == '23505';
  }

  Future<bool> _updateExistingWaveformRow(
    String table,
    Map<String, dynamic> payload,
  ) async {
    final userId = payload['user_id'];
    final dateValue = payload['date'];

    if (userId == null || dateValue == null) {
      return false;
    }

    final updatePayload = <String, dynamic>{};
    if (payload.containsKey('ppg_data')) {
      updatePayload['ppg_data'] = payload['ppg_data'];
    }
    if (payload.containsKey('ecg_data')) {
      updatePayload['ecg_data'] = payload['ecg_data'];
    }
    if (payload.containsKey('time')) {
      updatePayload['time'] = payload['time'];
    }

    if (updatePayload.isEmpty) {
      return false;
    }

    final dateRaw = dateValue.toString();
    final dateOnly = _coerceDateOnly(dateRaw);

    final byDateOnly = await _client
        .from(table)
        .update(updatePayload)
        .eq('user_id', userId)
        .eq('date', dateOnly)
        .select('user_id')
        .limit(1);

    if (byDateOnly is List && byDateOnly.isNotEmpty) {
      return true;
    }

    final byRawDate = await _client
        .from(table)
        .update(updatePayload)
        .eq('user_id', userId)
        .eq('date', dateRaw)
        .select('user_id')
        .limit(1);

    return byRawDate is List && byRawDate.isNotEmpty;
  }

  String _coerceDateOnly(String value) {
    final trimmed = value.trim();
    final tIndex = trimmed.indexOf('T');
    if (tIndex > 0) {
      return trimmed.substring(0, tIndex);
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) {
      final y = parsed.year.toString().padLeft(4, '0');
      final m = parsed.month.toString().padLeft(2, '0');
      final d = parsed.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    return trimmed;
  }

  // ---------------------------------------------------------------------------
  // MORNING CHECK-IN
  // ---------------------------------------------------------------------------
  Future<void> saveMorningCheckIn(Map<String, dynamic> data) async {
    // data should correspond to columns in 'morning_checkins' table
    // e.g. user_id, date, sleep_quality, fatigue, dizziness, tachycardia, notes
    await _insertWithSchemaFallback('morning_checkins', data);
  }

  // ---------------------------------------------------------------------------
  // EVENING CHECK-IN
  // ---------------------------------------------------------------------------
  Future<void> saveEveningCheckIn(Map<String, dynamic> data) async {
    // data should correspond to columns in 'evening_checkins' table
    await _insertWithSchemaFallback('evening_checkins', data);
  }

  // ---------------------------------------------------------------------------
  // LIFESTYLE LOG
  // ---------------------------------------------------------------------------
  Future<void> saveLifestyleLog(Map<String, dynamic> data) async {
    // data should correspond to columns in 'lifestyle_logs' table
    await _insertWithSchemaFallback('lifestyle_logs', data);
  }

  // ---------------------------------------------------------------------------
  // POTS EPISODE
  // ---------------------------------------------------------------------------
  Future<void> saveEpisode(Map<String, dynamic> data) async {
    // data should correspond to columns in 'episodes' table
    await _insertWithSchemaFallback('episodes', data);
  }

  // ---------------------------------------------------------------------------
  // RAW MEASUREMENT DATA (JSON UPLOAD)
  // ---------------------------------------------------------------------------
  Future<void> saveRawMeasurementData(String userId, List<Map<String, dynamic>> rawData) async {
    // 1. Create a measurement row first to get the generated measurement_id
    final insertData = {
      'user_id': userId,
      'recorded_at': DateTime.now().toUtc().toIso8601String(),
      'source': 'device_id', // Or pass this in as a parameter
    };

    final response = await _client.from('measurements').insert(insertData).select().single();
    final measurementId = response['measurement_id'];

    if (measurementId == null) {
      throw StateError("Failed to generate measurement_id from database.");
    }

    // 2. Convert raw data to JSON and upload to Supabase storage
    final jsonString = jsonEncode(rawData);
    final filePath = '$userId/$measurementId.json';

    await _client.storage.from('raw_uploads').uploadBinary(
      filePath,
      Uint8List.fromList(utf8.encode(jsonString)),
      fileOptions: const FileOptions(contentType: 'application/json', upsert: true),
    );

    // 3. Update the measurement row with the newly created file path
    await _client
        .from('measurements')
        .update({'raw_file_path': filePath})
        .eq('measurement_id', measurementId);
  }
}
