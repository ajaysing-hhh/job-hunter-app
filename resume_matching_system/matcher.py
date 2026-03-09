from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


@dataclass
class MatchResult:
    score: float


class ResumeMatcher:
    """Compares resume text with job descriptions using TF-IDF cosine similarity."""

    def __init__(self, resume_text: str) -> None:
        self.resume_text = resume_text

    def score_job(self, job_description: str) -> MatchResult:
        vectorizer = TfidfVectorizer(stop_words='english')
        matrix = vectorizer.fit_transform([self.resume_text, job_description])
        score = float(cosine_similarity(matrix[0:1], matrix[1:2])[0][0])
        return MatchResult(score=max(0.0, min(score, 1.0)))

    def rank_jobs(self, jobs: Iterable[dict]) -> list[dict]:
        ranked = []
        for job in jobs:
            description = job.get('description', '')
            match = self.score_job(description)
            ranked.append({**job, 'match_score': match.score})

        return sorted(ranked, key=lambda item: item['match_score'], reverse=True)
