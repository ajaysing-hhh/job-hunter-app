import 'package:flutter_test/flutter_test.dart';
import 'package:linkedin_job_matcher/job_match.dart';

void main() {
  test('parses job payload', () {
    final match = JobMatch.fromJson({
      'id': '1',
      'title': 'Flutter Dev',
      'company': 'ACME',
      'location': 'Remote',
      'match_score': 0.82,
      'url': 'https://example.com',
    });

    expect(match.title, 'Flutter Dev');
    expect(match.matchScore, closeTo(0.82, 0.001));
  });
}
