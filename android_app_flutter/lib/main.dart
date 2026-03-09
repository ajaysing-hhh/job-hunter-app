import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'job_api_service.dart';
import 'job_match.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const JobMatcherApp());
}

class JobMatcherApp extends StatelessWidget {
  const JobMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LinkedIn Job Matcher',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const JobMatchesPage(),
    );
  }
}

class JobMatchesPage extends StatefulWidget {
  const JobMatchesPage({super.key});

  @override
  State<JobMatchesPage> createState() => _JobMatchesPageState();
}

class _JobMatchesPageState extends State<JobMatchesPage> {
  final _jobService = JobApiService('http://10.0.2.2:8000');
  final _notificationService = NotificationService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
  );

  late Future<List<JobMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _jobService.fetchMatches();
    _configureNotifications();
  }

  Future<void> _configureNotifications() async {
    final token = await _notificationService.initialize();
    if (token != null) {
      await _jobService.registerPushToken(token);
    }
  }

  Future<void> _refreshMatches() async {
    setState(() {
      _matchesFuture = _jobService.fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume-Matched Job Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMatches,
          ),
        ],
      ),
      body: FutureBuilder<List<JobMatch>>(
        future: _matchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final matches = snapshot.data ?? [];
          if (matches.isEmpty) {
            return const Center(child: Text('No matching jobs found yet.'));
          }

          return RefreshIndicator(
            onRefresh: _refreshMatches,
            child: ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return ListTile(
                  title: Text(match.title),
                  subtitle: Text('${match.company} • ${match.location}'),
                  trailing: Chip(
                    label: Text('${(match.matchScore * 100).toStringAsFixed(0)}%'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
