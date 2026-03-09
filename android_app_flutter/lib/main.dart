import 'package:flutter/material.dart';
import 'job_api_service.dart';
import 'job_match.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚨 DISABLED: This is what caused the black screen
  // await Firebase.initializeApp();

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
  // This IP looks for a backend server. We will catch the error gracefully if it fails.
  final _jobService = JobApiService('http://10.0.2.2:8000');
  late Future<List<JobMatch>> _matchesFuture;

  @override
  void initState() {
    super.initState();
    _matchesFuture = _jobService.fetchMatches();
    
    // 🚨 DISABLED: Firebase notifications
    // _configureNotifications();
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
        title: const Text('AgentOS Hunter UI'),
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
            // Instead of a black screen, we show this message while the UI stays alive
            return const Center(
              child: Text(
                'UI Loaded Successfully!\n(Backend not connected yet)', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )
            );
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
