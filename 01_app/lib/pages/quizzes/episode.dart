import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heartbeat/app_state.dart';
import 'package:heartbeat/widgets/quiz_bottom_bar.dart';
import 'package:heartbeat/widgets/quiz_next_button.dart';

/// POTS Episode log: landing page (embedded in tabs) + full-screen paged survey.
class EpisodeQuiz extends StatefulWidget {
  const EpisodeQuiz({super.key});
  @override
  State<EpisodeQuiz> createState() => _EpisodeQuizState();
}

class _EpisodeQuizState extends State<EpisodeQuiz> {
  void _startSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.clearEpisodeDraft();
    // Reset all episode scores
    for (final key in appState.episodeScores.keys.toList()) {
      appState.episodeScores[key] = 0;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _EpisodeSurveyScreen()),
    );
  }

  void _continueSurvey() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _EpisodeSurveyScreen()),
    );
  }

  void _restartSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.clearEpisodeDraft();
    for (final key in appState.episodeScores.keys.toList()) {
      appState.episodeScores[key] = 0;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _EpisodeSurveyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    final draft = appState.episodeDraft;
    final hasDraft = draft != null;
    final now = DateTime.now();
    final timeStr = _formatTime(TimeOfDay.now());
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ──
            _InfoBanner(
              title: 'POTS Episode Log',
              subtitle: 'Log as often as you need',
              icon: Icons.monitor_heart_outlined,
            ),
            const SizedBox(height: 12),

            // ── Date & Time ──
            _SectionCard(
              title: 'Date & Time',
              leadingIcon: Icons.calendar_today,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  const Icon(Icons.access_time,
                      size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(timeStr, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Action buttons ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasDraft ? _continueSurvey : _startSurvey,
                icon: Icon(
                    hasDraft ? Icons.play_arrow : Icons.play_arrow_rounded),
                label: Text(hasDraft ? 'Continue Survey' : 'Start Survey'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC2B2B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (hasDraft) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restartSurvey,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart Survey'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCC2B2B),
                    side: const BorderSide(color: Color(0xFFCC2B2B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── Recent episodes ──
            _SectionCard(
              title: 'Recent Episodes',
              leadingIcon: Icons.history,
              child: appState.episodeEntries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No recent episodes yet. Start logging!',
                          style: TextStyle(color: Colors.black45)),
                    )
                  : Column(
                      children: appState.episodeEntries
                          .take(5)
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _EpisodeEntryTile(entry: e),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'am' : 'pm';
    return '$h:$m $suffix';
  }
}

// ═══════════════════════════════════════════════════════════
// Full-screen survey route
// ═══════════════════════════════════════════════════════════

class _EpisodeSurveyScreen extends StatefulWidget {
  const _EpisodeSurveyScreen();
  @override
  State<_EpisodeSurveyScreen> createState() => _EpisodeSurveyScreenState();
}

class _EpisodeSurveyScreenState extends State<_EpisodeSurveyScreen> {
  int _currentPage = 0;

  // 12 symptoms + 1 notes page = 13 total
  static const int _totalPages = 13;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final TextEditingController _notesCtrl = TextEditingController();
  final PageController _pageCtrl = PageController();

  // MAPS symptoms (12 items)
  static const List<String> _symptoms = [
    'Dizziness in upright position or while standing up',
    'Dizziness, feeling that you are going to faint',
    'Palpitations, high pulse, or feeling heart beating irregularly',
    'Difficult breathing/dyspnoea, both at effort and rest',
    'Chest pain',
    'Headache',
    'Concentration difficulties and/or problems with thinking',
    'Muscle pain',
    'Nausea',
    'Gastrointestinal problems (stomach-ache, diarrhoea, constipation)',
    'Tremulousness',
    'Blurred vision',
  ];

  // Local symptom scores (keyed by symptom string)
  late final Map<String, Severity> _scores;

  @override
  void initState() {
    super.initState();
    // Initialize all to Severity.none (None)
    _scores = {for (final s in _symptoms) s: Severity.none};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<MyAppState>(context, listen: false);
      final draft = appState.episodeDraft;
      if (draft != null) {
        setState(() {
          _currentPage = draft.currentPage;
          _date = draft.date;
          _time = draft.time;
          _notesCtrl.text = draft.notes;
          // Restore scores from draft
          for (final entry in draft.symptomScores.entries) {
            _scores[entry.key] = _severityFromValue(entry.value);
          }
        });
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(_currentPage);
        }
      }
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────

  Map<String, double> _scoresToDoubleMap() {
    return {
      for (final entry in _scores.entries)
        entry.key: _severityToValue(entry.value).toDouble(),
    };
  }

  EpisodeDraft _buildDraft() => EpisodeDraft(
        currentPage: _currentPage,
        date: _date,
        time: _time,
        symptomScores: _scoresToDoubleMap(),
        notes: _notesCtrl.text,
      );

  void _pauseSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.pauseEpisodeSurvey(_buildDraft());
    Navigator.of(context).pop();
  }

  void _stopSurvey() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop survey?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Stop',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      appState.clearEpisodeDraft();
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  void _saveLog() async {
    // Push scores to appState
    final appState = Provider.of<MyAppState>(context, listen: false);
    for (final entry in _scores.entries) {
      final val = _severityToValue(entry.value).toDouble();
      appState.updateEpisodeScore(entry.key, val);
    }
    
    try {
      await appState.saveEpisode(
        date: _date,
        time: _time,
        scores: appState.episodeScores,
        notes: _notesCtrl.text.trim(),
      );
      
      if (mounted) {
        appState.clearEpisodeDraft();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Severity ↔ integer
  static int _severityToValue(Severity s) {
    switch (s) {
      case Severity.none:
        return 0;
      case Severity.slight:
        return 1;
      case Severity.moderate:
        return 2;
      case Severity.severe:
        return 3;
    }
  }

  static Severity _severityFromValue(double v) {
    final i = v.round().clamp(0, 3);
    switch (i) {
      case 0:
        return Severity.none;
      case 1:
        return Severity.slight;
      case 2:
        return Severity.moderate;
      case 3:
      default:
        return Severity.severe;
    }
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('POTS Episode Log'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Step ${_currentPage + 1} of $_totalPages',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFFFE0E0),
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFCC2B2B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // 12 symptoms pages
                  for (final symptom in _symptoms)
                    _buildSingleSymptomPage(symptom),
                  // Page 13: Notes
                  _buildNotesPage(),
                ],
              ),
            ),

            // ── Bottom controls ──
            QuizBottomBar(
              onPause: _pauseSurvey,
              onStop: _stopSurvey,
              onBack: _currentPage > 0 ? _prevPage : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Single symptom page builder ───────────────────────────

  Widget _buildSingleSymptomPage(String symptom) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: symptom,
            leadingIcon: Icons.circle_outlined,
            child: _VerticalSeveritySelector(
              value: _scores[symptom],
              onChanged: (sev) {
                setState(() {
                  _scores[symptom] = sev;
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          QuizNextButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  // ── Notes page ────────────────────────────────────────────

  Widget _buildNotesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Additional Notes',
            leadingIcon: Icons.edit_note,
            child: TextField(
              controller: _notesCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Triggers, context, or any other observations...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          QuizNextButton(
            onPressed: _saveLog,
            label: 'Save Log',
            icon: Icons.check, 
          ),
        ],
      ),
    );
  }
}

/* ====================== Shared UI Helpers ====================== */

class _VerticalSeveritySelector extends StatelessWidget {
  const _VerticalSeveritySelector(
      {required this.value, required this.onChanged});

  final Severity? value;
  final ValueChanged<Severity> onChanged;

  static const _labels = ['None', 'Mild', 'Moderate', 'Severe'];
  static const _values = [
    Severity.none,
    Severity.slight,
    Severity.moderate,
    Severity.severe,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (i) {
        final selected = value == _values[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onChanged(_values[i]),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected ? const Color(0xFFCC2B2B) : Colors.white,
                foregroundColor: selected ? Colors.white : Colors.black87,
                side: BorderSide(
                    color: selected ? const Color(0xFFCC2B2B) : Colors.black26),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(_labels[i]),
            ),
          ),
        );
      }),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(
      {required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7FF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4F7CFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 22)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title,
      required this.child,
      required this.leadingIcon});

  final String title;
  final Widget child;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black12.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(leadingIcon, color: const Color(0xFF4F7CFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _EpisodeEntryTile extends StatelessWidget {
  const _EpisodeEntryTile({required this.entry});

  final EpisodeEntry entry;

  @override
  Widget build(BuildContext context) {
    final dt = entry.dateTime;
    final dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final timeLabel = _format(dt);
    final symptomCount = entry.scores.values.where((v) => v > 0).length;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black12.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(dateLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                Text(timeLabel,
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            _kv('Symptoms reported', '$symptomCount'),
          ],
        ),
      ),
    );
  }

  static String _format(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour < 12 ? 'am' : 'pm';
    return '$h:$m $suffix';
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Text(k, style: const TextStyle(color: Colors.black87)),
        const Spacer(),
        Text(v,
            style: const TextStyle(
                color: Color(0xFF4F7CFF), fontWeight: FontWeight.w600)),
      ],
    );
  }
}


