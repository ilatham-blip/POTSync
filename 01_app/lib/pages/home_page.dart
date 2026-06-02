import 'package:flutter/material.dart';
import 'package:heartbeat/app_state.dart';
import 'package:heartbeat/app_theme.dart';
import 'package:heartbeat/test_connection.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<MyAppState>(context);
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBrandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Health Monitor',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // Developer/Test button (as in your current code)
          IconButton(
            icon: const Icon(Icons.build),
            tooltip: 'Test Connection',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestConnectionScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GreetingCard(greeting: _greeting()),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.favorite_border,
                      iconColor: const Color(0xFFE53935),
                      value: '${appState.episodesThisWeekCount}',
                      title: 'POTS Episodes',
                      subtitle: 'This week',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF4F7CFF),
                      value: '${appState.checkInAdherencePercentage}%',
                      title: 'Checkin Adherence',
                      subtitle: 'This week',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const DailyReminderCard(
                title: 'Daily Reminder',
                message:
                    "Don't forget to complete your evening questions before bed.",
              ),
              const SizedBox(height: 20),
              const SectionTitle('Quick Actions'),
              const SizedBox(height: 8),
              ActionTile(
                title: 'Complete Daily Questions',
                subtitle: 'Track your symptoms',
                leading: const Icon(Icons.checklist_rtl_rounded,
                    color: Colors.black87),
                onTap: () {
                  Provider.of<MyAppState>(context, listen: false).changeIndex(1);
                },
              ),
              const SizedBox(height: 12),
              ActionTile(
                title: 'Log POTS Episode',
                subtitle: 'Record episode details',
                leading:
                    const Icon(Icons.favorite_border, color: Colors.black87),
                onTap: () {
                  Provider.of<MyAppState>(context, listen: false).changeIndex(1, symptomTab: 1);
                },
              ),
              const SizedBox(height: 12),
              ActionTile(
                title: 'View Insights',
                subtitle: 'See your health trends',
                leading:
                    const Icon(Icons.insights_rounded, color: Colors.black87),
                onTap: () {
                  Provider.of<MyAppState>(context, listen: false).changeIndex(2);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

/* ---------------------- Reusable Widgets ---------------------- */

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key, required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F7CFF), Color(0xFF5A41FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nightlight_round, color: Colors.white, size: 44),
            const SizedBox(height: 8),
            Text(
              greeting,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Welcome to your Health Monitor',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black12.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DailyReminderCard extends StatelessWidget {
  const DailyReminderCard({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              )),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leading,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.black12.withOpacity(0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              SizedBox(width: 32, height: 32, child: Center(child: leading)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF3A66FF)),
            ],
          ),
        ),
      ),
    );
  }
}