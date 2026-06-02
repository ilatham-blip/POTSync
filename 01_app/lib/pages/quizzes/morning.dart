import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:heartbeat/app_state.dart';
import 'package:heartbeat/widgets/quiz_bottom_bar.dart';
import 'package:heartbeat/widgets/quiz_next_button.dart';
import 'package:heartbeat/services/plux_service.dart';
import 'dart:async';
import 'dart:math' as math;

/// Morning quiz: landing page (embedded in tabs) + full-screen paged survey.
class MorningQuiz extends StatefulWidget {
  const MorningQuiz({super.key});
  @override
  State<MorningQuiz> createState() => _MorningQuizState();
}

class _MorningQuizState extends State<MorningQuiz> {
  void _startSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.clearMorningDraft();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _MorningSurveyScreen()),
    );
  }

  void _continueSurvey() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _MorningSurveyScreen()),
    );
  }

  void _restartSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.clearMorningDraft();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _MorningSurveyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    final draft = appState.morningDraft;
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
              title: 'Morning Time Log',
              subtitle: 'Complete your morning check-in (5am - 5pm)',
              icon: Icons.wb_sunny_outlined,
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
                  backgroundColor: const Color(0xFF4F7CFF),
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
                    foregroundColor: const Color(0xFF4F7CFF),
                    side: const BorderSide(color: Color(0xFF4F7CFF)),
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

            // ── Recent entries ──
            _SectionCard(
              title: 'Recent Entries',
              leadingIcon: Icons.history,
              child: appState.morningEntries.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No entries yet',
                    style: TextStyle(color: Colors.black45)),
              )
                  : Column(
                children: appState.morningEntries
                    .take(5)
                    .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MorningEntryTile(entry: e),
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

class _MorningSurveyScreen extends StatefulWidget {
  const _MorningSurveyScreen();
  @override
  State<_MorningSurveyScreen> createState() => _MorningSurveyScreenState();
}

class _MorningSurveyScreenState extends State<_MorningSurveyScreen> {
  int _currentPage = 0;
  static const int _totalPages = 13;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  final TextEditingController _hrCtrl = TextEditingController();
  final TextEditingController _hrvCtrl = TextEditingController();

  // MAPS scores
  Severity _insomnia = Severity.none;
  Severity _abnormalTiredness = Severity.none;
  Severity _dizziness = Severity.none;
  Severity _palpitations = Severity.none;
  Severity _dyspnoea = Severity.none;
  Severity _chestPain = Severity.none;
  Severity _headache = Severity.none;
  Severity _concentration = Severity.none;
  Severity _musclePain = Severity.none;
  Severity _nausea = Severity.none;
  Severity _giProblems = Severity.none;

  final TextEditingController _notesCtrl = TextEditingController();
  final PageController _pageCtrl = PageController();
  final _pluxService = PluxService();

  // --- PLUX STATE VARIABLES ---
  final int _recordDuration = 5; // Changed back to 20 for production
  bool _isPluxConnected = false;

  // App Modes
  bool _isTesting = false; // True if just watching the graph
  bool _isRecording = false; // True if saving the data
  bool _recordingDone = false;

  // The permanent 20s buckets (for the database)
  final List<double> _ppgData = [];
  final List<double> _ecgData = [];

  // Temporary scrolling graph buckets (keeps last 150 points)
  final List<double> _graphPpgBuffer = [];
  final List<double> _graphEcgBuffer = [];
  static const int _maxGraphPoints = 150;

  Timer? _recordingTimer;
  StreamSubscription<List<double>>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<MyAppState>(context, listen: false);
      final draft = appState.morningDraft;
      if (draft != null) {
        setState(() {
          _currentPage = draft.currentPage;
          _date = draft.date;
          _time = draft.time;
          _hrCtrl.text = draft.heartRateBpm?.toString() ?? '';
          _hrvCtrl.text = draft.hrvMs?.toString() ?? '';
          _insomnia = draft.insomnia;
          _abnormalTiredness = draft.abnormalTiredness;
          _dizziness = draft.dizziness;
          _palpitations = draft.palpitations;
          _dyspnoea = draft.dyspnoea;
          _chestPain = draft.chestPain;
          _headache = draft.headache;
          _concentration = draft.concentration;
          _musclePain = draft.musclePain;
          _nausea = draft.nausea;
          _giProblems = draft.giProblems;
          _notesCtrl.text = draft.notes;
        });
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(_currentPage);
        }
      }
    });
  }

  bool _isDisconnected = false;
  Future<void> _safeDisconnect() async {
    if (_isDisconnected) return;
    _isDisconnected = true;
    await _pluxService.disconnect();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _dataSubscription?.cancel();

    // --- Kill the zombie connection when leaving the page! ---
    _safeDisconnect();
    // ---------------------------------------------------------

    _hrCtrl.dispose();
    _hrvCtrl.dispose();
    _notesCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // --- UNIFIED HARDWARE LISTENER ---
  Future<void> _startHardwareAndListen() async {
    if (_dataSubscription != null) return;

    await _pluxService.startRecording();

    _dataSubscription = _pluxService.heartDataStream.listen((dataPair) {
      if (dataPair.length == 2) {
        setState(() {
          _graphPpgBuffer.add(dataPair[0]);
          _graphEcgBuffer.add(dataPair[1]);

          if (_graphPpgBuffer.length > _maxGraphPoints) {
            _graphPpgBuffer.removeAt(0);
            _graphEcgBuffer.removeAt(0);
          }
        });

        if (_isRecording) {
          _ppgData.add(dataPair[0]);
          _ecgData.add(dataPair[1]);
        }
      }
    });
  }

  Future<void> _stopHardwareAndListen() async {
    _dataSubscription?.cancel();
    _dataSubscription = null;
    await _pluxService.stopRecording();
  }

  // --- BUTTON ACTIONS ---
  void _toggleTesting() async {
    if (_isTesting) {
      await _stopHardwareAndListen();
      setState(() => _isTesting = false);
    } else {
      setState(() {
        _isTesting = true;
        _graphPpgBuffer.clear();
        _graphEcgBuffer.clear();
      });
      await _startHardwareAndListen();
    }
  }

  void _startRecording() async {
    setState(() {
      _isRecording = true;
      _isTesting = false;
      _recordingDone = false;
      _ppgData.clear();
      _ecgData.clear();
      _graphPpgBuffer.clear();
      _graphEcgBuffer.clear();
    });

    await _startHardwareAndListen();

    _recordingTimer = Timer(Duration(seconds: _recordDuration), () {
      if (mounted) _finishRecording();
    });
  }

  void _finishRecording() {
    _stopHardwareAndListen();

    print('RECORDING FINISHED! Saved ${_ppgData.length} data points.');
    print('PPG (A1): $_ppgData');
    print('ECG (A2): $_ecgData');

    setState(() {
      _isRecording = false;
      _recordingDone = true;
      _hrCtrl.text = _ppgData.isNotEmpty ? _ppgData.length.toString() : "0";
      _hrvCtrl.text = "45";
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' ${_recordDuration}s complete!'), backgroundColor: Colors.green),
      );
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _stopHardwareAndListen();

    setState(() {
      _isRecording = false;
      _isTesting = false;
      _ppgData.clear();
      _ecgData.clear();
    });
  }

  void _redoRecording() {
    setState(() {
      _recordingDone = false;
      _ppgData.clear();
      _ecgData.clear();
      _graphPpgBuffer.clear();
      _graphEcgBuffer.clear();
      _hrCtrl.clear();
      _hrvCtrl.clear();
    });
  }

  // ─── Helpers ──────────────────────────────────────────────

  MorningDraft _buildDraft() => MorningDraft(
    currentPage: _currentPage,
    date: _date,
    time: _time,
    heartRateBpm: int.tryParse(_hrCtrl.text),
    hrvMs: int.tryParse(_hrvCtrl.text),
    insomnia: _insomnia,
    abnormalTiredness: _abnormalTiredness,
    dizziness: _dizziness,
    palpitations: _palpitations,
    dyspnoea: _dyspnoea,
    chestPain: _chestPain,
    headache: _headache,
    concentration: _concentration,
    musclePain: _musclePain,
    nausea: _nausea,
    giProblems: _giProblems,
    notes: _notesCtrl.text,
  );

  void _pauseSurvey() async {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.pauseMorningCheckIn(_buildDraft());

    // Force disconnect BEFORE leaving
    await _safeDisconnect();
    if (mounted) Navigator.of(context).pop();
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
      appState.clearMorningDraft();

      // Force disconnect BEFORE leaving
      await _safeDisconnect();
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
    final appState = Provider.of<MyAppState>(context, listen: false);
    try {
      await appState.saveMorningCheckIn(
        date: _date,
        time: _time,
        heartRateBpm: int.tryParse(_hrCtrl.text),
        hrvMs: int.tryParse(_hrvCtrl.text),
        insomnia: _insomnia,
        abnormalTiredness: _abnormalTiredness,
        dizziness: _dizziness,
        palpitations: _palpitations,
        dyspnoea: _dyspnoea,
        chestPain: _chestPain,
        headache: _headache,
        concentration: _concentration,
        musclePain: _musclePain,
        nausea: _nausea,
        giProblems: _giProblems,
        notes: _notesCtrl.text.trim(),
        ppgData: _ppgData,
        ecgData: _ecgData,
      );

      // Force disconnect BEFORE leaving
      await _safeDisconnect();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      await _safeDisconnect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save morning log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Morning Log'),
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
                      backgroundColor: const Color(0xFFE0E7FF),
                      valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF4F7CFF)),
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
                  _buildHRVPage(),
                  _buildInsomniaPage(),
                  _buildAbnormalTirednessPage(),
                  _buildDizzinessPage(),
                  _buildPalpitationsPage(),
                  _buildDyspnoeaPage(),
                  _buildChestPainPage(),
                  _buildHeadachePage(),
                  _buildConcentrationPage(),
                  _buildMusclePainPage(),
                  _buildNauseaPage(),
                  _buildGiProblemsPage(),
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

  // ── Page 1: HRV ───────────────────────────────────────────

  Widget _buildHRVPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Heart Rate & HRV',
            leadingIcon: Icons.monitor_heart,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Heart Rate (bpm)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _hrCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'e.g. 72',
                    border: OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.favorite, color: Color(0xFFE53935)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('HRV (ms)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _hrvCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'e.g. 50',
                    border: OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.timeline, color: Color(0xFF4F7CFF)),
                  ),
                ),
                const SizedBox(height: 24),

                // --- DYNAMIC PLUX UI & LIVE GRAPH ---
                if (_isPluxConnected) ...[
                  // 1. The Live Graph Box
                  Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C), // Dark theme for graph
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _graphPpgBuffer.isEmpty && !_recordingDone
                        ? const Center(child: Text("Press Test Sensor Button To View", style: TextStyle(color: Colors.white54)))
                        : Stack(
                      children: [
                        // Draw PPG (Red) ONLY
                        CustomPaint(
                          size: Size.infinite,
                          painter: _LiveGraphPainter(_graphPpgBuffer, Colors.redAccent),
                        ),
                        // Legend
                        const Positioned(
                          top: 0, left: 0,
                          child: Text("PPG", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. The Buttons
                  if (_isRecording)
                  // RECORDING STATE
                    SizedBox(
                      width: double.infinity, // Forces it to take the full width
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center, // Centers the items
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF4F7CFF)),
                          const SizedBox(height: 12),
                          Text(
                              "Recording data... Please sit still for ${_recordDuration}s",
                              textAlign: TextAlign.center, // Centers the text itself
                              style: const TextStyle(color: Color(0xFF4F7CFF), fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _cancelRecording,
                            icon: const Icon(Icons.cancel, color: Colors.redAccent),
                            label: const Text('Cancel Recording', style: TextStyle(color: Colors.redAccent)),
                          )
                        ],
                      ),
                    )
                  else if (_recordingDone)
                  // FINISHED STATE
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          label: const Text('Data Recorded Successfully', style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _redoRecording,
                          icon: const Icon(Icons.refresh, color: Color(0xFF4F7CFF)),
                          label: const Text('Redo Recording', style: TextStyle(color: Color(0xFF4F7CFF))),
                        )
                      ],
                    )
                  else
                  // IDLE STATE (Ready to Test or Record)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _toggleTesting,
                          icon: Icon(_isTesting ? Icons.stop : Icons.science, color: _isTesting ? Colors.red : const Color(0xFF4F7CFF)),
                          label: Text(_isTesting ? 'Stop Testing' : 'Test Sensor (Live View)',
                              style: TextStyle(color: _isTesting ? Colors.red : const Color(0xFF4F7CFF))),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _isTesting ? Colors.red : const Color(0xFF4F7CFF)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _startRecording,
                          icon: const Icon(Icons.play_arrow),
                          label: Text('Start ${_recordDuration}s Recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F7CFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ), // <--- Missing comma fixed here!
                ] else ...[
                  // CONNECT STATE
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        // 1. Instantly clear any old popups stuck in the queue!
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to PLUX...')));

                        final result = await _pluxService.testConnection();
                        setState(() { _isPluxConnected = true; });

                        if (mounted) {
                          // 2. Clear the "Connecting..." popup instantly before showing "Connected!"
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connected: $result'), backgroundColor: Colors.green));
                        }
                      },
                      icon: const Icon(Icons.bluetooth),
                      label: const Text('Connect to PLUX HeartBIT'),
                      style: OutlinedButton.styleFrom(
                         foregroundColor: const Color(0xFF4F7CFF),
                         side: const BorderSide(color: Color(0xFF4F7CFF)),
                         padding: const EdgeInsets.symmetric(vertical: 14),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                     ),
                   ),
                 ],
               ],
             ),
           ),
           const SizedBox(height: 16),
           QuizNextButton(onPressed: _nextPage),
         ],
       ),
     );
   }

  // ── Page 2: Insomnia ────────────────────────────────────

  Widget _buildInsomniaPage() {
    return _buildSeverityPage(
      title: 'Insomnia',
      subtitle: 'Difficulty falling or staying asleep',
      icon: Icons.bedtime_outlined,
      value: _insomnia,
      onChanged: (v) => setState(() => _insomnia = v),
    );
  }

  // ── Page 3: Abnormal Tiredness ────────────────────────────

  Widget _buildAbnormalTirednessPage() {
    return _buildSeverityPage(
      title: 'Abnormal Tiredness',
      subtitle: 'Abnormal tiredness that persists after rest',
      icon: Icons.battery_alert_outlined,
      value: _abnormalTiredness,
      onChanged: (v) => setState(() => _abnormalTiredness = v),
    );
  }

  // ── Page 4: Dizziness ──────────────────────────────────

  Widget _buildDizzinessPage() {
    return _buildSeverityPage(
      title: 'Dizziness',
      subtitle: 'Dizziness in upright position or while standing up / feeling that you are going to faint',
      icon: Icons.swap_vert_outlined,
      value: _dizziness,
      onChanged: (v) => setState(() => _dizziness = v),
    );
  }

  // ── Page 5: Palpitations ────────────────────────────────

  Widget _buildPalpitationsPage() {
    return _buildSeverityPage(
      title: 'Palpitations',
      subtitle: 'Palpitations, high pulse, or feeling heart beating irregularly',
      icon: Icons.favorite_outline,
      value: _palpitations,
      onChanged: (v) => setState(() => _palpitations = v),
    );
  }

  // ── Page 6: Dyspnoea ───────────────────────────────────

  Widget _buildDyspnoeaPage() {
    return _buildSeverityPage(
      title: 'Difficulty Breathing',
      subtitle: 'Difficult breathing / dyspnoea, both at effort and rest',
      icon: Icons.air_outlined,
      value: _dyspnoea,
      onChanged: (v) => setState(() => _dyspnoea = v),
    );
  }

  // ── Page 7: Chest Pain ─────────────────────────────────

  Widget _buildChestPainPage() {
    return _buildSeverityPage(
      title: 'Chest Pain',
      subtitle: 'Chest pain or tightness',
      icon: Icons.monitor_heart_outlined,
      value: _chestPain,
      onChanged: (v) => setState(() => _chestPain = v),
    );
  }

  // ── Page 8: Headache ──────────────────────────────────

  Widget _buildHeadachePage() {
    return _buildSeverityPage(
      title: 'Headache',
      subtitle: 'Headache or pressure in the head',
      icon: Icons.psychology_outlined,
      value: _headache,
      onChanged: (v) => setState(() => _headache = v),
    );
  }

  // ── Page 9: Concentration ─────────────────────────────

  Widget _buildConcentrationPage() {
    return _buildSeverityPage(
      title: 'Concentration Difficulties',
      subtitle: 'Concentration difficulties and/or problems with thinking',
      icon: Icons.lightbulb_outline,
      value: _concentration,
      onChanged: (v) => setState(() => _concentration = v),
    );
  }

  // ── Page 10: Muscle Pain ──────────────────────────────

  Widget _buildMusclePainPage() {
    return _buildSeverityPage(
      title: 'Muscle Pain',
      subtitle: 'Muscle pain or aches',
      icon: Icons.fitness_center_outlined,
      value: _musclePain,
      onChanged: (v) => setState(() => _musclePain = v),
    );
  }

  // ── Page 11: Nausea ───────────────────────────────────

  Widget _buildNauseaPage() {
    return _buildSeverityPage(
      title: 'Nausea',
      subtitle: 'Nausea or feeling sick',
      icon: Icons.sick_outlined,
      value: _nausea,
      onChanged: (v) => setState(() => _nausea = v),
    );
  }

  // ── Page 12: GI Problems ──────────────────────────────

  Widget _buildGiProblemsPage() {
    return _buildSeverityPage(
      title: 'Gastrointestinal Problems',
      subtitle: 'Stomach-ache, diarrhoea, constipation',
      icon: Icons.restaurant_outlined,
      value: _giProblems,
      onChanged: (v) => setState(() => _giProblems = v),
    );
  }

  // ── Shared severity page builder ───────────────────────────

  Widget _buildSeverityPage({
    required String title,
    required String subtitle,
    required IconData icon,
    required Severity value,
    required ValueChanged<Severity> onChanged,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: title,
            subtitle: subtitle,
            leadingIcon: icon,
            child: _SeveritySelector(
              value: value,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 16),
          QuizNextButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  // ── Page 4: Notes ─────────────────────────────────────────

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
                hintText: 'Any other observations...',
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

class _SeveritySelector extends StatelessWidget {
  const _SeveritySelector({required this.value, required this.onChanged});

  final Severity value;
  final ValueChanged<Severity> onChanged;

  static const _labels = ['None', 'Slight', 'Moderate', 'Severe'];
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
                backgroundColor: selected ? const Color(0xFF4F7CFF) : Colors.white,
                foregroundColor: selected ? Colors.white : Colors.black87,
                side: BorderSide(
                    color: selected ? const Color(0xFF4F7CFF) : Colors.black26),
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
        required this.leadingIcon,
        this.subtitle});

  final String title;
  final String? subtitle;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.black54)),
                      ],
                    ],
                  ),
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

class _MorningEntryTile extends StatelessWidget {
  const _MorningEntryTile({required this.entry});
  final MorningEntry entry;

  @override
  Widget build(BuildContext context) {
    final dt = entry.dateTime;
    final dateLabel =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final timeLabel = _format(dt);

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
            _kv('Insomnia', _label(entry.insomnia)),
            _kv('Tiredness', _label(entry.abnormalTiredness)),
            _kv('Dizziness', _label(entry.dizziness)),
            _kv('Palpitations', _label(entry.palpitations)),
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

  static String _label(Severity s) {
    switch (s) {
      case Severity.none: return 'None';
      case Severity.slight: return 'Slight';
      case Severity.moderate: return 'Moderate';
      case Severity.severe: return 'Severe';
    }
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

class _LiveGraphPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LiveGraphPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    double minVal = data.reduce(math.min);
    double maxVal = data.reduce(math.max);

    if (maxVal - minVal < 20) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final double widthStep = size.width / (data.length > 1 ? data.length - 1 : 1);

    for (int i = 0; i < data.length; i++) {
      final double x = i * widthStep;
      final double normalizedY = (data[i] - minVal) / (maxVal - minVal);
      final double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}