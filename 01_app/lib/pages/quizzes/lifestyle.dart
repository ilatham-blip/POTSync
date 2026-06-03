import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:heartbeat/app_state.dart';
import 'package:heartbeat/widgets/custom_slider.dart';
import 'package:heartbeat/widgets/quiz_bottom_bar.dart';
import 'package:heartbeat/widgets/quiz_next_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LifestyleQuiz extends StatefulWidget {
  const LifestyleQuiz({super.key});
  @override
  State<LifestyleQuiz> createState() => _LifestyleQuizState();
}

class _LifestyleQuizState extends State<LifestyleQuiz> {
  void _startSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.clearLifestyleDraft();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _LifestyleSurveyScreen()),
    );
  }

  void _continueSurvey() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _LifestyleSurveyScreen()),
    );
  }

  void _restartSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.clearLifestyleDraft();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _LifestyleSurveyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    final draft = appState.lifestyleDraft;
    final hasDraft = draft != null;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header banner ──
            _InfoBanner(
              title: 'Daily Lifestyle Log',
              subtitle: 'Track habits that impact your symptoms',
              icon: Icons.eco_outlined,
            ),
            const SizedBox(height: 12),

            // ── Date ──
            _SectionCard(
              title: 'Date',
              leadingIcon: Icons.calendar_today,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(dateStr, style: const TextStyle(fontSize: 15)),
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
                  backgroundColor: const Color(0xFF16A34A),
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
                    foregroundColor: const Color(0xFF16A34A),
                    side: const BorderSide(color: Color(0xFF16A34A)),
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
              child: appState.lifestyleEntries.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No recent entries yet. Start logging!',
                          style: TextStyle(color: Colors.black45)),
                    )
                  : Column(
                      children: appState.lifestyleEntries
                          .take(5)
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _LifestyleEntryTile(entry: e),
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Full-screen survey route
// ═══════════════════════════════════════════════════════════

class _LifestyleSurveyScreen extends StatefulWidget {
  const _LifestyleSurveyScreen();
  @override
  State<_LifestyleSurveyScreen> createState() => _LifestyleSurveyScreenState();
}

class _LifestyleSurveyScreenState extends State<_LifestyleSurveyScreen> {
  int _currentPage = 0;
  final PageController _pageCtrl = PageController();

  // Data fields
  DateTime _date = DateTime.now();
  bool _hotPlace = false;
  bool _refinedCarbs = false;
  double _standingMins = 0;
  double _carbsGrams = 0; // Not used in new UI? Kept for data structure if needed, or mapped from boolean
  double _waterLitres = 0;
  double _alcoholUnits = 0;
  bool _restTooMuch = false;
  double _exMild = 0;
  double _exModerate = 0;
  double _exIntense = 0;
  bool _onPeriod = false;
  int _stressLevel = 0; // 0-3
  final TextEditingController _notesCtrl = TextEditingController();

  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadGender();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<MyAppState>(context, listen: false);
      final draft = appState.lifestyleDraft;
      if (draft != null) {
        setState(() {
          _currentPage = draft.currentPage;
          _date = draft.date;
          _hotPlace = draft.hotPlace;
          _refinedCarbs = draft.refinedCarbs;
          _standingMins = draft.standingMins;
          _carbsGrams = draft.carbsGrams;
          _waterLitres = draft.waterLitres;
          _alcoholUnits = draft.alcoholUnits;
          _restTooMuch = draft.restTooMuch;
          _exMild = draft.exMild;
          _exModerate = draft.exModerate;
          _exIntense = draft.exIntense;
          _onPeriod = draft.onPeriod;
          _stressLevel = draft.stressLevel.toInt();
          _notesCtrl.text = draft.notes;
        });
        if (_pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(_currentPage);
        }
      }
    });
  }

  Future<void> _loadGender() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final profile = await Supabase.instance.client
        .from('user_profiles')
        .select('gender')
        .eq('id', user.id)
        .maybeSingle();
    if (profile != null && mounted) {
      setState(() => _gender = profile['gender'] as String?);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────

  LifestyleDraft _buildDraft() => LifestyleDraft(
        currentPage: _currentPage,
        date: _date,
        hotPlace: _hotPlace,
        refinedCarbs: _refinedCarbs,
        standingMins: _standingMins,
        carbsGrams: _carbsGrams,
        waterLitres: _waterLitres,
        alcoholUnits: _alcoholUnits,
        restTooMuch: _restTooMuch,
        exMild: _exMild,
        exModerate: _exModerate,
        exIntense: _exIntense,
        onPeriod: _onPeriod,
        stressLevel: _stressLevel.toDouble(),
        notes: _notesCtrl.text,
      );

  void _pauseSurvey() {
    final appState = Provider.of<MyAppState>(context, listen: false);
    appState.pauseLifestyleSurvey(_buildDraft());
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
      appState.clearLifestyleDraft();
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _nextPage() {
    _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    setState(() => _currentPage++);
  }

  void _prevPage() {
    _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    setState(() => _currentPage--);
  }

  void _saveLog() async {
    final app = context.read<MyAppState>();
    try {
      await app.saveLifestyleEntry(
        date: _date,
        hotPlace: _hotPlace,
        refinedCarbs: _refinedCarbs,
        standingMins: _standingMins.round(),
        carbsGrams: _carbsGrams.round(),
        waterLitres: double.parse(_waterLitres.toStringAsFixed(2)),
        alcoholUnits: _alcoholUnits.round(),
        restTooMuch: _restTooMuch,
        exMildMins: _exMild.round(),
        exModerateMins: _exModerate.round(),
        exIntenseMins: _exIntense.round(),
        onPeriod: _onPeriod,
        stressLevel: _stressLevel,
        notes: _notesCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }



  // ─── Page Builders ────────────────────────────────────────

  List<Widget> _buildPages() {
    final List<Widget> pages = [];

    // 1. Hot Place (Boolean)
    pages.add(_buildBooleanPage(
      title: 'Were you in a hot place today?',
      icon: Icons.sunny,
      value: _hotPlace,
      onChanged: (v) {
        setState(() => _hotPlace = v);
      },
    ));

    // 2. Standing (Slider)
    pages.add(_buildSliderPage(
      title: 'Standing or sitting upright for long periods',
      icon: Icons.access_time,
      slider: CustomSlider(
        text: 'Minutes',
        value: _standingMins,
        max: 240,
        divisions: 240,
        showLabel: true,
        decimalPlaces: 0,
        onChanged: (v) => setState(() => _standingMins = v),
      ),
    ));

    // 3. Refined Carbs (Boolean)
    pages.add(_buildBooleanPage(
      title: 'Did you eat refined carbohydrates?',
      subtitle: '(e.g., white bread, white rice, pasta)',
      icon: Icons.bakery_dining,
      value: _refinedCarbs,
      onChanged: (v) {
        setState(() => _refinedCarbs = v);
      },
    ));

    // 4. Water (Slider)
    pages.add(_buildSliderPage(
      title: 'Water Intake',
      icon: Icons.water_drop_outlined,
      slider: CustomSlider(
        text: 'Litres',
        value: _waterLitres,
        max: 5,
        divisions: 20,
        showLabel: true,
        decimalPlaces: 2,
        onChanged: (v) => setState(() => _waterLitres = v),
      ),
    ));

    // 5. Alcohol (Slider)
    pages.add(_buildSliderPage(
      title: 'Alcohol Consumption',
      icon: Icons.local_bar_outlined,
      slider: CustomSlider(
        text: 'Units',
        value: _alcoholUnits,
        max: 20,
        divisions: 20,
        showLabel: true,
        decimalPlaces: 0,
        onChanged: (v) => setState(() => _alcoholUnits = v),
      ),
    ));

    // 6. Rest Too Much (Boolean)
    pages.add(_buildBooleanPage(
      title: 'Did you rest too much today?',
      icon: Icons.hotel_outlined,
      value: _restTooMuch,
      onChanged: (v) {
        setState(() => _restTooMuch = v);
      },
    ));

    // 7. Exercise (Multi-Slider)
    pages.add(_buildExercisePage());

    // 8. On Period (Conditional)
    if (_gender != 'Male') {
      pages.add(_buildBooleanPage(
        title: 'Are you on your period?',
        icon: Icons.bloodtype_outlined,
        value: _onPeriod,
        onChanged: (v) {
          setState(() => _onPeriod = v);
        },
      ));
    }

    // 9. Stress (0-3 Buttons)
    pages.add(_buildStressPage());

    // 10. Notes & Save
    pages.add(_buildNotesPage());

    return pages;
  }

  // ─── UI Components ────────────────────────────────────────

  Widget _buildBooleanPage({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: title,
            leadingIcon: icon,
            child: Column(
              children: [
                if (subtitle != null) ...[
                  Text(subtitle,
                      style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                ],
                _OptionButton(
                  label: 'No',
                  selected: value == false,
                  onTap: () => onChanged(false),
                ),
                const SizedBox(height: 12),
                _OptionButton(
                  label: 'Yes',
                  selected: value == true,
                  onTap: () => onChanged(true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          QuizNextButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildSliderPage({
    required String title,
    required IconData icon,
    required Widget slider,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: title,
            leadingIcon: icon,
            child: slider,
          ),
          const SizedBox(height: 16),
          QuizNextButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildExercisePage() {
    final total = _exMild + _exModerate + _exIntense;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Exercise (Minutes)',
            leadingIcon: Icons.fitness_center,
            child: Column(
              children: [
                CustomSlider(
                    text: 'Mild',
                    value: _exMild,
                    max: 180,
                    divisions: 180,
                    showLabel: true,
                    decimalPlaces: 0,
                    onChanged: (v) => setState(() => _exMild = v)),
                const SizedBox(height: 16),
                CustomSlider(
                    text: 'Moderate',
                    value: _exModerate,
                    max: 180,
                    divisions: 180,
                    showLabel: true,
                    decimalPlaces: 0,
                    onChanged: (v) => setState(() => _exModerate = v)),
                const SizedBox(height: 16),
                CustomSlider(
                    text: 'Intense',
                    value: _exIntense,
                    max: 180,
                    divisions: 180,
                    showLabel: true,
                    decimalPlaces: 0,
                    onChanged: (v) => setState(() => _exIntense = v)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF7E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${total.round()} mins',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          QuizNextButton(onPressed: _nextPage),
        ],
      ),
    );
  }

  Widget _buildStressPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Stress Level',
            leadingIcon: Icons.sentiment_very_dissatisfied,
            child: Column(
              children: [
                for (int i = 0; i <= 3; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _OptionButton(
                    label: ['None', 'Low', 'Medium', 'High'][i],
                    selected: _stressLevel == i,
                    onTap: () {
                      setState(() => _stressLevel = i);
                    },
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

  Widget _buildNotesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Daily Notes',
            leadingIcon: Icons.edit_note,
            child: TextField(
              controller: _notesCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Any other observations about your day...',
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

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();
    final totalPages = pages.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Daily Lifestyle Log'),
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
                  Text('Step ${_currentPage + 1} of $totalPages',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / totalPages,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE0F2F1),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFF16A34A)),
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
                children: pages,
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
}

// ─── Shared Widgets ─────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF16A34A) : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black87,
          side: BorderSide(
              color: selected ? const Color(0xFF16A34A) : Colors.black26),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
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
          Icon(icon, color: const Color(0xFF4f7cff)),
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
                      maxLines: 2,
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

class _LifestyleEntryTile extends StatelessWidget {
  const _LifestyleEntryTile({required this.entry});

  final LifestyleEntry entry;

  @override
  Widget build(BuildContext context) {
    final dt = entry.date;
    final dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

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
              ],
            ),
            const SizedBox(height: 8),
            _kv('Water Intake', '${entry.waterLitres} L'),
            _kv('Exercise', '${entry.exMildMins + entry.exModerateMins + entry.exIntenseMins} mins'),
          ],
        ),
      ),
    );
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

