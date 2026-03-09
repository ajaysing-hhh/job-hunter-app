class JobMatch {
  final String id;
  final String title;
  final String company;
  final String location;
  final double matchScore;
  final String url;

  JobMatch({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.matchScore,
    required this.url,
  });

  factory JobMatch.fromJson(Map<String, dynamic> json) {
    return JobMatch(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      matchScore: (json['match_score'] as num).toDouble(),
      url: json['url'] as String,
    );
  }
}
